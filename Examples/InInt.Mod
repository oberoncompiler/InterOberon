MODULE InInt;
IMPORT Out, In;
VAR a, b, c: INTEGER;
BEGIN
  a := 30;
  Out.Char('a');
  In.Int(a);
  Out.Char('b');
  In.Int(b);
  Out.Char('c');
  In.Int(c);
  Out.Int(a, 0); Out.Ln;
  Out.Int(b, 0); Out.Ln;
  Out.Int(c, 0); Out.Ln;
  Out.Int(a + b * c, 0);
  Out.Ln
END InInt.
