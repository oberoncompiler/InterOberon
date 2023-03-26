MODULE Repeat;
IMPORT Out;
VAR a: INTEGER;
BEGIN
  a := 1;
  REPEAT
    Out.Int(a, 3); Out.Char(';');
    a := a + 1
  UNTIL ~(a MOD 13 # 0) OR (a = 30) OR (a >= 27);
  Out.Ln
END Repeat.
