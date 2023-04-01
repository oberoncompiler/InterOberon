MODULE Risc;
IMPORT In, Out, Files, Strings, SYSTEM;

CONST
  version* = 1; (** Machine code file version *)
  (** 'RSC' + CHR(version) as INTEGER *)
  fileMark* = ORD('R') + 256 * (ORD('S') + 256 * (ORD('C') + 256 * version));

  (** Error codes **)
  (** Negative error codes are from VM, positive are from the program *)
  noError*     = 0;
  unimpl*      = -1;
  noFile*      = -2;
  cantLoad*    = -3;
  badMark*     = -4;
  noMemory*    = -5;
  memOverflow* = -6;
  badDiv*      = -7;
  divByZero*   = -8;

  (** Register Numbers **)
  MP* = 13; (** Module Pointer *)

  (** Machine characteristics **)
  memLen*    = 5120; (** Size of RAM in words (4 bytes) *)
  varOffset* = memLen DIV 5 * 4 * 4; (** Value of R[MP], in bytes *)
  regCount*  = 16; (** Register count *)

  (** Register instruction opcodes **)
  mov = 0;
  lsl = 1;
  asr = 2;
  ror = 3;
  and = 4;
  ann = 5;
  ior = 6;
  xor = 7;
  add = 8;
  sub = 9;
  mul = 10;
  div = 11;
  fad = 12;
  fsb = 13;
  fml = 14;
  fdv = 15;

  (** Condition Codes **)
  MI = 0; PL =  8; EQ = 1; NE =  9; CS = 2; CC = 10; VS = 3; VC = 11;
  LS = 4; HI = 12; LT = 5; GE = 13; LE = 6; GT = 14;
  AL = 7; (** Always *) NV = 15; (** Never *)

VAR
  mem: ARRAY memLen OF INTEGER; (** Memory *)
  R: ARRAY regCount OF INTEGER; (** Registers *)
  H: INTEGER; (** Auxiliary regiser. For MUL and DIV *)
  N, Z, C, V: BOOLEAN; (** Flags *)
  PC: INTEGER; (** Program counter (index in mem of next instruction) *)
  IR: INTEGER; (** Instruction register. Holds an instruction *)

PROCEDURE DumpMemory;
VAR i: INTEGER;
  Z, H: INTEGER;
BEGIN
  i := 0;
  REPEAT
    Out.Char(' ');

    (* Colors *)
    Z := mem[i] DIV 10000000H MOD 10H;
    IF Z = 0EH THEN H := 1 ELSIF Z = 4 THEN H := 4 ELSE H := -1 END;
    IF H # -1 THEN Out.Char(1BX); Out.String('[4'); Out.Int(H, 0); Out.Char('m') END;
    Out.Char(' ');

    Out.Hex(mem[i], 8);

    (* Undo colors *)
    Out.Char(' ');
    IF H # -1 THEN Out.Char(1BX); Out.String('[49m') END;

    Z := mem[i] MOD 256; IF (Z < 32) OR (Z >= 0FFH) THEN Z := 32 END;
    Out.Char(CHR(Z));

    IF (i + 1) MOD 8 = 0 THEN Out.Ln END;
    INC(i)
  UNTIL (i = memLen) OR (mem[i] = 0);
  Out.Ln;
  Out.String('======='); Out.Ln
END DumpMemory;

PROCEDURE ClearRegisters;
VAR i: INTEGER;
BEGIN
  FOR i := 0 TO regCount - 1 DO R[i] := 0 END;
  R[MP] := varOffset;
  N := FALSE; Z := FALSE; C := FALSE; V := FALSE;
  H := 0; PC := 0; IR := 0
END ClearRegisters;

PROCEDURE ToSet(x: INTEGER): SET;
RETURN SYSTEM.VAL(SET, x) END ToSet;

PROCEDURE ToReal(x: INTEGER): REAL;
RETURN SYSTEM.VAL(REAL, x) END ToReal;

PROCEDURE MulHigh(x, y: INTEGER): INTEGER;
VAR a, b: SYSTEM.INT64;
BEGIN
  a := x;
  b := y;
  a := a * b DIV 10000H DIV 10000H
RETURN SYSTEM.VAL(INTEGER, a)
END MulHigh;

(** Returns -1 if x < 0, or 1 otherwise. Sign(0) = 1 *)
PROCEDURE Sign(x: INTEGER): INTEGER;
BEGIN
  IF x < 0 THEN x := -1 ELSE x := 1 END
RETURN x END Sign;

(** Register instructions (formats F0 and F1). useIm means F1 *)
PROCEDURE F01(u, v, useIm: BOOLEAN; VAR res: INTEGER);
VAR a, b, c, op, n, Rb: INTEGER;
  r: REAL;
BEGIN
  a := ASR(IR, 24) MOD 10H;
  b := ASR(IR, 20) MOD 10H;
  op := ASR(IR, 16) MOD 10H;
  IF useIm THEN
    n := IR MOD 10000H;
    IF v THEN n := n + LSL(0FFFFH, 16) END
  ELSE n := R[IR MOD 10H] (* n := R[c] *)
  END;
  CASE op OF
    mov: IF u THEN R[a] := H ELSE R[a] := n END
  | lsl: R[a] := LSL(R[b], n)
  | asr: R[a] := ASR(R[b], n)
  | ror: R[a] := ROR(R[b], n)
  | and: R[a] := ORD(ToSet(R[b]) * ToSet(n))
  | ann: R[a] := ORD(ToSet(R[b]) * (-ToSet(n)))
  | ior: R[a] := ORD(ToSet(R[b]) + ToSet(n))
  | xor: R[a] := ORD(ToSet(R[b]) / ToSet(n))
  | add: Rb := R[b]; R[a] := Rb + n;
         V := (Sign(Rb) = Sign(n)) & (Sign(R[a]) # Sign(n));
         C := (Rb < 0) & (n < 0) OR ((Rb < 0) OR (n < 0)) & (R[a] >= 0)
  | sub: R[a] := R[b] - n;
         V := (Sign(Rb) # Sign(n)) & (Sign(R[a]) = Sign(n));
         C := (Rb >= 0) & (n < 0) OR
              (R[a] < 0) & ((Rb >= 0) & (n >= 0) OR (Rb < 0) & (n < 0))
  | mul: R[a] := R[b] * n; H := MulHigh(R[b], n)
  | div:
    IF n # 0 THEN Rb := R[b]; R[a] := Rb DIV n; H := Rb MOD n
    ELSE res := badDiv
    END
  | fad: R[a] := SYSTEM.VAL(INTEGER, ToReal(R[b]) + ToReal(R[a]))
  | fsb: R[a] := SYSTEM.VAL(INTEGER, ToReal(R[b]) - ToReal(R[a]))
  | fml: R[a] := SYSTEM.VAL(INTEGER, ToReal(R[b]) * ToReal(R[a]))
  | fdv: r := ToReal(R[c]);
    IF r # 0.0 THEN R[a] := SYSTEM.VAL(INTEGER, ToReal(R[b]) / r)
    ELSE res := divByZero
    END
  END;
  Z := R[a] = 0;
  N := R[a] < 0
END F01;

(** Memory instructions *)
PROCEDURE F2(u, v: BOOLEAN; VAR res: INTEGER);
CONST B2 = 10000H; (* 2 byte offset *)
VAR a, b, off, addr, addr4, byte, x, t: INTEGER;
  q, right: BOOLEAN;
BEGIN
  a := ASR(IR, 24) MOD 10H;
  b := ASR(IR, 20) MOD 10H;
  q := ODD(ASR(IR, 19));
  off := IR MOD 80000H;
  addr := R[b] + off;
  addr4 := addr DIV 4;
  IF (addr4 < 0) OR (addr4 >= LEN(mem)) THEN
    res := memOverflow
  ELSIF v & q THEN (* Two-byte access (for CHARs) *)
    x := mem[addr4]; (* 4 bytes *)
    right := ODD(addr DIV 2); (* The right of the two 2-bytes? *)
    IF u THEN (* Store *)
      IF right THEN mem[addr4] := x MOD B2 + R[a] MOD B2 * B2
      ELSE mem[addr4] := x DIV B2 * B2 + R[a] MOD B2
      END
    ELSE (* Load *)
      IF right THEN R[a] := x DIV B2 MOD B2
      ELSE R[a] := x MOD B2
      END
    END
  ELSIF v THEN (* Byte-access *)
    x := mem[addr4]; (* 4 bytes *)
    byte := addr MOD 4; (* byte number [0; 3] *)
    IF u THEN (* Store *)
      t := 8 * byte;
      mem[addr4] := ORD(ToSet(x) - {t..t + 7} +
                             ToSet(LSL(R[a] MOD 100H, t)))
    ELSE (* Load *)
      R[a] := ASR(x, 8 * byte) MOD 100H
    END
  ELSE (* Word-access *)
    IF u THEN (* Store *)
      mem[addr4] := R[a]
    ELSE (* Load *)
      R[a] := mem[addr4]
    END
  END
END F2;

PROCEDURE CondTrue(cond: INTEGER): BOOLEAN;
VAR res: BOOLEAN;
BEGIN
  CASE cond OF
    MI: res := N
  | EQ: res := Z
  | CS: res := C
  | VS: res := V
  | LS: res := ~C OR Z
  | LT: res := N # V
  | LE: res := (N # V) OR Z
  | AL: res := TRUE
  | PL: res := ~N
  | NE: res := ~Z
  | CC: res := ~C
  | VC: res := ~V
  | HI: res := ~(~C OR Z)
  | GE: res := ~(N # V)
  | GT: res := ~((N # V) OR Z)
  | NV: res := FALSE
  END
RETURN res END CondTrue;

(** Branch instructions *)
PROCEDURE F3(u, v: BOOLEAN; VAR res: INTEGER; VAR done: BOOLEAN);
VAR cond, addr, x: INTEGER;

  PROCEDURE InChar(VAR res: INTEGER);
  VAR p: INTEGER;
    c: CHAR;
  BEGIN
    p := R[0] MOD 10000H;
    IF (p < 0) OR (p >= memLen * 4) THEN res := memOverflow
    ELSE In.Char(c);
      IF p MOD 4 DIV 2 = 0 THEN (* Left half of word *)
        p := p DIV 4;
        mem[p] := mem[p] DIV 10000H * 10000H + ORD(c)
      ELSE (* Right half of word *)
        p := p DIV 4;
        mem[p] := LSL(ORD(c), 16) + mem[p] MOD 10000H
      END
    END
  END InChar;

  PROCEDURE InInt(VAR res: INTEGER);
  VAR p: INTEGER;
  BEGIN
    p := R[0] MOD 10000H DIV 4;
    IF (p < 0) OR (p >= memLen) THEN res := memOverflow
    ELSE In.Int(mem[p])
    END
  END InInt;

BEGIN
  IF v THEN R[15] := PC END;
  cond := ASR(IR, 24) MOD 10H;
  IF CondTrue(cond) THEN
    IF u THEN addr := IR MOD 1000000H;
      addr := ORD(ToSet(addr) / {23}) - 800000H;
      INC(addr, PC)
    ELSE addr := R[IR MOD 10H]
    END;
    IF v THEN
      x := addr - PC;
      IF x = 1 THEN InChar(res)
      ELSIF x = 2 THEN InInt(res)
      ELSIF x = 5 THEN Out.Char(CHR(R[0] MOD 10000H))
      ELSIF x = 6 THEN Out.Int(R[0], R[1] MOD 512)
      ELSIF x = 7 THEN Out.Ln
      ELSIF x = 100 THEN done := TRUE
      END
    ELSE
      PC := addr
    END
  END
END F3;

PROCEDURE Run*(): INTEGER;
VAR res: INTEGER;
  done: BOOLEAN;
  u, v: BOOLEAN;
BEGIN
  ClearRegisters;
  res := noError;
  done := FALSE;
  REPEAT
    IR := mem[PC]; INC(PC);
    u := ODD(ASR(IR, 29));
    v := ODD(ASR(IR, 28));
    IF ~ODD(ASR(IR, 31)) THEN (* F0, F1 *)
      IF ~ODD(ASR(IR, 30)) THEN (* F0 *)
        F01(u, v, FALSE, res)
      ELSE (** F1 **)
        F01(u, v, TRUE, res)
      END
    ELSE (* F2, F3 *)
      IF ~ODD(ASR(IR, 30)) THEN (* F2 *)
        F2(u, v, res)
      ELSE (** F3 **)
        F3(u, v, res, done)
      END
    END;
    IF (PC < 0) OR (PC >= memLen) THEN res := memOverflow END
  UNTIL done OR (res # noError)
RETURN res END Run;

PROCEDURE Read(VAR r: Files.Rider; VAR x: INTEGER);
VAR b: BYTE;
BEGIN
  Files.Read(r, b); x := b;
  Files.Read(r, b); x := LSL(x, 8) + b;
  Files.Read(r, b); x := LSL(x, 8) + b;
  Files.Read(r, b); x := LSL(x, 8) + b
END Read;

PROCEDURE ReadMemory(VAR r: Files.Rider): BOOLEAN;
VAR x, i: INTEGER;
BEGIN
  i := 0;
  Read(r, x);
  WHILE ~r.eof & (i < LEN(mem)) DO
    mem[i] := x;
    Read(r, x);
    INC(i)
  END;
  DumpMemory
RETURN i # 0 END ReadMemory;

PROCEDURE ReadMark(VAR r: Files.Rider): BOOLEAN;
VAR n: INTEGER;
BEGIN Files.ReadInt(r, n)
RETURN ~r.eof & (n = fileMark) END ReadMark;

PROCEDURE Load*(fname: ARRAY OF CHAR; VAR err: INTEGER);
VAR F: Files.File;
  r: Files.Rider;
  i: INTEGER;
BEGIN
  FOR i := 0 TO memLen - 1 DO mem[i] := 0 END;
  F := Files.Old(fname);
  IF F = NIL THEN
    err := noFile
  ELSE
    Files.Set(r, F, 0);
    IF ~ReadMark(r) THEN
      err := badMark
    ELSIF ~ReadMemory(r) THEN
      err := noMemory
    ELSE
      err := noError
    END
  END
END Load;

PROCEDURE RunFile*(modName: ARRAY OF CHAR): INTEGER;
VAR fname: ARRAY 64 OF CHAR;
  res: INTEGER;
BEGIN
  Strings.Copy(modName, fname); Strings.Append('.o', fname);
  Load(fname, res);
  IF res = noError THEN
    res := Run()
  END
RETURN res END RunFile;

END Risc.
