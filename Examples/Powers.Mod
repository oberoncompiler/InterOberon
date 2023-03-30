MODULE Powers;
IMPORT In, Out;
VAR a, x, i, res: INTEGER;
BEGIN
  Out.Char('a'); Out.Char('='); In.Int(a);
  Out.Char('x'); Out.Char('='); In.Int(x);
  IF x >= 0 THEN
    i := 0;
    res := 1;
    REPEAT
      res := res * a;
      i := i + 1;
      Out.Int(i, 3); Out.Char(')');
      Out.Int(res, 12); Out.Ln
    UNTIL i = x
  END
END Powers.
