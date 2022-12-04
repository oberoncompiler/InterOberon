MODULE ErrorMsg;
CONST
  expModule*         = 1;
  expSemicol*        = 2;
  expIdent*          = 3;
  expEnd*            = 4;
  expPeriod*         = 5;
  expColon*          = 6;
  expBecomes*        = 7;
  expExpression*     = 8;
  expType*           = 9;
  expRparen*         = 40;

  undecl*            = 60;
  multipleDecl*      = 61;
  noModule*          = 62;

  modNameMismatch*   = 90;

  longString*        = 110;

PROCEDURE Get*(n: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN
  IF n = expModule THEN s := 'Ожидается MODULE'
  ELSIF n = expSemicol THEN s := 'Ожидается точка с запятой'
  ELSIF n = expIdent THEN s := 'Ожидается имя'
  ELSIF n = expEnd THEN s := 'Ожидается END'
  ELSIF n = expPeriod THEN s := 'Ожидается точка'
  ELSIF n = expColon THEN s := 'Ожидается двоеточие'
  ELSIF n = expBecomes THEN s := 'Ожидается :='
  ELSIF n = expExpression THEN s := 'Ожидается выражение'
  ELSIF n = expType THEN s := 'Ожидается тип'
  ELSIF n = expRparen THEN s := 'Ожидается )'
  ELSIF n = undecl THEN s := 'Необъявленное имя'
  ELSIF n = multipleDecl THEN s := 'Имя уже объявлено'
  ELSIF n = noModule THEN s := 'Модуль не существует'
  ELSIF n = modNameMismatch THEN s := 'Имя модуля не совпадает'
  ELSIF n = longString THEN s := 'Строка слишком длинная'
  ELSE s := 'Неопознанная ошибка'
  END
END Get;

END ErrorMsg.
