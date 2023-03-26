MODULE Hello;
IMPORT Out;
VAR a: INTEGER;
BEGIN
  a := 30;
  IF ~(~(a MOD 5 = 0) OR ~(a MOD 6 = 0)) OR (a MOD 7 = 0) THEN
    Out.Char('X')
  ELSE
    Out.Char('Y')
  END;
  Out.Ln
END Hello.
