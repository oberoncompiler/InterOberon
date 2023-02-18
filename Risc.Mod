MODULE Risc;
IMPORT Out, Files, Strings;

CONST
  version* = 1; (** Machine code file version *)
  (** 'RSC' + CHR(version) as INTEGER *)
  fileMark* = ORD('R') + 256 * (ORD('S') + 256 * (ORD('C') + 256 * version));

  (** Error codes **)
  (**  *)
  noError*  = 0;
  noFile*   = -1;
  cantLoad* = -2;
  badMark*  = -3;
  noMemory* = -4;

  (** Machine characteristics **)
  memLen* = 4096; (** Size of RAM in words (4 bytes) *)
  regCount* = 16; (** Register count *)

  (** Flags set members **)
  N = 0;
  Z = 1;
  C = 2;
  V = 3;

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
  flags: SET; (** Flag register. Contains N, Z, C, V *)
  PC: INTEGER; (** Program counter (index in mem of next instruction) *)
  IR: INTEGER; (** Instruction register. Holds an instruction *)

PROCEDURE DumpMemory;
VAR i: INTEGER;
BEGIN
  FOR i := 0 TO 31 DO
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
  H := 0;
  flags := {};
  PC := 0; IR := 0;
END ClearRegisters;

PROCEDURE F1(u, v: BOOLEAN);
VAR a, b, op, im: INTEGER;
BEGIN
  a := ASR(IR, 24) MOD 10H;
  b := ASR(IR, 20) MOD 10H;
  op := ASR(IR, 16) MOD 10H;
  im := IR MOD 10000H;
  IF op = mov THEN R[a] := im
    Out.String('R['); Out.Int(a, 0); Out.String('] := '); Out.Int(im, 0); Out.Ln
    (*!TODO*)
  END
END F1;

PROCEDURE Run*(): INTEGER;
VAR res: INTEGER;
  done: BOOLEAN;
  u, v: BOOLEAN;
BEGIN
  res := noError;
  ClearRegisters;
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
        Out.String('F0 '); Out.Hex(IR, 8); Out.Ln
      ELSE (** F1 **)
        F1(u, v)
      END
    ELSE (* F2, F3 *)
      IF ~ODD(ASR(IR, 30)) THEN (* F2 *)
        Out.String('F2 '); Out.Hex(IR, 8); Out.Ln
      ELSE (** F3 **)
        Out.String('F3 '); Out.Hex(IR, 8); Out.Ln
      END
    END;
    IF PC >= 7 THEN done := TRUE END
  UNTIL done
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
