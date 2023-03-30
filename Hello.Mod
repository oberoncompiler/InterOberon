MODULE InChar;
IMPORT Out, In;
VAR
  x, y, n: INTEGER;
  d, c: CHAR;
BEGIN
  Out.Char('>');
  In.Char(c);
  In.Char(d);
  Out.Int(ORD(c), 0); Out.Ln;
  Out.Int(ORD(d), 0); Out.Ln;
  Out.Char(d); Out.Char(c); Out.Ln
END InChar.
