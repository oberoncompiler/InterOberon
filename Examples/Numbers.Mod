MODULE Numbers;
IMPORT Out;
VAR a, b, x: INTEGER;
BEGIN
  a := 1;
  WHILE a < 20 DO
    Out.Int(a, 3);
    IF (a MOD 3 = 0) OR (a MOD 4 = 0) OR (a MOD 5 = 0) THEN
      Out.Int(345, 4)
    ELSIF (a MOD 2 = 0) & (a MOD 5 = 0) THEN
      Out.Int(235, 4)
    END;
    Out.Char(';');
    a := a + 1
  ELSIF a < 40 DO
    Out.Int(a, 3);
    IF (a MOD 4 = 0) OR (a MOD 5 = 0) OR (a MOD 7 = 0) THEN
      Out.Int(457, 4)
    ELSIF (a MOD 2 = 0) & (a MOD 5 = 0) THEN
      Out.Int(235, 4)
    END;
    Out.Char(';');
    a := a + 1
  END;
  Out.Ln
END Numbers.
