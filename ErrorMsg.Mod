MODULE ErrorMsg;
CONST
  expModule*         = 1;
  expSemicol*        = 2;
  expIdent*          = 3;
  expEnd*            = 4;
  expPeriod*         = 5;
  expBecomes*        = 6;
  expExpression*     = 7;
  expRparen*         = 40;

  modNameMismatch*   = 60;

  longString*        = 100;

PROCEDURE Get*(n: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN
  IF n = expModule THEN s := 'Ожидается MODULE'
  ELSIF n = expSemicol THEN s := 'Ожидается точка с запятой'
  ELSIF n = expIdent THEN s := 'Ожидается имя'
  ELSIF n = expEnd THEN s := 'Ожидается END'
  ELSIF n = expPeriod THEN s := 'Ожидается точка'
  ELSIF n = expBecomes THEN s := 'Ожидается :='
  ELSIF n = expExpression THEN s := 'Ожидается выражение'
  ELSIF n = expRparen THEN s := 'Ожидается )'
  ELSIF n = modNameMismatch THEN s := 'Имя модуля не совпадает'
  ELSIF n = longString THEN s := 'Строка слишком длинная'
  ELSE s := 'Неопознанная ошибка'
  END
END Get;

END ErrorMsg.
