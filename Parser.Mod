MODULE Parser;
IMPORT S := Scanner, ST := SymTable, E := ErrorMsg, Out, Strings,
  G := Generator;

VAR
  sym: INTEGER;
  dummy: ST.Object; (** In case of error in QualIdent *)
  varsize: INTEGER; (** How many bytes do variables occupy *)

  Expr0: PROCEDURE(VAR x: G.Item);
  StatSeq0: PROCEDURE;

  modName*: ARRAY 64 OF CHAR; (** Name of last compiled module *)

PROCEDURE Load*(fname: ARRAY OF CHAR): BOOLEAN;
RETURN S.Load(fname) END Load;

PROCEDURE CheckInt(VAR x: G.Item);
BEGIN
  IF x.type.form # ST.Int THEN
    S.Mark(E.notInt);
    x.type := ST.intType
  END
END CheckInt;

(** Import = [ident ":="] ident. *)
PROCEDURE Import;
VAR name: ARRAY 64 OF CHAR;
  M: ST.Object;
BEGIN
  IF sym = S.ident THEN
    Strings.Copy(S.id, name);
    M := ST.NewObject(ST.Mod, name);
    S.Get(sym);
    IF sym = S.becomes THEN
      S.Get(sym);
      IF sym = S.ident THEN Strings.Copy(S.id, name); S.Get(sym)
      ELSE S.Mark(E.expIdent)
      END
    END;
    ST.Import(M, name)
  ELSE S.Mark(E.expIdent)
  END
END Import;

(** ImportList = Import {"," Import} ";". *)
PROCEDURE ImportList;
BEGIN
  Import;
  WHILE sym = S.comma DO S.Get(sym); Import END;
  IF sym = S.semicol THEN S.Get(sym) ELSE S.Mark(E.expSemicol) END
END ImportList;

(** Type = ident. *)
PROCEDURE Type(VAR T: ST.Type);
VAR p: ST.Object;
BEGIN
  IF sym = S.ident THEN
    p := ST.ThisObject();
    S.Get(sym);
    IF p # NIL THEN
      IF p.class = ST.Typ THEN
        T := p.type
      ELSE S.Mark(E.expType)
      END
    ELSE S.Mark(E.undecl)
    END
  ELSE S.Mark(E.expIdent)
  END
END Type;

(** VarDecl = IdentList ":" Type. *)
PROCEDURE VarDecl;
VAR p, q: ST.Object;
  T: ST.Type;
BEGIN
  (* Save pointer to the first object created below *)
  p := ST.NewObject(ST.Var, S.id);
  S.Get(sym);
  WHILE sym = S.comma DO
    S.Get(sym);
    IF sym = S.ident THEN
      q := ST.NewObject(ST.Var, S.id);
      S.Get(sym)
    ELSE S.Mark(E.expIdent)
    END
  END;
  IF sym = S.colon THEN ELSE S.Mark(E.expColon) END;
  S.Get(sym);
  Type(T);
  REPEAT
    p.type := T;
    IF T.size > 1 THEN
      varsize := (varsize + T.size - 1) DIV T.size * T.size
    END;
    p.val := varsize;
    varsize := varsize + T.size;
    p := p.next
  UNTIL p = ST.dummy
END VarDecl;

(** DeclSeq = [VAR {VarDecl ";"}]. *)
PROCEDURE DeclSeq;
BEGIN
  IF sym = S.var THEN
    S.Get(sym);
    WHILE sym = S.ident DO
      VarDecl;
      IF sym = S.semicol THEN S.Get(sym) ELSE S.Mark(E.expSemicol) END
    END
  END
END DeclSeq;

(** Selector = . *)
PROCEDURE Selector;
BEGIN
END Selector;

(** QualIdent = [ident "."] ident. *)
PROCEDURE QualIdent(VAR obj: ST.Object);
BEGIN
  IF sym = S.ident THEN
    obj := ST.ThisObject();
    IF obj = NIL THEN S.Mark(E.undecl); obj := dummy END;
    S.Get(sym);
    IF (sym = S.period) & (obj.class = ST.Mod) THEN
      S.Get(sym);
      IF sym = S.ident THEN
        obj := ST.ThisImport(obj);
        S.Get(sym);
        IF obj = NIL THEN S.Mark(E.undecl); obj := dummy END
      ELSE S.Mark(E.expIdent); obj := dummy
      END
    END
  ELSE S.Mark(E.expIdent)
  END
END QualIdent;

(* Factor = Designator | Number | String | FALSE | TRUE | "(" Expr ")". *)
PROCEDURE Factor(VAR x: G.Item);
VAR obj: ST.Object;
BEGIN
  IF sym = S.lparen THEN
    S.Get(sym);
    Expr0(x);
    IF sym = S.rparen THEN S.Get(sym) ELSE S.Mark(E.expRparen) END
  ELSIF sym = S.int THEN
    G.MakeConstItem(x, ST.intType, S.ival);
    S.Get(sym)
  ELSIF sym = S.ident THEN
    QualIdent(obj);
    G.MakeItem(x, obj)
  ELSIF sym = S.string THEN
    G.MakeConstItem(x, ST.charType, ORD(S.sval[0]));
    IF S.len # 1 THEN S.Mark(E.stringTodo) END;
    S.Get(sym)
  ELSIF (sym = S.false) OR (sym = S.true) THEN
    G.MakeConstItem(x, ST.boolType, ORD(sym = S.true));
    S.Get(sym)
  ELSE S.Mark(E.notValue)
  END
END Factor;

(* Term = Factor [MulOperator Factor].
   MulOperator = "*" | "DIV" | "MOD". *)
PROCEDURE Term(VAR x: G.Item);
VAR op: INTEGER;
  y: G.Item;
BEGIN
  Factor(x);
  WHILE (sym = S.times) OR (sym = S.div) OR (sym = S.mod) DO
    op := sym;
    S.Get(sym);
    Factor(y);
    IF x.type.form = ST.Int THEN
      CheckInt(y);
      G.MulOp(op, x, y)
    ELSE S.Mark(E.incompatible)
    END
  END
END Term;

(* SimpleExpr = ["+" | "-"] Term [AddOperator Term].
   AddOperator = "+" | "-". *)
PROCEDURE SimpleExpr(VAR x: G.Item);
VAR op: INTEGER;
  y: G.Item;
  minus: BOOLEAN;
BEGIN
  IF sym = S.minus THEN S.Get(sym); minus := TRUE
  ELSE minus := FALSE;
    IF sym = S.plus THEN S.Get(sym) END
  END;
  Term(x);
  IF minus THEN G.Neg(x) END;
  WHILE (sym = S.plus) OR (sym = S.minus) DO
    op := sym;
    S.Get(sym);
    Term(y);
    IF x.type.form = ST.Int THEN
      CheckInt(y);
      G.AddOp(op, x, y)
    ELSE S.Mark(E.incompatible)
    END
  END
END SimpleExpr;

(* Expr = SimpleExpr [relation SimpleExpr]. *)
PROCEDURE Expr(VAR x: G.Item);
VAR op: INTEGER;
  y: G.Item;
BEGIN
  SimpleExpr(x);
  IF (S.eql <= sym) & (sym <= S.geq) THEN
    op := sym;
    S.Get(sym);
    SimpleExpr(y);
    IF (x.type.form IN {ST.Char, ST.Int}) & (x.type = y.type) THEN
      G.IntRel(op, x, y);
      x.type := ST.boolType
    ELSIF x.type.form = ST.Bool THEN
      IF op <= S.neq THEN G.IntRel(op, x, y)
      ELSE S.Mark(E.onlyEqlNeq)
      END
    ELSE S.Mark(E.incompatible)
    END
  END
END Expr;

(** Assign = Designator ":=" Expr. *)
PROCEDURE Assign(obj: ST.Object);
VAR x, y: G.Item;
BEGIN
  G.MakeItem(x, obj); 
  Expr(y);
  G.Assign(x, y)
END Assign;

(** ExprList = Expr {"," Expr}. *)
PROCEDURE ExprList;
BEGIN
  
END ExprList;

(** Param = Expr.
     par can be NIL *)
PROCEDURE Param(par: ST.Object);
VAR x: G.Item;
BEGIN
  Expr(x);
  IF par # NIL THEN
    IF ST.TypesCompatible(par.type, x.type) THEN
      G.ValueParam(x);
    ELSE S.Mark(E.incompatible)
    END
  END
END Param;

(** ActualParams = "(" [ExprList] ")". *)
PROCEDURE ActualParams(VAR x: G.Item);
VAR n: INTEGER;
  par: ST.Object;
BEGIN
  S.Get(sym);
  IF sym # S.rparen THEN
    par := x.type.dsc;
    Param(par); n := 1;
    WHILE sym = S.comma DO
      S.Get(sym);
      IF par # NIL THEN par := par.next END;
      Param(par);
      INC(n)
    END
  ELSE n := 0
  END;
  IF n < x.type.nofpars THEN S.Mark(E.fewerParams)
  ELSIF n > x.type.nofpars THEN S.Mark(E.moreParams)
  END;
  IF sym = S.rparen THEN S.Get(sym) ELSE S.Mark(E.expRparen) END
END ActualParams;

(** ProcedureCall = Designator [ActualParams]. *)
PROCEDURE ProcedureCall(obj: ST.Object);
VAR x: G.Item;
  rx: INTEGER;
BEGIN
  G.MakeItem(x, obj);
  IF sym = S.lparen THEN (* With parameters *)
    IF x.type.form # ST.Proc THEN S.Mark(E.notProcedure)
    ELSE
      IF x.type.base.form # ST.NoTyp THEN S.Mark(E.notUsed) END;
      G.PrepCall(x, rx); ActualParams(x); G.Call(x, rx)
    END
  ELSIF x.type.form = ST.Proc THEN (* Procedure with no parameters *)
    IF x.type.nofpars > 0 THEN S.Mark(E.noParams) END;
    IF x.type.base.form # ST.NoTyp THEN S.Mark(E.notUsed)
    ELSE G.PrepCall(x, rx); G.Call(x, rx)
    END
  ELSE S.Mark(E.expStatement)
  END
END ProcedureCall;

(** IfStatement = IF expression THEN StatementSequence
    {ELSIF expression THEN StatementSequence}
    [ELSE StatementSequence] END. *)
PROCEDURE IfStatement;
VAR x: G.Item;
  L: INTEGER;
BEGIN
  S.Get(sym);
  Expr(x);
  IF x.type.form # ST.Bool THEN S.Mark(E.expBool) END;

  (* CONDITIONAL JUMP *)
  G.CFJump(x);

  IF sym = S.then THEN S.Get(sym) ELSE S.Mark(E.expThen) END;

  StatSeq0;
  L := 0;
  WHILE sym = S.elsif DO
    S.Get(sym);

    (* UNCONDITIONAL JUMP *)
    G.FJump(L);

    (* FIXUP CONDITIONAL JUMP *)
    G.Fixup(x);

    Expr(x);
    IF x.type.form # ST.Bool THEN S.Mark(E.expBool) END;
    IF sym = S.then THEN S.Get(sym) ELSE S.Mark(E.expThen) END;

    (* CONDITIONAL JUMP *)
    G.CFJump(x);

    StatSeq0
  END;

  IF sym = S.else THEN
    S.Get(sym);

    (* UNCONDITIONAL JUMP *)
    G.FJump(L);

    (* FIXUP CONDITIONAL JUMP *)
    G.Fixup(x);

    StatSeq0
  END;

  IF sym = S.end THEN S.Get(sym) ELSE S.Mark(E.expEnd) END;

  (* FIXUP UNCONDITIONAL JUMP *)
  G.FixLink(L)
END IfStatement;

(** WhileStatement = WHILE expression DO StatementSequence
    {ELSIF expression DO StatementSequence} END. *)
PROCEDURE WhileStatement;
VAR x: G.Item;
  L: INTEGER;
BEGIN
  L := G.Here();
  S.Get(sym);
  Expr(x);
  IF x.type.form # ST.Bool THEN S.Mark(E.expBool) END;

  (* CONDITIONAL JUMP *)
  G.CFJump(x);

  IF sym = S.do THEN S.Get(sym) ELSE S.Mark(E.expDo) END;

  StatSeq0;

  (* UNCONDITIONAL BACK JUMP TO START OF LOOP *)
  G.BJump(L);

  WHILE sym = S.elsif DO
    S.Get(sym);

    (* FIXUP CONDITIONAL JUMP *)
    G.Fixup(x);

    Expr(x);
    IF x.type.form # ST.Bool THEN S.Mark(E.expBool) END;
    IF sym = S.do THEN S.Get(sym) ELSE S.Mark(E.expDo) END;

    (* CONDITIONAL JUMP *)
    G.CFJump(x);

    StatSeq0;

    (* UNCONDITIONAL BACK JUMP TO START OF LOOP *)
    G.BJump(L)
  END;

  (* FIXUP CONDITIONAL JUMP *)
  G.Fixup(x);

  IF sym = S.end THEN S.Get(sym) ELSE S.Mark(E.expEnd) END
END WhileStatement;

PROCEDURE RepeatStatement;
VAR x: G.Item;
  L: INTEGER;
BEGIN
  L := G.Here();
  S.Get(sym);

  StatSeq0;

  IF sym # S.until THEN S.Mark(E.expUntil)
  ELSE S.Get(sym);
    Expr(x);
    IF x.type.form # ST.Bool THEN S.Mark(E.expBool) END;

    (* CONDITIONAL BACK JUMP TO START OF LOOP *)
    G.CBJump(x, L)
  END
END RepeatStatement;

(** Statement = [Assign | ProcedureCall | IfStatement |
    WhileStatement | RepeatStatement ]. *)
PROCEDURE Statement;
VAR obj: ST.Object;
BEGIN
  IF sym = S.ident THEN
    QualIdent(obj);
    Selector;
    IF sym = S.eql THEN S.Mark(E.expBecomes); sym := S.becomes END;
    IF sym = S.becomes THEN
      S.Get(sym);
      Out.String('Присваивание в '); Out.String(obj.name);
      Out.String(' следующего выражения:'); Out.Ln;
      Assign(obj)
    ELSE
      Out.String('    (Вызов процедуры ');
      Out.String(obj.name); Out.Char(')'); Out.Ln;
      ProcedureCall(obj)
    END
  ELSIF sym = S.if THEN
    IfStatement
  ELSIF sym = S.while THEN
    WhileStatement
  ELSIF sym = S.repeat THEN
    RepeatStatement
  END
END Statement;

PROCEDURE StatSeq;
BEGIN
  Statement;
  WHILE sym = S.semicol DO
    S.Get(sym);
    Statement
  END
END StatSeq;

(** Module = MODULE ident ";" [IMPORT ImportList] DeclSeq
             [BEGIN StatSeq] END ident ".". *)
PROCEDURE Module;
BEGIN
  varsize := 0;
  IF sym = S.module THEN
    S.Get(sym);
    IF sym = S.ident THEN
      Strings.Copy(S.id, modName);
      G.Open(modName);
      S.Get(sym);
      IF sym = S.semicol THEN S.Get(sym) ELSE S.Mark(E.expSemicol) END;

      IF sym = S.import THEN S.Get(sym); ImportList END;
      DeclSeq;
      IF sym = S.begin THEN S.Get(sym); StatSeq END;

      IF sym = S.end THEN
        S.Get(sym);
        IF sym = S.ident THEN
          IF modName # S.id THEN S.Mark(E.modNameMismatch) END;
          S.Get(sym);
          IF sym = S.period THEN S.Get(sym) ELSE S.Mark(E.expPeriod) END
        ELSE S.Mark(E.expIdent)
        END
      ELSE S.Mark(E.expEnd)
      END
    ELSE S.Mark(E.expIdent)
    END
  ELSE S.Mark(E.expModule)
  END;
  IF ~S.error THEN G.Close END
END Module;

PROCEDURE Compile*(): BOOLEAN;
BEGIN
  S.Get(sym);
  ST.Init;
  G.Init;
  Module
RETURN ~S.error END Compile;

BEGIN
  Expr0 := Expr;
  StatSeq0 := StatSeq;
  NEW(dummy); dummy.class := ST.Var; dummy.type := ST.intType
END Parser.
