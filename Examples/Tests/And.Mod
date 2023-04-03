MODULE And;
IMPORT Out;
VAR a, b, x: INTEGER;
BEGIN
  a := 1;
  WHILE a < 21 DO
    Out.Int(a, 3);
    IF (a MOD 2 = 0) & (a = 0) THEN
      Out.Int(235, 4)
    END;
    Out.Char(';');
    a := a + 1
  END;
  Out.Ln
END And.
