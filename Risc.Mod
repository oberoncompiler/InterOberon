MODULE Risc;
IMPORT Out, Files, Strings, SYSTEM;

CONST
  version* = 1; (** Machine code file version *)
  (** 'RSC' + CHR(version) as INTEGER *)
  fileMark* = ORD('R') + 256 * (ORD('S') + 256 * (ORD('C') + 256 * version));

  (** Error codes **)
  (**  *)
  noError*   = 0;
  noFile*    = -1;
  cantLoad*  = -2;
  badMark*   = -3;
  noMemory*  = -4;
  divByZero* = -5;
  unimpl*    = -6;

  (** Machine characteristics **)
  memLen* = 4096; (** Size of RAM in words (4 bytes) *)
  regCount* = 16; (** Register count *)

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

VAR
  mem: ARRAY memLen OF INTEGER; (** Memory *)
  R: ARRAY regCount OF INTEGER; (** Registers *)
  H: INTEGER; (** Auxiliary regiser. For MUL and DIV *)
  N, Z, C, V: BOOLEAN; (** Flags *)
  PC: INTEGER; (** Program counter (index in mem of next instruction) *)
  IR: INTEGER; (** Instruction register. Holds an instruction *)

PROCEDURE DumpMemory;
VAR i: INTEGER;
BEGIN
  FOR i := 0 TO 15 DO
    Out.String('  ');
    Out.Hex(mem[i], 8);
    IF (i + 1) MOD 8 = 0 THEN Out.Ln END
  END;
  Out.Ln
END DumpMemory;

PROCEDURE ClearRegisters;
VAR i: INTEGER;
BEGIN
  FOR i := 0 TO regCount - 1 DO R[i] := 0 END;
  N := FALSE; Z := FALSE; C := FALSE; V := FALSE;
  H := 0; PC := 0; IR := 0
END ClearRegisters;

PROCEDURE ToSet(x: INTEGER): SET;
RETURN SYSTEM.VAL(SET, x) END ToSet;

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
    mov: R[a] := n
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
    IF n # 0 THEN R[a] := R[b] DIV n; H := R[b] MOD n
    ELSE res := divByZero
    END
  | fad..fdv: res := unimpl (*!TODO*)
  END;
  Z := R[a] = 0;
  N := R[a] < 0;
END F01;

(** Memory instructions *)
PROCEDURE F2(u, v: BOOLEAN; VAR res: INTEGER);
VAR a, b, off, addr, byte, x, t: INTEGER;
BEGIN
  a := ASR(IR, 24) MOD 10H;
  b := ASR(IR, 20) MOD 10H;
  off := IR MOD 100000H;
  addr := R[b] + off;
  IF v THEN (* Byte-access *)
    x := mem[addr DIV 4]; (* 4 bytes *)
    byte := addr MOD 4; (* byte number [0; 3] *)
    IF u THEN (* Store *)
      t := 8 * byte;
      mem[addr DIV 4] := ORD(ToSet(x) - {t..t + 7} +
                             ToSet(LSL(R[a] MOD 100H, t)))
    ELSE (* Load *)
      R[a] := ASR(x, 8 * byte) MOD 100H
    END
  ELSE (* Word-access *)
    IF u THEN (* Store*)
      mem[addr DIV 4] := R[a]
    ELSE (* Load *)
      R[a] := mem[addr DIV 4]
    END
  END
END F2;

(** Branch instructions *)
PROCEDURE F3(u, v: BOOLEAN; VAR res: INTEGER);
VAR cond, addr: INTEGER;
BEGIN
  IF v THEN R[15] := PC END;
  cond := ASR(IR, 24) MOD 10H;
  IF TRUE(*!TODO cond*) THEN
    IF u THEN addr := PC + IR MOD 1000000H
    ELSE addr := R[IR MOD 10H]
    END;
    (*PC := addr*) (*!FIXME uncomment*)

    IF addr - PC = 1 THEN Out.Char(CHR(R[0] MOD 10000H))
    ELSIF addr - PC = 2 THEN Out.Int(R[0], R[1] MOD 40(*!FIXME remove 40*))
    ELSIF addr - PC = 3 THEN Out.Ln
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
    Out.Int(PC, 5); Out.Ln;
    IR := mem[PC]; INC(PC);
    u := ODD(ASR(IR, 29));
    v := ODD(ASR(IR, 28));
    Out.String('u='); Out.Int(ORD(u), 0); Out.Char(' ');
    Out.String('v='); Out.Int(ORD(v), 0); Out.Char(' ');
    IF ~ODD(ASR(IR, 31)) THEN (* F0, F1 *)
      IF ~ODD(ASR(IR, 30)) THEN (* F0 *)
        Out.String('F0 '); Out.Hex(IR, 8); Out.Ln;
        F01(u, v, FALSE, res)
      ELSE (** F1 **)
        Out.String('F1 '); Out.Hex(IR, 8); Out.Ln;
        F01(u, v, TRUE, res)
      END
    ELSE (* F2, F3 *)
      IF ~ODD(ASR(IR, 30)) THEN (* F2 *)
        Out.String('----F2 '); Out.Hex(IR, 8); Out.Ln;
        F2(u, v, res)
      ELSE (** F3 **)
        Out.String('----F3 '); Out.Hex(IR, 8); Out.Ln;
        F3(u, v, res)
      END
    END;
    IF PC >= 13 THEN done := TRUE END;
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
BEGIN
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
