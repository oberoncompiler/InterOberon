MODULE Parser;
IMPORT S := Scanner, ST := SymTable, E := ErrorMsg, Out, Strings;

VAR
  sym: INTEGER;
  dummy: ST.Object; (** In case of error in QualIdent *)

  Expr: PROCEDURE;

PROCEDURE Load*(fname: ARRAY OF CHAR): BOOLEAN;
RETURN S.Load(fname) END Load;

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
      Out.String('В модуле '); Out.String(obj.name); Out.Ln;
      S.Get(sym);
      IF sym = S.ident THEN
        obj := ST.ThisImport(obj);
        S.Get(sym);
        IF obj = NIL THEN S.Mark(E.undecl); obj := dummy END
      ELSE S.Mark(E.expIdent); obj := dummy
      END
    END;
    Out.String('Уточнённое имя '); Out.String(obj.name); Out.Ln
  ELSE S.Mark(E.expIdent)
  END
END QualIdent;

(* Factor = Designator | Number | "(" Expr ")". *)
PROCEDURE Factor;
VAR obj: ST.Object;
BEGIN
  IF sym = S.lparen THEN
    S.Get(sym);
    Expr;
    IF sym = S.rparen THEN S.Get(sym) ELSE S.Mark(E.expRparen) END
  ELSIF sym = S.int THEN
    Out.String('Число '); Out.Int(S.ival, 0); Out.Ln;
    S.Get(sym)
  ELSIF sym = S.ident THEN
    QualIdent(obj);
    Out.String('Объект '); Out.String(obj.name); Out.Ln
  ELSIF sym = S.string THEN
    Out.String('Строка "'); Out.String(S.sval); Out.Char('"'); Out.Ln;
    S.Get(sym)
  ELSE S.Mark(E.expValue)
  END
END Factor;

(* Term = Factor [MulOperator Factor]. *)
PROCEDURE Term;
BEGIN
  Factor;
  WHILE sym = S.times DO
    S.Get(sym);
    Out.String('Умножение'); Out.Ln;
    Factor
  END
END Term;

(* SimpleExpr = Term [AddOperator Term]. *)
PROCEDURE SimpleExpr;
BEGIN
  Term;
  WHILE (sym = S.plus) OR (sym = S.minus) DO
    IF sym = S.plus THEN Out.String('Спецсложение')
    ELSE Out.String('Спецвычитание')
    END;
    Out.Ln;
    S.Get(sym);
    Term
  END
END SimpleExpr;

(* Expr = SimpleExpr [relation SimpleExpr]. *)
PROCEDURE Expr0;
BEGIN
  SimpleExpr;
  IF sym = S.equals THEN
    S.Get(sym);
    Out.String('Проверка на равенство'); Out.Ln;
    SimpleExpr
  END
END Expr0;

(** Assign = Designator ":=" Expr. *)
PROCEDURE Assign;
BEGIN

  Expr
END Assign;

(** ExprList = Expr {"," Expr}. *)
PROCEDURE ExprList;
BEGIN
  
END ExprList;

(** Param = Expr. *)
PROCEDURE Param;
BEGIN
  Expr
END Param;

(** ActualParams = "(" [ExprList] ")". *)
PROCEDURE ActualParams;
VAR n: INTEGER;
BEGIN
  S.Get(sym);
  IF sym # S.rparen THEN
    Param; n := 1;
    WHILE sym = S.comma DO
      S.Get(sym);
      Param;
      INC(n)
    END;
    IF sym = S.rparen THEN S.Get(sym) ELSE S.Mark(E.expRparen) END
  ELSE S.Get(sym); n := 0
  END;
  Out.String('Прочитано параметров: '); Out.Int(n, 0); Out.Ln
END ActualParams;

(** ProcedureCall = Designator [ActualParams]. *)
PROCEDURE ProcedureCall;
BEGIN
  IF sym = S.lparen THEN
    ActualParams
  (*!FIXME ELSIF nofpars... *)
  END
END ProcedureCall;

(** Statement = [Assign | ProcedureCall]. *)
PROCEDURE Statement;
VAR obj: ST.Object;
BEGIN
  IF sym = S.ident THEN
    QualIdent(obj);
    Selector;
    IF sym = S.equals THEN S.Mark(E.expBecomes); sym := S.becomes END;
    IF sym = S.becomes THEN
      S.Get(sym);
      Out.String('Присваивание в '); Out.String(obj.name);
      Out.String(' следующего выражения:'); Out.Ln;
      Assign
    ELSE
      Out.String('Вызов процедуры '); Out.String(obj.name); Out.Ln;
      ProcedureCall
    END
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
VAR modName: ARRAY 64 OF CHAR;
BEGIN
  IF sym = S.module THEN
    S.Get(sym);
    IF sym = S.ident THEN
      Strings.Copy(S.id, modName);
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

  IF ~S.error THEN (*!FIXME*)
    Out.String('Модуль ');
    Out.String(modName);
    Out.String(' спецскомпилирован.'); Out.Ln
  END
END Module;

PROCEDURE Compile*;
BEGIN
  (*S.Test*)

  S.Get(sym);
  ST.Init;
  Module;

  IF S.error THEN
    Out.String('Спецкомпиляция полностью провалена!'); Out.Ln
  ELSE
    ST.ShowDebug
  END
END Compile;

BEGIN
  Expr := Expr0;
  NEW(dummy); dummy.class := ST.Var; dummy.type := ST.intType
END Parser.
