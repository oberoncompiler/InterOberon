MODULE Generator;
IMPORT ST := SymTable, S := Scanner, E := ErrorMsg, Out;

CONST
  (** Values of Item.mode **)
  (** Some of Object Classes from SymTable are also valid *)
  Reg*  = 10;

  (** - **)
  maxGenReg = 12; (* Number of maximum available general-purpose register *)

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
  RH: INTEGER; (** Number of the highest free register *)

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

(** Write instruction with 1 argument -- a register *)
PROCEDURE Write1(inst: ARRAY OF CHAR; a: INTEGER);
BEGIN
  Out.String(inst);
  Out.String(' R'); Out.Int(a, 0); Out.Ln
END Write1;

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
      Write2i('MOV', RH, x.a)
    ELSIF x.mode = ST.Var THEN
      Write3i('LDR', RH, 13, x.a)
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
    Write1('NEG', x.r)
  END
END Neg;

(** Addition or subtraction. x := x op y *)
PROCEDURE AddOp*(op: INTEGER; VAR x, y: Item);
BEGIN
  IF (x.mode = ST.Const) & (y.mode = ST.Const) THEN
    IF op = S.plus THEN
      IF S.maxInt - y.a >= x.a THEN INC(x.a, y.a)
      ELSE S.Mark(E.intOverflow)
      END
    ELSE (* op = S.minus *)
      IF S.minInt + y.a <= x.a THEN DEC(x.a, y.a)
      ELSE S.Mark(E.intOverflow)
      END
    END
  ELSIF y.mode = ST.Const THEN (* x -- Reg or Var *)
    Load(x); (* x -- Reg, y -- Const *)
    IF op = S.plus THEN
      Write3i('ADD', x.r, x.r, y.a)
    ELSE (* op = S.minus *)
      Write3i('SUB', x.r, x.r, y.a)
    END
  ELSIF x.mode = ST.Const THEN (* y -- Reg or Var *)
    Load(y); (* x -- Const, y -- Reg *)
    IF op = S.plus THEN
      Write3i('ADD', y.r, y.r, x.a)
    ELSE (* op = S.minus *)
      Neg(y);
      Write3i('ADD', y.r, y.r, x.a)
    END;
    x := y
  ELSE
    Load(x); Load(y); (* x -- Reg, y -- Reg *)
    IF op = S.plus THEN
      Write3('ADD', x.r, x.r, y.r)
    ELSE (* op = S.minus *)
      Write3('SUB', x.r, x.r, y.r)
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
      IF y.a # 0 THEN x.a := x.a DIV y.a
      ELSE S.Mark(E.divZero)
      END
    ELSE (* op = S.mod *)
      IF y.a # 0 THEN x.a := x.a MOD y.a
      ELSE S.Mark(E.divZero)
      END
    END
  ELSIF y.mode = ST.Const THEN (* x -- Reg or Var *)
    Load(x); (* x -- Reg, y -- Const *)
    IF op = S.times THEN
      Write3i('MUL', x.r, x.r, y.a)
    ELSIF y.a = 0 THEN S.Mark(E.divZero)
    ELSIF op = S.div THEN
      Write3i('DIV', x.r, x.r, y.a)
    ELSE (* op = S.mod *)
      Write3i('MOD', x.r, x.r, y.a)
    END
  ELSIF x.mode = ST.Const THEN (* y -- Reg or Var *)
    Load(y); (* x -- Const, y -- Reg *)
    IF op = S.times THEN
      Write3i('MUL', y.r, y.r, x.a)
    ELSE
      Load(x); (* x -- Reg, y -- Reg, y.r < x.r *)
      IF op = S.div THEN
        Write3('DIV', y.r, x.r, y.r)
      ELSE (* op = S.mod *)
        Write3('MOD', y.r, x.r, y.r)
      END;
      DEC(RH)
    END;
    x := y
  ELSE
    Load(x); Load(y); (* x -- Reg, y -- Reg *)
    IF op = S.times THEN
      Write3('MUL', x.r, x.r, y.r)
    ELSIF op = S.div THEN
      Write3('DIV', x.r, x.r, y.r)
    ELSE (* op = S.mod *)
      Write3('MOD', x.r, x.r, y.r)
    END;
    DEC(RH)
  END
END MulOp;

PROCEDURE Assign*(VAR x, y: Item);
BEGIN
  IF ~ST.TypesCompatible(x.type, y.type) THEN S.Mark(E.incompatible)
  ELSIF x.mode # ST.Var THEN S.Mark(E.assignConst(*?*))
  ELSE (* x -- Var, y -- Const, Var or Reg *)
    Load(y); (* x -- Var, y -- Reg *)
    Write3i('STR', y.r, 13, x.a);
    DEC(RH)
  END
END Assign;

(** Procedure Calls *)

(** Called before Actual Parameters *)
PROCEDURE PrepCall*(VAR x: Item; rx: INTEGER);
BEGIN
  Out.String('Подготовка вызова процедуры'); Out.Ln
END PrepCall;

(** Called after Actual Parameters *)
PROCEDURE Call*(VAR x: Item; rx: INTEGER);
BEGIN
  Out.String('Вызов процедуры'); Out.Ln
END Call;

PROCEDURE Init*;
BEGIN
  RH := 0
END Init;

END Generator.
