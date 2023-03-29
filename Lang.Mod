MODULE Lang;
IMPORT Strings, Files, Out;

CONST
  (** Symbols **)
  null   = 0;
  eql    = 1; (** = *)
  lbrak  = 2; (** [ *)
  rbrak  = 3; (** ] *)
  string = 4; (** With no quotes *)
  int    = 5; (** Integer number *)
  eot    = 6; (** End of text *)

  (** Error Codes **)
  expEql     = 1;
  expEql2    = 2;
  expLbrak   = 3;
  expRbrak   = 4;
  expString  = 5;
  expInt     = 6;
  unexpEot   = 7;
  rangeError = 8;

  (** - **)
  maxInt = 2147483647;

TYPE
  Pair = RECORD
    key: ARRAY 10 OF CHAR;
    value: ARRAY 32 OF CHAR
  END;

  Module = RECORD
    name: Pair;
    objs: ARRAY 5 OF Pair
  END;

VAR
  curLang*: ARRAY 6 OF CHAR;
  r: Files.Rider;
  line, col: INTEGER;
  nextLine: BOOLEAN; (** Used in Read *)

  len: INTEGER;            (** When sym = string *)
  sval: ARRAY 256 OF CHAR; (** When sym = string *)
  ival: INTEGER;           (** When sym = int *)

  ch: CHAR;
  sym: INTEGER;

  error*: BOOLEAN; (* FALSE if ok, TRUE if not started yet or on error *)
  errPos: INTEGER; (* Position of last error *)

  (** Loaded strings **)
  errors: ARRAY 128, 80 OF CHAR; (** error code < 128, error length < 80 *)
  risc: ARRAY 10, 80 OF CHAR; (** 10 RISC messages, length < 80 *)
  kw: ARRAY 32 OF Pair; (** 32 keywords like BEGIN *)
  uni: ARRAY 5 OF Pair; (** 5 universe objects like INTEGER *)
  mods: ARRAY 2 OF Module; (** 2 modules like Out *)
  modCount: INTEGER; (** Actual length of mods *)

PROCEDURE GetError(code: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN
  IF    code = expEql     THEN s := '= expected'
  ELSIF code = expEql2    THEN s := 'Expected = and module name in the language'
  ELSIF code = expLbrak   THEN s := '[ expected'
  ELSIF code = expRbrak   THEN s := '] expected'
  ELSIF code = expString  THEN s := 'String expected'
  ELSIF code = expInt     THEN s := 'Integer expected'
  ELSIF code = unexpEot   THEN s := 'Unexpected end of file'
  ELSIF code = rangeError THEN s := 'Index out of range'
  ELSE s := 'Error'
  END
END GetError;

PROCEDURE Mark(errCode: INTEGER);
VAR s: ARRAY 256 OF CHAR;
  pos: INTEGER;
BEGIN
  error := TRUE; pos := Files.Pos(r);
  IF pos > errPos + 4 THEN
    errPos := pos;
    Out.String('Language file error [');
    Out.Int(line, 0); Out.Char(':'); Out.Int(col, 0);
    Out.String(']: '); GetError(errCode, s); Out.String(s); Out.Ln
  END
END Mark;

PROCEDURE Read;
BEGIN
  Files.ReadChar(r, ch);
  IF r.eof THEN ch := 0X
  ELSIF nextLine THEN
    INC(line);
    col := 1;
    nextLine := FALSE
  ELSE
    INC(col)
  END;
  IF ch = 0AX THEN nextLine := TRUE END
END Read;

PROCEDURE GetSym;
VAR n: INTEGER;
BEGIN
  (* Skip whitespaces *)
  WHILE (ch # 0X) & (ch <= ' ') DO Read END;
  IF ch = 0X THEN
    sym := eot
  ELSIF ch = '=' THEN sym := eql; Read
  ELSIF ch = '[' THEN sym := lbrak; Read
  ELSIF ch = ']' THEN sym := rbrak; Read
  ELSIF ch = ']' THEN sym := rbrak; Read
  ELSIF ('0' <= ch) & (ch <= '9') THEN
    ival := 0;
    REPEAT
      n := ORD(ch) - ORD('0');
      IF ival <= (maxInt - n) DIV 10 THEN ival := ival * 10 + n END;
      Read
    UNTIL ~(('0' <= ch) & (ch <= '9'));
    sym := int
  ELSIF ('a' <= ch) & (ch <= 'z') OR ('A' <= ch) & (ch <= 'Z') THEN
    len := 0;
    REPEAT
      IF len < LEN(sval) - 1 THEN
        sval[len] := ch;
        INC(len)
      END;
      Read
    UNTIL ~(('a' <= ch) & (ch <= 'z') OR ('A' <= ch) & (ch <= 'Z') OR
            ('0' <= ch) & (ch <= '9'));
    sval[len] := 0X;
    sym := string
  END
END GetSym;

PROCEDURE GetSymLn;
BEGIN
  IF ch = 0X THEN sym := eot
  ELSIF (ch = 0AX) OR (ch = 0DX) THEN sym := null
  ELSE
    len := 0;
    WHILE (ch # 0X) & (ch # 0AX) & (ch # 0DX) DO
      IF len < LEN(sval) - 1 THEN sval[len] := ch; INC(len) END;
      Read
    END;
    sval[len] := 0X;
    sym := string
  END
END GetSymLn;

PROCEDURE ClearPairs(VAR pairs: ARRAY OF Pair);
VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE i # LEN(pairs) DO pairs[i].key[0] := 0X; INC(i) END
END ClearPairs;

PROCEDURE ReadIntSection(VAR m: ARRAY OF ARRAY OF CHAR);
VAR n: INTEGER;
BEGIN
  FOR n := 0 TO LEN(m) - 1 DO m[n, 0] := 0X END;
  WHILE sym = int DO
    n := ival;
    IF (0 <= n) & (n < LEN(m)) THEN
      GetSym;
      IF sym = eql THEN GetSymLn ELSE Mark(expEql) END;
      IF sym = string THEN Strings.Copy(sval, m[n]); GetSym
      ELSE Mark(expString)
      END
    ELSE Mark(rangeError)
    END
  END
END ReadIntSection;

PROCEDURE ReadStrSection(VAR m: ARRAY OF Pair);
VAR i: INTEGER;
BEGIN
  ClearPairs(m);
  i := 0;
  WHILE sym = string DO
    Strings.Copy(sval, m[i].key);
    GetSym;
    IF sym = eql THEN GetSymLn ELSE Mark(expEql) END;
    IF sym = string THEN Strings.Copy(sval, m[i].value); GetSym
    ELSE Mark(expString)
    END;
    INC(i)
  END
END ReadStrSection;

PROCEDURE MakeModuleSection(name: ARRAY OF CHAR);
BEGIN
  IF modCount < LEN(mods) THEN
    Strings.Copy(name, mods[modCount].name.key);
    mods[modCount].name.value := '';
    INC(modCount)
  END
END MakeModuleSection;

PROCEDURE ReadModuleSection;
VAR name: ARRAY 64 OF CHAR;
BEGIN
  MakeModuleSection(sval);
  GetSym;
  IF sym = rbrak THEN GetSym ELSE Mark(expRbrak) END;
  IF sym = eql THEN GetSymLn ELSE Mark(expEql2) END;
  IF sym = string THEN
    Strings.Copy(sval, mods[modCount - 1].name.value);
    GetSym
  ELSE Mark(expString)
  END;
  ReadStrSection(mods[modCount - 1].objs)
END ReadModuleSection;

PROCEDURE CheckRbrak;
BEGIN
  IF sym = rbrak THEN GetSym ELSE Mark(expRbrak) END
END CheckRbrak;

PROCEDURE ReadFile;
BEGIN
  modCount := 0;
  WHILE sym = lbrak DO
    GetSym;
    IF sym = string THEN
      IF sval = 'errors' THEN GetSym; CheckRbrak; ReadIntSection(errors)
      ELSIF sval = 'risc' THEN GetSym; CheckRbrak; ReadIntSection(risc)
      ELSIF sval = 'keywords' THEN GetSym; CheckRbrak; ReadStrSection(kw)
      ELSIF sval = 'universe' THEN GetSym; CheckRbrak; ReadStrSection(uni)
      ELSE ReadModuleSection
      END
    ELSE Mark(expString)
    END
  END;
  IF sym # eot THEN Mark(expLbrak) END
END ReadFile;

PROCEDURE Load*(lang: ARRAY OF CHAR): BOOLEAN;
VAR F: Files.File;
  fname: ARRAY 256 OF CHAR;
BEGIN
  Strings.Copy(lang, curLang);
  fname := 'Langs/'; Strings.Append(curLang, fname);
  Strings.Append('.txt', fname);
  F := Files.Old(fname);
  IF F # NIL THEN
    Files.Set(r, F, 0);
    line := 1;
    col := 0;
    nextLine := FALSE;
    error := FALSE;
    errPos := -10;
    Read;
    GetSym;
    ReadFile
  END
RETURN (F # NIL) & ~error END Load;

PROCEDURE Identify*(module: ARRAY OF CHAR): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
  IF module = 'MODULE' THEN ok := Load('en')
  ELSIF module = 'МОДУЛЬ' THEN ok := Load('ru')
  ELSIF module = 'MODULIS' THEN ok := Load('lv')
  ELSE ok := FALSE
  END
RETURN ok END Identify;

PROCEDURE FindByValue*(m: ARRAY OF Pair; s: ARRAY OF CHAR;
    VAR res: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  res := ''; i := 0;
  IF ~error THEN
    WHILE (i # LEN(m)) & (m[i].key # '') & (m[i].value # s) DO INC(i) END;
    IF (i # LEN(m)) & (m[i].key # '') THEN Strings.Copy(m[i].key, res) END
  END
END FindByValue;

PROCEDURE FindByKey*(m: ARRAY OF Pair; s: ARRAY OF CHAR;
    VAR res: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  res := ''; i := 0;
  IF ~error THEN
    WHILE (i # LEN(m)) & (m[i].key # '') & (m[i].key # s) DO INC(i) END;
    IF (i # LEN(m)) & (m[i].key # '') THEN Strings.Copy(m[i].value, res) END
  END
END FindByKey;

PROCEDURE FindKeyword*(s: ARRAY OF CHAR; VAR res: ARRAY OF CHAR);
BEGIN FindByValue(kw, s, res)
END FindKeyword;

PROCEDURE FindUniObj*(s: ARRAY OF CHAR; VAR res: ARRAY OF CHAR);
BEGIN FindByKey(uni, s, res)
END FindUniObj;

(** num is Lang-internal number of module M *)
PROCEDURE FindModObj*(num: INTEGER; s: ARRAY OF CHAR;
    VAR res: ARRAY OF CHAR);
BEGIN FindByKey(mods[num].objs, s, res)
END FindModObj;

(** num is Lang-internal number of module M *)
PROCEDURE FindModule*(s: ARRAY OF CHAR; VAR res: ARRAY OF CHAR;
    VAR num: INTEGER);
VAR i: INTEGER;
BEGIN
  res := ''; i := 0;
  WHILE (i # LEN(mods)) & (mods[i].name.value # '') &
        (mods[i].name.value # s)
  DO INC(i)
  END;
  IF (i # LEN(mods)) & (mods[i].name.value # '') THEN
    Strings.Copy(mods[i].name.key, res);
    num := i
  END
END FindModule;

BEGIN
  error := TRUE
END Lang.
