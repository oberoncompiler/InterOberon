MODULE Hello;
IMPORT Out;
VAR a, b: INTEGER;
  c: CHAR;
BEGIN
  Out.Int(a, 10)
END Hello.

     R13=400, a=0, b=4, x=8, y=9, z=10, n=12

a := 5                            MOV  R0,   5
                                  STR  R0, R13,   0
b := a + 3                        LDR  R0, R13,   0
                                  ADD  R0,  R0,   3
                                  STR  R0, R13,   4
n := 512 - a * b DIV (b * b - a)  LDR  R0, R13,   0       R0 := a
                                  LDR  R1, R13,   4       R1 := b
                                  MUL  R0,  R0,  R1       R0 := R0 * R1
                                  LDR  R1, R13,   4       R1 := b
                                  LDR  R2, R13,   4       R2 := b
                                  MUL  R1,  R1,  R2       R1 := R1 * R2
                                  LDR  R2, R13,   0       R2 := a
                                  SUB  R1,  R1,  R2       R1 := R1 - R2
                                  DIV  R0,  R0,  R1       R0 := R0 DIV R1
                                  MOV  R1, 512            R1 := 512
                                  SUB  R0,  R1,  R0       R0 := R1 - R0
                                  STR  R0, R13,  12       n := R0

