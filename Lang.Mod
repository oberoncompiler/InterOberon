MODULE Lang;
IMPORT Strings, Files, Out;

CONST
  (** Symbols **)
  eql    = 1; (** = *)
  lbrak  = 2; (** [ *)
  rbrak  = 3; (** ] *)
  string = 4; (** With no quotes *)
  int    = 5; (** Integer number *)
  ln     = 6; (** New line *)
  eot    = 7; (** End of text *)

  (** Error Codes **)
  expEql    = 1;
  expLbrak  = 2;
  expRbrak  = 3;
  expString = 4;
  expInt    = 5;
  unexpEot  = 6;

  (** - **)
  maxInt = 2147483647;

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

  error*: BOOLEAN; (* FALSE if ok *)
  errPos: INTEGER; (* Position of last error *)

PROCEDURE GetError(code: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN
  IF    code = expEql    THEN s := '= expected'
  ELSIF code = expLbrak  THEN s := '[ expected'
  ELSIF code = expRbrak  THEN s := '] expected'
  ELSIF code = expString THEN s := 'String expected'
  ELSIF code = expInt    THEN s := 'Integer expected'
  ELSIF code = unexpEot  THEN s := 'Unexpected end of file'
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
  ELSIF (ch = 0AX) OR (ch = 0DX) THEN sym := ln; Read
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

PROCEDURE ReadFile(): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
  ok := FALSE;
  ok := TRUE;
RETURN ok END ReadFile;

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
    GetSym
  END
RETURN (F # NIL) & ReadFile() END Load;

PROCEDURE Identify*(module: ARRAY OF CHAR): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
  IF module = 'MODULE' THEN ok := Load('en')
  ELSIF module = 'МОДУЛЬ' THEN ok := Load('ru')
  ELSIF module = 'MODULIS' THEN ok := Load('lv')
  ELSE ok := FALSE
  END
RETURN ok END Identify;

END Lang.
