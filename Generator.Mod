MODULE Generator;
IMPORT ST := SymTable, S := Scanner, E := ErrorMsg, Out;

CONST
  (** Values of Item.mode **)
  (** Some of Object Classes from SymTable are also valid *)
  Reg*  = 10;

TYPE
  (** Item is a generator object.
        |  mode |     a     |     b     |      r      |
        |  Reg  |     -     |     -     | register No |
        | Const |   value   |     -     |      -      |
  *)
  Item* = RECORD
    mode*: INTEGER; (** See constants above, also Object Classes *)
    type*: ST.Type;
    a*, b*, r*: INTEGER (** Meaning of a, b, r according to the table above *)
  END;

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

(** Operations **)

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
  ELSE
    (* !TODO *)
    x.mode := Reg
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
  ELSE
    (* !TODO *)
    x.mode := Reg
  END
END MulOp;

(** Negation. x := -x *)
PROCEDURE Neg*(VAR x: Item);
BEGIN
  IF x.mode = ST.Const THEN
    IF x.a # S.minInt THEN x.a := -x.a
    ELSE S.Mark(E.intOverflow)
    END
  END
END Neg;

END Generator.
