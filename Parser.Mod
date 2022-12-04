MODULE Parser;
IMPORT S := Scanner, ST := SymTable, E := ErrorMsg, Out, Strings;

VAR
  sym: INTEGER;

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
    M := ST.dummy;
    ST.NewObject(ST.Mod, name);
    S.Get(sym);
    IF sym = S.becomes THEN
      S.Get(sym);
      IF sym = S.ident THEN Strings.Copy(S.id, name)
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
VAR p: ST.Object;
  T: ST.Type;
BEGIN
  p := ST.dummy; (* Save pointer to the first object created below *)
  ST.NewObject(ST.Var, S.id);
  S.Get(sym);
  WHILE sym = S.comma DO
    S.Get(sym);
    IF sym = S.ident THEN
      ST.NewObject(ST.Var, S.id);
      S.Get(sym)
    ELSE S.Mark(E.expIdent)
    END
  END;
  IF sym = S.colon THEN
    S.Get(sym);
    Type(T);
    WHILE p # ST.dummy DO
      p.type := T;
      p := p.next
    END
  ELSE S.Mark(E.expColon)
  END
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

(* Factor = Ident | Number | "(" Expr ")". *)
PROCEDURE Factor;
BEGIN
  IF sym = S.lparen THEN
    S.Get(sym);
    Expr;
    IF sym = S.rparen THEN S.Get(sym) ELSE S.Mark(E.expRparen) END
  ELSIF sym = S.int THEN
    Out.String('Число '); Out.Int(S.ival, 0); Out.Ln;
    S.Get(sym)
  ELSIF sym = S.ident THEN
    Out.String(S.id); Out.Ln;
    S.Get(sym)
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

PROCEDURE Assign(name: ARRAY OF CHAR);
BEGIN
  Out.String('Присваивание в '); Out.String(name);
  Out.String(' следующего выражения:'); Out.Ln;

  Expr
END Assign;

(* Statement = [Assign]. *)
PROCEDURE Statement;
VAR name: ARRAY 256 OF CHAR;
BEGIN
  IF sym = S.ident THEN
    Strings.Copy(S.id, name);
    S.Get(sym);
    IF sym = S.equals THEN S.Mark(E.expBecomes); sym := S.becomes END;
    IF sym = S.becomes THEN
      S.Get(sym);
      Assign(name)
    ELSE S.Mark(E.expBecomes)
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
  Expr := Expr0
END Parser.
