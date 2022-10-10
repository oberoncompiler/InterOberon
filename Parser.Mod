MODULE Parser;
IMPORT S := Scanner, E := ErrorMsg, Out, Strings;

VAR
  sym: INTEGER;

PROCEDURE Load*(fname: ARRAY OF CHAR): BOOLEAN;
RETURN S.Load(fname) END Load;

PROCEDURE ImportList;
BEGIN (*!TODO*)
END ImportList;

PROCEDURE DeclSeq;
BEGIN (*!TODO*)
END DeclSeq;

PROCEDURE Factor;
BEGIN
  IF sym = S.ident THEN
    Out.String(S.id); Out.Ln;
    S.Get(sym)
  END
END Factor;

PROCEDURE Term;
BEGIN
  Factor;
  WHILE sym = S.times DO
    S.Get(sym);
    Out.String('Умножение'); Out.Ln;
    Factor
  END
END Term;

PROCEDURE SimpleExpr;
BEGIN
  Term;
  WHILE sym = S.plus DO
    S.Get(sym);
    Out.String('Сложение'); Out.Ln;
    Term
  END
END SimpleExpr;

PROCEDURE Expr;
BEGIN
  SimpleExpr;
  WHILE sym = S.equals DO
    S.Get(sym);
    Out.String('Проверка на равенство'); Out.Ln;
    SimpleExpr
  END
END Expr;

PROCEDURE Assign(name: ARRAY OF CHAR);
BEGIN
  Out.String('Присваивание в '); Out.String(name);
  Out.String(' следующего выражения:'); Out.Ln;

  Expr
END Assign;

PROCEDURE Stat;
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
    END;
  END
END Stat;

PROCEDURE StatSeq;
BEGIN
  Stat;
  WHILE sym = S.semicol DO
    S.Get(sym);
    Stat
  END
END StatSeq;

PROCEDURE Module;
VAR modName: ARRAY 64 OF CHAR;
BEGIN
  IF sym = S.module THEN
    S.Get(sym);
    IF sym = S.ident THEN
      Strings.Copy(S.id, modName);
      S.Get(sym);
      IF sym = S.semicol THEN S.Get(sym) ELSE S.Mark(E.expSemicol) END;

      ImportList;
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
  Module;

  IF S.error THEN
    Out.String('Спецкомпиляция полностью провалена!'); Out.Ln
  END
END Compile;

END Parser.
