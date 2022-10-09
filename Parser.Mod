MODULE Parser;
IMPORT S := Scanner, E := ErrorMsg, Out, Strings;

VAR
  sym: INTEGER;

PROCEDURE Load*(fname: ARRAY OF CHAR): BOOLEAN;
RETURN S.Load(fname) END Load;

PROCEDURE Module;
VAR modName: ARRAY 64 OF CHAR;
BEGIN
  IF sym = S.module THEN
    S.Get(sym);
    IF sym = S.ident THEN
      Strings.Copy(S.id, modName);
      S.Get(sym);
      IF sym = S.semicol THEN S.Get(sym) ELSE S.Mark(E.expSemicol) END;

      (*...*)

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
