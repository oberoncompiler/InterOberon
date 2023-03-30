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
  Add = 8; Sub = 9; Cmp = Sub; Mul = 10; Div = 11;
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

  cmpNeeded: BOOLEAN; (** For Load and LoadCond interaction *)

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
  Files.Set(tmp, F, pos * 4 + codeStart + 1);
  Files.Write(tmp, ASR(n, 16) MOD 100H);
  Files.Write(tmp, ASR(n, 8) MOD 100H);
  Files.Write(tmp, n MOD 100H)
END PutOffset;

(** Load in registers **)

(** Occupy register RH *)
PROCEDURE IncR;
BEGIN
  IF RH < maxGenReg THEN INC(RH) ELSE S.Mark(E.regOverflow) END
END IncR;

PROCEDURE Load(VAR x: Item);
VAR op, addr: INTEGER;
BEGIN
  IF x.mode # Reg THEN
    IF x.mode = ST.Const THEN
      Put1(Mov, RH, 0, x.a)
    ELSIF x.mode = ST.Var THEN
      op := Ldr; addr := x.a;
      IF x.type.size = 1 THEN INC(op) (* BOOLEAN *)
      ELSE addr := addr DIV 4 * 4
      END;
      Put2(op, RH, MP, addr);
      cmpNeeded := TRUE;
      IF x.type.size = 2 THEN (* 2-byte CHARs *)
        IF x.a MOD 4 DIV 2 = 0 THEN (* Left half of word*)
          Put1(And, RH, RH, 0FFFFH)
        ELSE (* Right half of word*)
          Put1(Ann, RH, RH, 0FFFFH);
          Put1(Ror, RH, RH, 16)
        END
      END
    END;
    x.mode := Reg;
    x.r := RH;
    IncR
  END
END Load;

PROCEDURE LoadAddr(VAR x: Item);
BEGIN
  IF x.mode = ST.Var THEN
    Put1(Add, RH, MP, x.a);
    x.r := RH;
    IncR
  ELSE S.Mark(E.badVarPar)
  END;
  x.mode := Reg
END LoadAddr;

PROCEDURE LoadCond(VAR x: Item);
BEGIN
  IF x.mode # Cond THEN
    IF x.type.form = ST.Bool THEN
      IF x.mode = ST.Const THEN x.r := NV - x.a * (NV - AL)
      ELSE Load(x);
        IF cmpNeeded THEN Put1(Cmp, x.r, x.r, 0) END;
        x.r := NE; DEC(RH)
      END
    ELSE S.Mark(E.expBool)
    END;
    x.mode := Cond;
    x.a := 0; x.b := 0 (* For FixLink to work properly in IF/ELSE *)
  END
END LoadCond;

(** Standard Functions **)

(** Ordinal number. x := ORD(x) *)
PROCEDURE Ord*(VAR x: Item);
BEGIN
  IF x.mode IN {ST.Var, ST.Const, Reg} THEN Load(x)
  ELSE S.Mark(E.incompatible)
  END
END Ord;

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
    Put0(Sub, x.r, RH, x.r)
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
    ELSE (* op = S.minus *)
      Put1(Sub, x.r, x.r, y.a)
    END
  ELSIF x.mode = ST.Const THEN (* y -- Reg or Var *)
    Load(y); (* x -- Const, y -- Reg *)
    IF op = S.minus THEN Neg(y) END;
    Put1(Add, y.r, y.r, x.a);
    x := y
  ELSE
    Load(x); Load(y); (* x -- Reg, y -- Reg *)
    IF op = S.plus THEN
      Put0(Add, x.r, x.r, y.r)
    ELSE (* op = S.minus *)
      Put0(Sub, x.r, x.r, y.r)
    END;
    DEC(RH)
  END
END AddOp;

PROCEDURE Negated(code: INTEGER): INTEGER;
BEGIN
  IF code < 8 THEN INC(code, 8) ELSE DEC(code, 8) END
RETURN code END Negated;

PROCEDURE Not*(VAR x: Item);
VAR t: INTEGER;
BEGIN
  LoadCond(x);
  x.r := Negated(x.r);
  t := x.a; x.a := x.b; x.b := t
END Not;

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
    ELSIF y.a <= 0 THEN S.Mark(E.badDiv)
    ELSIF op = S.div THEN
      Put1(Div, x.r, x.r, y.a)
    ELSE (* op = S.mod *)
      Put1(Div, x.r, x.r, y.a);
      Put0(Mov + U, x.r, 0, 0) (* R[x.r] := H *)
    END
  ELSIF x.mode = ST.Const THEN (* y -- Reg or Var *)
    Load(y); (* x -- Const, y -- Reg *)
    IF op = S.times THEN
      Put1(Mul, y.r, y.r, x.a)
    ELSE
      Load(x); (* x -- Reg, y -- Reg, y.r < x.r *)
      IF op = S.div THEN
        Put1(Div, y.r, x.r, y.r)
      ELSE (* op = S.mod *)
        Put1(Div, y.r, x.r, y.r);
        Put0(Mov + U, y.r, 0, 0) (* R[y.r] := H *)
      END;
      DEC(RH)
    END;
    x := y
  ELSE
    Load(x); Load(y); (* x -- Reg, y -- Reg *)
    IF op = S.times THEN
      Put0(Mul, x.r, x.r, y.r)
    ELSIF op = S.div THEN
      Put0(Div, x.r, x.r, y.r)
    ELSE (* op = S.mod *)
      Put0(Div, x.r, x.r, y.r);
      Put0(Mov + U, x.r, 0, 0) (* R[x.r] := H *)
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
VAR op: INTEGER;
BEGIN
  IF ~ST.TypesCompatible(x.type, y.type) THEN S.Mark(E.incompatible)
  ELSIF x.mode # ST.Var THEN S.Mark(E.assignConst(*?*))
  ELSE (* x -- Var, y -- Const, Var or Reg *)
    Load(y); (* x -- Var, y -- Reg *)
    op := Str;
    IF x.type.size = 1 THEN INC(op) END; (* BOOLEAN *)
    Put2(op, y.r, MP, x.a);
    DEC(RH)
  END
END Assign;

(** Jumps *)

PROCEDURE Here*(): INTEGER;
RETURN pc END Here;

PROCEDURE NextL(VAR L: INTEGER);
VAR tmp: Files.Rider;
  b: BYTE;
BEGIN
  Files.Set(tmp, F, L * 4 + codeStart + 1);
  Files.Read(tmp, b); L := b;
  Files.Read(tmp, b); L := L * 100H + b;
  Files.Read(tmp, b); L := L * 100H + b
END NextL;

PROCEDURE FixLink*(L: INTEGER);
VAR prevL: INTEGER;
BEGIN
  WHILE L # 0 DO
    prevL := L;
    NextL(L);
    PutOffset(prevL, pc - prevL - 1)
  END
END FixLink;

PROCEDURE Fixup*(VAR x: Item);
BEGIN FixLink(x.a)
END Fixup;

PROCEDURE CFJump*(VAR x: Item);
BEGIN
  LoadCond(x);
  Put3(BC, Negated(x.r), x.a);
  FixLink(x.b);
  x.b := 0; (* Required because of And1 *)
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
  LoadCond(x);
  Put3(BC, Negated(x.r), L - pc - 1);
  FixLink(x.b); (*FixLinkWith(x.a, L)*)
END CBJump;

PROCEDURE MergeLists(L1, L2: INTEGER): INTEGER;
VAR L, prevL: INTEGER;
BEGIN
  IF L1 = 0 THEN L1 := L2
  ELSIF L2 # 0 THEN
    L := L1;
    REPEAT prevL := L; NextL(L) UNTIL L = 0;
    PutOffset(prevL, L2)
  END
RETURN L1 END MergeLists;

(** x := x & *)
PROCEDURE And1*(VAR x: Item);
BEGIN
  LoadCond(x);
  CFJump(x)
END And1;

(** x := x & y *)
PROCEDURE And2*(VAR x, y: Item);
BEGIN
  LoadCond(y);
  x.a := MergeLists(y.a, x.a);
  x.b := y.b; x.r := y.r
END And2;

(** x := x OR *)
PROCEDURE Or1*(VAR x: Item);
BEGIN
  LoadCond(x);
  Put3(BC, x.r, x.b);
  FixLink(x.a); x.a := 0;
  x.b := pc - 1
END Or1;

(** x := x OR y *)
PROCEDURE Or2*(VAR x, y: Item);
BEGIN
  LoadCond(y);
  x.b := MergeLists(y.b, x.b);
  x.a := y.a; x.r := y.r
END Or2;

(** Procedure Calls *)

(** Value of parameters are stored in registers
    before a procedure call *)
PROCEDURE ValueParam*(VAR x: Item);
BEGIN Load(x)
END ValueParam;

(** VAR-parameters are stored in registers as pointers
    before a procedure call *)
PROCEDURE VarParam*(VAR x: Item);
BEGIN LoadAddr(x)
END VarParam;

(** Called before Actual Parameters.
    Does nothing on our implementation of RISC-5. *)
PROCEDURE PrepCall*(VAR x: Item; VAR rx: INTEGER);
END PrepCall;

(** Called after Actual Parameters *)
PROCEDURE Call*(VAR x: Item; rx: INTEGER);
BEGIN
  Put3(BL, AL, x.a); (* x.a is a fake call number, not an offset *)
  RH := 0 (* Do it only if x is a proper procedure *)
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
  Files.Register(F)
END Close;

BEGIN
  relmap[0] := 1; relmap[1] :=  9; relmap[2] := 5;
  relmap[3] := 6; relmap[4] := 14; relmap[5] := 13
END Generator.
