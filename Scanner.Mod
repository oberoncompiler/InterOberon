MODULE Scanner;
IMPORT Files, Out, E := ErrorMsg;

CONST
  null*    = 0;
  ident*   = 1;
  int*     = 2;
  string*  = 4;
  module*  = 12;
  end*     = 13;
  semicol* = 14;
  period*  = 15;
  comma*   = 16;
  begin*   = 17;
  becomes* = 18;
  colon*   = 19;

  times*   = 21;
  div*     = 22;
  mod*     = 23;
  plus*    = 24;
  minus*   = 25;
  var*     = 26;
  import*  = 27;
  false*   = 28;
  true*    = 29;
  if*      = 30;
  then*    = 31;
  elsif*   = 32;
  else*    = 33;
  while*   = 34;
  do*      = 35;
  repeat*  = 36;
  until*   = 37;

  lparen*  = 40; (** "(" *)
  rparen*  = 41; (** ")" *)

  eql*     = 43; (** =  *)
  neq*     = 44; (** #  *)
  lss*     = 45; (** <  *)
  leq*     = 46; (** <= *)
  gtr*     = 47; (** >  *)
  geq*     = 48; (** >= *)

  eot*     = 70; (** End of text *)

  maxInt*  = 2147483647;
  minInt*  = -maxInt - 1;

VAR
  moduleFname: ARRAY 128 OF CHAR;
  r: Files.Rider;
  line, col: INTEGER;
  nextLine: BOOLEAN; (** Used in Read *)

  id*: ARRAY 64 OF CHAR;   (** When sym = ident *)
  len*: INTEGER;           (** When sym = ident or string *)
  ival*: INTEGER;          (** When sym = int *)
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

PROCEDURE Load*(fname: ARRAY OF CHAR): BOOLEAN;
VAR F: Files.File;
BEGIN
  moduleFname := fname;
  F := Files.Old(fname);
  IF F # NIL THEN
    Files.Set(r, F, 0);
    line := 1;
    col := 0;
    nextLine := FALSE;
    error := FALSE;
    errPos := -10;
    Read
  END
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

PROCEDURE Get*(VAR sym: INTEGER);
VAR quote: CHAR;
  marked: BOOLEAN;
  n: INTEGER;
BEGIN
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
  ELSIF ch = '(' THEN sym := lparen; Read
  ELSIF ch = ')' THEN sym := rparen; Read
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
  ELSIF ('a' <= ch) & (ch <= 'z') OR ('A' <= ch) & (ch <= 'Z') THEN
    len := 0;
    REPEAT
      IF len < LEN(id) - 1 THEN
        id[len] := ch;
        INC(len)
      END;
      Read
    UNTIL ~(('a' <= ch) & (ch <= 'z') OR ('A' <= ch) & (ch <= 'Z') OR
            ('0' <= ch) & (ch <= '9'));
    id[len] := 0X;

    IF id = 'MODULE' THEN sym := module
    ELSIF id = 'END' THEN sym := end
    ELSIF id = 'BEGIN' THEN sym := begin
    ELSIF id = 'VAR' THEN sym := var
    ELSIF id = 'IMPORT' THEN sym := import
    ELSIF id = 'DIV' THEN sym := div
    ELSIF id = 'MOD' THEN sym := mod
    ELSIF id = 'FALSE' THEN sym := false
    ELSIF id = 'TRUE' THEN sym := true
    ELSIF id = 'IF' THEN sym := if
    ELSIF id = 'THEN' THEN sym := then
    ELSIF id = 'ELSIF' THEN sym := elsif
    ELSIF id = 'ELSE' THEN sym := else
    ELSIF id = 'WHILE' THEN sym := while
    ELSIF id = 'DO' THEN sym := do
    ELSIF id = 'REPEAT' THEN sym := repeat
    ELSIF id = 'UNTIL' THEN sym := until
    ELSE sym := ident
    END
  ELSE
    sym := null;
    Read
  END
END Get;

END Scanner.
