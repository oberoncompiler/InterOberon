MODULE Scanner;
IMPORT Files, Out, ErrorMsg;

CONST
  null*    = 0;
  ident*   = 1;
  module*  = 2;
  end*     = 3;
  semicol* = 4;
  period*  = 5;
  eot*     = 70;

VAR
  moduleFname: ARRAY 128 OF CHAR;
  r: Files.Rider;
  line, col: INTEGER;
  nextLine: BOOLEAN; (* Used in Read *)

  id*: ARRAY 64 OF CHAR; (* When sym = ident *)
  len*: INTEGER;         (* When sym = ident *)

  ch: CHAR; (* Used in Get *)

  error*: BOOLEAN; (* FALSE if ok *)
  errPos: INTEGER; (* Position of last error *)

PROCEDURE SymName*(sym: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN
  IF sym = null THEN s := 'null'
  ELSIF sym = ident THEN s := 'ident'
  ELSIF sym = module THEN s := 'module'
  ELSIF sym = end THEN s := 'end'
  ELSIF sym = semicol THEN s := 'semicol'
  ELSIF sym = period THEN s := 'period'
  ELSIF sym = eot THEN s := 'eot'
  ELSE s := 'unknown'
  END
END SymName;

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
    Read
  END
RETURN F # NIL END Load;

PROCEDURE Get*(VAR sym: INTEGER);
BEGIN
  (* Skip whitespaces *)
  WHILE (ch # 0X) & (ch <= ' ') DO Read END;

  IF ch = 0X THEN
    sym := eot
  ELSIF ch = ';' THEN sym := semicol; Read
  ELSIF ch = '.' THEN sym := period; Read
  ELSIF ('a' < ch) & (ch < 'z') OR ('A' < ch) & (ch < 'Z') THEN
    len := 0;
    REPEAT
      IF len < LEN(id) - 1 THEN
        id[len] := ch;
        INC(len)
      END;
      Read
    UNTIL ~(('a' < ch) & (ch < 'z') OR ('A' < ch) & (ch < 'Z') OR ('0' < ch) & (ch < '9'));
    id[len] := 0X;

    IF id = 'MODULE' THEN sym := module
    ELSIF id = 'END' THEN sym := end
    ELSE sym := ident
    END
  ELSE
    sym := null;
    Read
  END
END Get;

PROCEDURE Mark*(errCode: INTEGER);
VAR s: ARRAY 256 OF CHAR;
BEGIN
  error := TRUE; errPos := Files.Pos(r);
  Out.String(moduleFname); Out.Char(':');
  Out.Int(line, 0); Out.Char(':'); Out.Int(col, 0);
  Out.String(': error: #'); Out.Int(errCode, 0); Out.Char(' ');
  ErrorMsg.Get(errCode, s); Out.String(s); Out.Ln
END Mark;

PROCEDURE Test*;
VAR sym: INTEGER;
  s: ARRAY 30 OF CHAR;
BEGIN
  Get(sym);
  WHILE sym # eot DO
    Out.Int(line, 3); Out.Char(':'); Out.Int(col, 2); Out.String(' - ');
    SymName(sym, s); Out.String(s);
    IF sym = ident THEN Out.String(" '"); Out.String(id); Out.Char("'") END;
    Out.Ln;
    Get(sym)
  END
END Test;

END Scanner.
