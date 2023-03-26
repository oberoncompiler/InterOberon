MODULE Factorize;
IMPORT Out;
VAR a, b, x: INTEGER;
BEGIN
  a := 5177;
  b := 2;
  x := 0;
  Out.Int(a, 6);
  Out.Char(' '); Out.Char('='); Out.Char(' ');
  WHILE a MOD b = 0 DO
    IF x = 1 THEN Out.Char(' '); Out.Char('*'); Out.Char(' ') ELSE x := 1 END;
    Out.Int(b, 0);
    a := a DIV b
  ELSIF (a # 0) & (a > b) DO
    b := b + 1
  END;
  Out.Ln
END Factorize.
