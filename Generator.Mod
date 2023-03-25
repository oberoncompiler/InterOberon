MODULE Generator;
IMPORT ST := SymTable, S := Scanner, E := ErrorMsg, Out, Files, Strings;

CONST
  (** Values of Item.mode **)
  (** Some of Object Classes from SymTable are also valid *)
  Reg*  = 10;
  Cond* = 12; (** Condition expression result *)

  (** Dedicated Registers **)
  MT  = 12; (** Trap Interrupt *)
  MP  = 13; (** Module Pointer *)
  SP  = 14; (** Stack Pointer *)
  LNK = 15; (** Link (on procedure call) *)

  (** - **)
  maxGenReg = 12; (* Number of maximum available general-purpose register *)

  (** Register Instructions **)
  Mov = 0; Lsl = 1; Asr = 2; Ror= 3; And = 4; Ann = 5; Ior = 6; Xor = 7;
  Add = 8; Sub = 9; Cmp = 9; Mul = 10; Div = 11;
  Fad = 12; Fsb = 13; Fml = 14; Fdv = 15;
  (** Memory Instructions **)
  Ldr = 8; Str = 10; (* 1 can be added to Ldr or Str *)
  (** Branch Instructions **)
  (** B -- branch, R -- register, L -- link *)
  BR = 0; BLR = 1; BC = 2; BL = 3;
  (** Condition Codes **)
  MI = 0; PL = 8; EQ = 1; NE = 9; LT = 5; GE = 13; LE = 6; GT = 14;
  AL = 7; (** Always *) NV = 15; (** Never *)
  (** V and U **)
  (** V and U are added to op to enable the corresponding bit *)
  V = 1000H;
  U = 2000H;

  (** Output RISC machine code marks **)
  version = 1;
  (** Machine code file mark (first 4 bytes of .o file) *)
  fileMark = ORD('R') + 256 * (ORD('S') + 256 * (ORD('C') + 256 * version));

TYPE
  (** Item is a generator object.
        |  mode |     a     |     b     |      r      |
        |  Reg  |     -     |     -     | register No |
        | Const |   value   |     -     |      -      |
        |  Var  |  address  |     -     |      -      |
  *)
  Item* = RECORD
    mode*: INTEGER; (** See constants above, also Object Classes *)
    type*: ST.Type;
    a*, b*, r*: INTEGER (** Meaning of a, b, r according to the table above *)
  END;

VAR
  pc: INTEGER; (** Program counter, in 4 bytes *)
  RH: INTEGER; (** Number of the highest free register *)
  F: Files.File;
  R: Files.Rider;
  codeStart: INTEGER; (** Where actual machine code starts *)
  relmap: ARRAY 6 OF INTEGER; (** Relation map for logics operations *)

(** Item Constructors **)

PROCEDURE MakeConstItem*(VAR x: Item; type: ST.Type; val: INTEGER);
BEGIN
  x.mode := ST.Const;
  x.type := type;
  x.a := val
END MakeConstItem;

PROCEDURE MakeItem*(VAR x: Item; obj: ST.Object);
BEGIN
  x.mode := obj.class;
  x.type := obj.type;
  x.a := obj.val
END MakeItem;


(** Output **)

PROCEDURE Put(n: INTEGER);
BEGIN
  Files.Write(R, ASR(n, 24) MOD 100H);
  Files.Write(R, ASR(n, 16) MOD 100H);
  Files.Write(R, ASR(n, 8) MOD 100H);
  Files.Write(R, n MOD 100H);
  INC(pc)
END Put;

PROCEDURE Put0(op, a, b, c: INTEGER);
BEGIN
  Put(((a * 10H + b) * 10H + op) * 10000H + c)
END Put0;

PROCEDURE Put1(op, a, b, im: INTEGER);
BEGIN
  IF im < 0 THEN INC(op, V) END;
  Put((((40H + a) * 10H + b) * 10H + op) * 10000H + im MOD 10000H)
END Put1;

PROCEDURE Put2(op, a, b, off: INTEGER);
BEGIN
  Put(((op * 10H + a) * 10H + b) * 100000H + off MOD 100000H)
END Put2;

(** Here off is sometimes c *)
PROCEDURE Put3(op, cond, off: INTEGER);
BEGIN
  Put(((op + 12) * 10H + cond) * 1000000H + off MOD 1000000H)
END Put3;

PROCEDURE PutOffset(pos, n: INTEGER);
VAR tmp: Files.Rider;
BEGIN
  Files.Set(tmp, F, pos);
  Files.Write(tmp, ASR(n, 16) MOD 100H);
  Files.Write(tmp, ASR(n, 8) MOD 100H);
  Files.Write(tmp, n MOD 100H)
END PutOffset;

(** Write instruction with 1 argument -- a register *)
PROCEDURE Write1(inst: ARRAY OF CHAR; a: INTEGER);
BEGIN
  Out.String(inst);
  Out.String(' R'); Out.Int(a, 0); Out.Ln
END Write1;

(** Write instruction with 1 argument -- immediate *)
PROCEDURE Write1i(inst: ARRAY OF CHAR; a: INTEGER);
BEGIN
  Out.String(inst);
  Out.String(' '); Out.Int(a, 0); Out.Ln
END Write1i;

(** Write instruction with 2 arguments, both are registers *)
PROCEDURE Write2(inst: ARRAY OF CHAR; a, c: INTEGER);
BEGIN
  Out.String(inst);
  Out.String(' R'); Out.Int(a, 0); Out.String(', R');
  Out.Int(c, 0); Out.Ln
END Write2;

(** Write instruction with 2 arguments, the 2nd is immediate *)
PROCEDURE Write2i(inst: ARRAY OF CHAR; a, c: INTEGER);
BEGIN
  Out.String(inst);
  Out.String(' R'); Out.Int(a, 0); Out.String(', ');
  Out.Int(c, 0); Out.Ln
END Write2i;

(** Write instruction with 3 arguments, the 3rd is a register *)
PROCEDURE Write3(inst: ARRAY OF CHAR; a, b, c: INTEGER);
BEGIN
  Out.String(inst);
  Out.String(' R'); Out.Int(a, 0);
  Out.String(', R'); Out.Int(b, 0);
  Out.String(', R'); Out.Int(c, 0); Out.Ln
END Write3;

(** Write instruction with 3 arguments, the 3rd is immediate *)
PROCEDURE Write3i(inst: ARRAY OF CHAR; a, b, c: INTEGER);
BEGIN
  Out.String(inst);
  Out.String(' R'); Out.Int(a, 0);
  Out.String(', R'); Out.Int(b, 0); Out.String(', ');
  Out.Int(c, 0); Out.Ln
END Write3i;

(** Load in registers **)

(** Occupy register RH *)
PROCEDURE IncR;
BEGIN
  IF RH < maxGenReg THEN INC(RH) ELSE S.Mark(E.regOverflow) END
END IncR;

PROCEDURE Load(VAR x: Item);
BEGIN
  IF x.mode # Reg THEN
    IF x.mode = ST.Const THEN
      Put1(Mov, RH, 0, x.a)
      ;Write2i('MOV', RH, x.a)
    ELSIF x.mode = ST.Var THEN
      Put2(Ldr, RH, MP, x.a)
      ;Write3i('LDR', RH, MP, x.a)
    END;
    x.mode := Reg;
    x.r := RH;
    IncR
  END
END Load;

(** Operations **)

(** Negation. x := -x *)
PROCEDURE Neg*(VAR x: Item);
BEGIN
  IF x.mode = ST.Const THEN
    IF x.a # S.minInt THEN x.a := -x.a
    ELSE S.Mark(E.intOverflow)
    END
  ELSE (* x -- Var or Reg *)
    Load(x);
    Put1(Mov, RH, 0, 0);
    Put0(Sub, x.r, RH, x.r);
    ;Write1('NEG', x.r)
  END
END Neg;

(** Addition or subtraction. x := x op y *)
PROCEDURE AddOp*(op: INTEGER; VAR x, y: Item);
BEGIN
  IF (x.mode = ST.Const) & (y.mode = ST.Const) THEN
    IF op = S.plus THEN
      IF (y.a >= 0) & (S.maxInt - y.a >= x.a) OR
         (y.a < 0) & (S.minInt - y.a <= x.a)
      THEN INC(x.a, y.a)
      ELSE S.Mark(E.intOverflow)
      END
    ELSE (* op = S.minus *)
      IF (y.a >= 0) & (S.minInt + y.a <= x.a) OR
         (y.a < 0) & (S.maxInt + y.a >= x.a)
      THEN DEC(x.a, y.a)
      ELSE S.Mark(E.intOverflow)
      END
    END
  ELSIF y.mode = ST.Const THEN (* x -- Reg or Var *)
    Load(x); (* x -- Reg, y -- Const *)
    IF op = S.plus THEN
      Put1(Add, x.r, x.r, y.a)
      ;Write3i('ADD', x.r, x.r, y.a)
    ELSE (* op = S.minus *)
      Put1(Sub, x.r, x.r, y.a)
      ;Write3i('SUB', x.r, x.r, y.a)
    END
  ELSIF x.mode = ST.Const THEN (* y -- Reg or Var *)
    Load(y); (* x -- Const, y -- Reg *)
    IF op = S.minus THEN Neg(y) END;
    Put1(Add, y.r, y.r, x.a);
    Write3i('ADD', y.r, y.r, x.a);
    x := y
  ELSE
    Load(x); Load(y); (* x -- Reg, y -- Reg *)
    IF op = S.plus THEN
      Put0(Add, x.r, x.r, y.r)
      ;Write3('ADD', x.r, x.r, y.r)
    ELSE (* op = S.minus *)
      Put0(Sub, x.r, x.r, y.r)
      ;Write3('SUB', x.r, x.r, y.r)
    END;
    DEC(RH)
  END
END AddOp;

(** Multiplication or division (or MOD). x := x op y *)
PROCEDURE MulOp*(op: INTEGER; VAR x, y: Item);
BEGIN
  IF (x.mode = ST.Const) & (y.mode = ST.Const) THEN
    IF op = S.times THEN
      IF (y.a = 0) OR (S.maxInt DIV ABS(y.a) >= ABS(x.a)) THEN x.a := x.a * y.a
      ELSE S.Mark(E.intOverflow)
      END
    ELSIF op = S.div THEN
      IF y.a > 0 THEN x.a := x.a DIV y.a
      ELSE S.Mark(E.badDiv)
      END
    ELSE (* op = S.mod *)
      IF y.a > 0 THEN x.a := x.a MOD y.a
      ELSE S.Mark(E.badDiv)
      END
    END
  ELSIF y.mode = ST.Const THEN (* x -- Reg or Var *)
    Load(x); (* x -- Reg, y -- Const *)
    IF op = S.times THEN
      Put1(Mul, x.r, x.r, y.a)
      ;Write3i('MUL', x.r, x.r, y.a)
    ELSIF y.a <= 0 THEN S.Mark(E.badDiv)
    ELSIF op = S.div THEN
      Put1(Div, x.r, x.r, y.a)
      ;Write3i('DIV', x.r, x.r, y.a)
    ELSE (* op = S.mod *)
      Put1(Div, x.r, x.r, y.a);
      Put0(Mov + U, x.r, 0, 0) (* R[x.r] := H *)
      ;Write3i('MOD', x.r, x.r, y.a)
    END
  ELSIF x.mode = ST.Const THEN (* y -- Reg or Var *)
    Load(y); (* x -- Const, y -- Reg *)
    IF op = S.times THEN
      Put1(Mul, y.r, y.r, x.a)
      ;Write3i('MUL', y.r, y.r, x.a)
    ELSE
      Load(x); (* x -- Reg, y -- Reg, y.r < x.r *)
      IF op = S.div THEN
        Put1(Div, y.r, x.r, y.r)
        ;Write3('DIV', y.r, x.r, y.r)
      ELSE (* op = S.mod *)
        Put1(Div, y.r, x.r, y.r);
        Put0(Mov + U, y.r, 0, 0) (* R[y.r] := H *)
        ;Write3('MOD', y.r, x.r, y.r)
      END;
      DEC(RH)
    END;
    x := y
  ELSE
    Load(x); Load(y); (* x -- Reg, y -- Reg *)
    IF op = S.times THEN
      Put0(Mul, x.r, x.r, y.r) (** PUT0 ???????? !FIXME *)
      ;Write3('MUL', x.r, x.r, y.r)
    ELSIF op = S.div THEN
      Put0(Div, x.r, x.r, y.r)
      ;Write3('DIV', x.r, x.r, y.r) (** PUT0 ???????? !FIXME *)
    ELSE (* op = S.mod *)
      Put0(Div, x.r, x.r, y.r); (** PUT0 ???????? !FIXME *)
      Put0(Mov + U, x.r, 0, 0) (* R[x.r] := H *)
      ;Write3('MOD', x.r, x.r, y.r)
    END;
    DEC(RH)
  END
END MulOp;

PROCEDURE SetCond(VAR x: Item; code: INTEGER);
BEGIN
  x.mode := Cond; x.r := code;
  x.a := 0; x.b := 0 (* False- and True-lists respectively *)
END SetCond;

PROCEDURE IntRel*(op: INTEGER; VAR x, y: Item);
BEGIN
  IF y.mode = ST.Const THEN
    Load(x);
    Put1(Sub, x.r, x.r, y.a);
    DEC(RH)
  ELSE
    Load(x);
    Load(y);
    Put0(Sub, x.r, x.r, y.r);
    DEC(RH, 2)
  END;
  SetCond(x, relmap[op - S.eql])
END IntRel;

PROCEDURE Assign*(VAR x, y: Item);
BEGIN
  IF ~ST.TypesCompatible(x.type, y.type) THEN S.Mark(E.incompatible)
  ELSIF x.mode # ST.Var THEN S.Mark(E.assignConst(*?*))
  ELSE (* x -- Var, y -- Const, Var or Reg *)
    Load(y); (* x -- Var, y -- Reg *)
    Put2(Str, y.r, MP, x.a);
    Write3i('STR', y.r, MP, x.a);
    DEC(RH)
  END
END Assign;

(** Jumps *)

PROCEDURE Here*(): INTEGER;
RETURN pc END Here;

PROCEDURE Negated(code: INTEGER): INTEGER;
BEGIN
  IF code < 8 THEN INC(code, 8) ELSE DEC(code, 8) END
RETURN code END Negated;

PROCEDURE CFJump*(VAR x: Item);
BEGIN
  Put3(BC, Negated(x.r), 0);
  x.a := pc - 1
END CFJump;

PROCEDURE FJump*(VAR L: INTEGER);
BEGIN
  Put3(BC, AL, L);
  L := pc - 1
END FJump;

PROCEDURE BJump*(L: INTEGER);
BEGIN
  Put3(BC, AL, L - pc - 1)
END BJump;

PROCEDURE CBJump*(VAR x: Item; L: INTEGER);
BEGIN
  Put3(BC, Negated(x.r), L - pc - 1)
END CBJump;

PROCEDURE Fixup*(VAR x: Item);
BEGIN
  PutOffset(x.a * 4 + codeStart + 1, pc - x.a - 1)
END Fixup;

PROCEDURE FixLink*(L: INTEGER);
VAR tmp: Files.Rider;
  pos, prevL: INTEGER;
  b: BYTE;
BEGIN
  WHILE L # 0 DO
    pos := L * 4 + codeStart + 1;
    prevL := L;
    Files.Set(tmp, F, pos);
    (*!FIXME check negative offset*)
    Files.Read(tmp, b); L := b;
    Files.Read(tmp, b); L := L * 100H + b;
    Files.Read(tmp, b); L := L * 100H + b;

    PutOffset(pos, pc - prevL - 1)
  END
END FixLink;

(** Procedure Calls *)

(** Parameters are stored in registers before a procedure call *)
PROCEDURE ValueParam*(VAR x: Item);
BEGIN
  Load(x)
END ValueParam;

(** Called before Actual Parameters *)
PROCEDURE PrepCall*(VAR x: Item; rx: INTEGER);
BEGIN
  (*!TODO*)
END PrepCall;

(** Called after Actual Parameters *)
PROCEDURE Call*(VAR x: Item; rx: INTEGER);
BEGIN
  Put3(BL, AL, x.a); (*!TODO x.a is a fake call number, not an offset *)
  Write1i('BL', x.a);
  RH := 0 (*!TODO Do it only if x is a proper procedure *)
END Call;

PROCEDURE Init*;
BEGIN
  pc := 0;
  RH := 0
END Init;

PROCEDURE Open*(modName: ARRAY OF CHAR);
VAR s: ARRAY 256 OF CHAR;
BEGIN
  Strings.Copy(modName, s); Strings.Append('.o', s);
  F := Files.New(s);
  IF F # NIL THEN
    Files.Set(R, F, 0);
    Files.WriteInt(R, fileMark);
    codeStart := Files.Pos(R)
  ELSE Out.String('Невозможно создать файл "'); Out.String(s);
    Out.String('".'); Out.Ln
  END
END Open;

PROCEDURE Close*;
BEGIN
  Put3(BL, AL, 100); (* Shut down *)
  Write1i('BL', 100);
  Files.Register(F)
END Close;

BEGIN
  relmap[0] := 1; relmap[1] :=  9; relmap[2] := 5;
  relmap[3] := 6; relmap[4] := 14; relmap[5] := 13
END Generator.
