MODULE Scanner;
IMPORT Files, Out, E := ErrorMsg, Lang;

CONST
  null       = 0;  (** Bad character *)
  times*     = 1;  (** *   *)
  div*       = 3;  (** DIV *)
  mod*       = 4;  (** MOD *)
  and*       = 5;  (** &   *)
  plus*      = 6;  (** +   *)
  minus*     = 7;  (** -   *)
  or*        = 8;  (** OR  *)
  eql*       = 9;  (** =   *)
  neq*       = 10; (** #   *)
  lss*       = 11; (** <   *)
  leq*       = 12; (** <=  *)
  gtr*       = 13; (** >   *)
  geq*       = 14; (** >=  *)
  period*    = 18; (** .   *)
(*char*      = 20;*)
  int*       = 21;
  false*     = 23; (** FALSE *)
  true*      = 24; (** TRUE  *)
  string*    = 26;
  not*       = 27; (** ~ *)
  lparen*    = 28; (** ( *)
  ident*     = 31;
  if*        = 32;
  while*     = 34;
  repeat*    = 35;
  comma*     = 40;
  colon*     = 41;
  becomes*   = 42; (** := *)
  rparen*    = 44; (** ) *)
  then*      = 47;
  do*        = 49;
  semicol*   = 52;
  end*       = 53;
  else*      = 55;
  elsif*     = 56;
  until*     = 57;
(*const*     = 63;*)
  var*       = 65; (** VAR *)
  begin*     = 67;
  import*    = 68;
  module*    = 69;
  eot        = 70; (** End of text *)

  (** - **)
  maxInt*  = 2147483647;
  minInt*  = -maxInt - 1;

VAR
  moduleFname: ARRAY 128 OF CHAR;
  r: Files.Rider;
  line, col: INTEGER;
  nextLine: BOOLEAN; (** Used in Read *)

  id*: ARRAY 64 OF CHAR;    (** When sym = ident *)
  len*: INTEGER;            (** When sym = ident or string *)
  ival*: INTEGER;           (** When sym = int *)
  sval*: ARRAY 256 OF CHAR; (** When sym = string *)

  ch: CHAR; (* Used in Get *)

  error*: BOOLEAN; (* FALSE if ok *)
  errPos: INTEGER; (* Position of last error *)

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

PROCEDURE Rewind*;
BEGIN
  Files.Set(r, Files.Base(r), 0);
  line := 1;
  col := 0;
  nextLine := FALSE;
  error := FALSE;
  errPos := -10;
  Read
END Rewind;

PROCEDURE Load*(fname: ARRAY OF CHAR): BOOLEAN;
VAR F: Files.File;
BEGIN
  moduleFname := fname;
  F := Files.Old(fname);
  IF F # NIL THEN Files.Set(r, F, 0); Rewind END
RETURN F # NIL END Load;

PROCEDURE Mark*(errCode: INTEGER);
VAR s: ARRAY 256 OF CHAR;
  pos: INTEGER;
BEGIN
  error := TRUE; pos := Files.Pos(r);
  IF pos > errPos + 4 THEN
    errPos := pos;
    Out.String(moduleFname); Out.Char(':');
    Out.Int(line, 0); Out.Char(':'); Out.Int(col, 0);
    Out.String(': error: #'); Out.Int(errCode, 0); Out.Char(' ');
    E.Get(errCode, s); Out.String(s); Out.Ln
  END
END Mark;

(** Skips a possibly nested comment. Begins on ch = '*' after '(',
    ends with a character after ')'. *)
PROCEDURE Comment;
VAR end: BOOLEAN;
BEGIN
  Read;
  end := FALSE;
  REPEAT
    IF ch = '(' THEN 
      Read;
      IF ch = '*' THEN Comment END
    ELSIF ch = '*' THEN
      Read;
      IF ch = ')' THEN Read; end := TRUE END
    ELSIF ch = 0X THEN end := TRUE
    ELSE Read
    END
  UNTIL end
END Comment;

PROCEDURE IsLetter(c: CHAR): BOOLEAN;
RETURN ( 'a' <= c) & (c <=  'z') OR
       ( 'A' <= c) & (c <=  'Z') OR
       (0C0X <= c) & (c <= 2AFX) & ~((1C0X <= c) & (c <= 1C3X)) &
         (c # 0D7X) & (c # 0F7X) OR (* Latin *)
       ( 388X <= c) & (c <=  3FFX) OR (* Greek *)
       ( 400X <= c) & (c <=  481X) OR (* Cyrillic *)
       ( 48AX <= c) & (c <=  52FX) OR (* Cyrillic Extended *)
       ( 531X <= c) & (c <=  556X) OR (* Armenian *)
       ( 560X <= c) & (c <=  588X) OR (* Armenian *)
       ( 5D0X <= c) & (c <=  5EAX) OR (* Hebrew *)
       ( 710X <= c) & (c <=  74FX) OR (* Sirian *)
       (10A0X <= c) & (c <= 10FFX)    (* Georgian *)
END IsLetter;

PROCEDURE Get*(VAR sym: INTEGER);
VAR quote: CHAR;
  marked: BOOLEAN;
  n: INTEGER;
  kw: ARRAY 32 OF CHAR;
BEGIN
  REPEAT
    (* Skip whitespaces *)
    WHILE (ch # 0X) & (ch <= ' ') DO Read END;

    IF ch = 0X THEN
      sym := eot
    ELSIF ch = ':' THEN Read;
      IF ch = '=' THEN sym := becomes; Read ELSE sym := colon END
    ELSIF ch = '=' THEN sym := eql; Read
    ELSIF ch = '#' THEN sym := neq; Read
    ELSIF ch = '<' THEN Read;
      IF ch = '=' THEN sym := leq; Read ELSE sym := lss END
    ELSIF ch = '>' THEN Read;
      IF ch = '=' THEN sym := geq; Read ELSE sym := gtr END
    ELSIF ch = ';' THEN sym := semicol; Read
    ELSIF ch = '.' THEN sym := period; Read
    ELSIF ch = ',' THEN sym := comma; Read
    ELSIF ch = '*' THEN sym := times; Read
    ELSIF ch = '+' THEN sym := plus; Read
    ELSIF ch = '-' THEN sym := minus; Read
    ELSIF ch = '(' THEN Read;
      IF ch = '*' THEN Comment; sym := null ELSE sym := lparen END
    ELSIF ch = ')' THEN sym := rparen; Read
    ELSIF ch = '&' THEN sym := and; Read
    ELSIF ch = '~' THEN sym := not; Read
    ELSIF (ch = '"') OR (ch = "'") THEN
      quote := ch;
      len := 0;
      marked := FALSE;
      Read;
      WHILE (ch # 0X) & (ch # quote) DO
        IF len < LEN(sval) - 1 THEN
          sval[len] := ch;
          INC(len)
        ELSIF ~marked THEN
          Mark(E.longString);
          marked := TRUE
        END;
        Read
      END;
      sval[len] := 0X;
      Read;
      sym := string
    ELSIF ('0' <= ch) & (ch <= '9') THEN
      ival := 0;
      REPEAT
        n := ORD(ch) - ORD('0');
        IF ival <= (maxInt - n) DIV 10 THEN ival := ival * 10 + n
        ELSE Mark(E.intOverflow)
        END;
        Read
      UNTIL ~(('0' <= ch) & (ch <= '9'));
      sym := int
    ELSIF IsLetter(ch) THEN
      len := 0;
      REPEAT
        IF len < LEN(id) - 1 THEN
          id[len] := ch;
          INC(len)
        END;
        Read
      UNTIL ~(IsLetter(ch) OR ('0' <= ch) & (ch <= '9'));
      id[len] := 0X;
      Lang.FindKeyword(id, kw);
      IF    kw = ''       THEN sym := ident
      ELSIF kw = 'module' THEN sym := module
      ELSIF kw = 'end'    THEN sym := end
      ELSIF kw = 'begin'  THEN sym := begin
      ELSIF kw = 'var'    THEN sym := var
      ELSIF kw = 'import' THEN sym := import
      ELSIF kw = 'div'    THEN sym := div
      ELSIF kw = 'mod'    THEN sym := mod
      ELSIF kw = 'or'     THEN sym := or
      ELSIF kw = 'false'  THEN sym := false
      ELSIF kw = 'true'   THEN sym := true
      ELSIF kw = 'if'     THEN sym := if
      ELSIF kw = 'then'   THEN sym := then
      ELSIF kw = 'elsif'  THEN sym := elsif
      ELSIF kw = 'else'   THEN sym := else
      ELSIF kw = 'while'  THEN sym := while
      ELSIF kw = 'do'     THEN sym := do
      ELSIF kw = 'repeat' THEN sym := repeat
      ELSIF kw = 'until'  THEN sym := until
      ELSE Mark(E.unknownKW)
      END
    ELSE sym := null; Read
    END
  UNTIL sym # null
END Get;

END Scanner.
