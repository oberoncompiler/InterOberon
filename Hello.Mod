MODULE Hello;
IMPORT Out, In;
VAR
  x, y, n: INTEGER;
  d, c: CHAR;
BEGIN
  Out.Char('>');
  In.Char(c);
  Out.Char(c);
  Out.Char('='); Out.Int(ORD(c), 0); Out.Ln;

  d := CHR(ORD('Ы') - 1);
  Out.Char(d); Out.Ln;

  In.Int(n);
  Out.Int(n, 0);
  Out.Char('='); Out.Char(CHR(n)); Out.Char('.'); Out.Ln
END Hello.
