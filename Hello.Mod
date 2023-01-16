MODULE Hello;
IMPORT o := Out;
VAR a, x: INTEGER;
  f: CHAR;
BEGIN
  a := 125125199994362362362366;
  o.Int(x, 0);
  o.Char('>');
  o.Ln
END Hello.

MODULE Hello;
IMPORT o := Out;
VAR x, m, t2: INTEGER;
  y, a: INTEGER;
  x2: BOOLEAN;
BEGIN
  a := b;
  x := y + 412 * (10 + a) - u * abc;
END Hello.



LOAD R0, 8          # R0 := y
MOV  R1, 412        # R1 := 412
MOV  R2, 10         # R2 := 10
LOAD R3, 12         # R3 := a
ADD  R2, R2, R3     # R2 := R2 + R3
MUL  R1, R1, R2     # R1 := R1 * R2
ADD  R0, R0, R1     # R0 := R0 + R1
LOAD R1, 16         # R1 := u
LOAD R2, 20         # R2 := abc
MUL  R1, R1, R2     # R1 := R1 * R2
SUB  R0, R0, R1     # R0 := R0 - R1
STOR R0, 4          # x := R0

ADD  R0, R0, 412    # R0 := R0 + 412

  x := y + 412 * (10 + a) - u * abc

-4
1
-8
1         # load
-412
-10
-12
1
2         # +
3         # 3
2
-16
1
-20
1
3
4         # -
5         # :=


