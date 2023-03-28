MODULE Hello;
IMPORT Out, In;
VAR
  a, b: BOOLEAN;
BEGIN
  a := TRUE;
  b := FALSE;
  IF a THEN
    Out.Int(423, 0)
  ELSE
    Out.Int(95, 0)
  END;
  Out.Ln
END Hello.
