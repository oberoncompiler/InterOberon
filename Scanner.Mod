MODULE Scanner;
IMPORT Files, Out;

CONST
  null*    = 0;
  ident*   = 1;
  module*  = 2;
  end*     = 3;
  semicol* = 4;
  period*  = 5;
  eot*     = 70;

VAR r: Files.Rider;
  line, col: INTEGER;
  nextLine: BOOLEAN; (* Used in Read *)

  id: ARRAY 64 OF CHAR; (* When sym = ident *)
  len: INTEGER;         (* When sym = ident *)

  ch: CHAR; (* Used in Get *)

PROCEDURE Read*(VAR ch: CHAR);
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
  F := Files.Old(fname);
  IF F # NIL THEN
    Files.Set(r, F, 0);
    line := 1;
    col := 0;
    nextLine := FALSE;
    Read(ch)
  END
RETURN F # NIL END Load;

PROCEDURE Get*(VAR sym: INTEGER);
BEGIN
  (*!FIXME skip whitespaces *)

  IF ch = 0X THEN
    sym := eot
  ELSIF ch = ';' THEN sym := semicol; Read(ch)
  ELSIF ch = '.' THEN sym := period; Read(ch)
  ELSIF ('a' < ch) & (ch < 'z') OR ('A' < ch) & (ch < 'Z') THEN
    len := 0;
    REPEAT
      IF len < LEN(id) - 1 THEN
        id[len] := ch;
        INC(len)
      END;
      Read(ch)
    UNTIL ~(('a' < ch) & (ch < 'z') OR ('A' < ch) & (ch < 'Z') OR ('0' < ch) & (ch < '9'));
    id[len] := 0X;

    IF id = 'MODULE' THEN sym := module
    ELSIF id = 'END' THEN sym := end
    ELSE sym := ident
    END
  ELSE
    sym := module;
    Read(ch)
  END
END Get;

PROCEDURE Test*;
VAR sym: INTEGER;
BEGIN
  Get(sym);
  WHILE sym # eot DO
    Out.Int(sym, 2); Out.Int(line, 5);
    Out.Char(':'); Out.Int(col, 0); Out.Ln;
    Get(sym)
  END
END Test;

PROCEDURE Test2*;
VAR ch: CHAR;
BEGIN
  Read(ch);
  WHILE ch # 0X DO
    Out.Char(ch); Out.Int(ORD(ch), 5); Out.Int(line, 5);
    Out.Char(':'); Out.Int(col, 0); Out.Ln;
    Read(ch)
  END
END Test2;

END Scanner.