MODULE Hello;
IMPORT Out, In;
VAR
  a, b, c, d: BOOLEAN;
  i: INTEGER;
BEGIN
  i := 0;
  WHILE i # 16 DO
    IF i DIV 8 = 1 THEN a := TRUE ELSE a := FALSE END;
    IF i DIV 4 MOD 2 = 1 THEN b := TRUE ELSE b := FALSE END;
    IF i DIV 2 MOD 2 = 1 THEN c := TRUE ELSE c := FALSE END;
    IF i MOD 2 = 1 THEN d := TRUE ELSE d := FALSE END;
    Out.Int(i, 3); Out.Char(' ');
    IF a & b & c & d THEN Out.Char('T') ELSE Out.Char('F') END;
    IF a OR b OR c OR d THEN Out.Char('T') ELSE Out.Char('F') END;
    IF (a OR b) & (c OR d) THEN Out.Char('T') ELSE Out.Char('F') END;
    IF a & b OR c & d THEN Out.Char('T') ELSE Out.Char('F') END;
    IF (a OR b & c) OR d THEN Out.Char('T') ELSE Out.Char('F') END;
    Out.Ln;
    i := i + 1
  END
END Hello.
