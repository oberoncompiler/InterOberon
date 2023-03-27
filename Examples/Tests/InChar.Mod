MODULE InChar;
IMPORT Out, In;
VAR
  x, y, n: INTEGER;
  d, c: CHAR;
BEGIN
  Out.Char('>');
  In.Char(c);
  Out.Char(c); Out.Ln;

  Out.Char('>');
  In.Int(n);
  Out.Int(n, 0); Out.Ln
END InChar.
