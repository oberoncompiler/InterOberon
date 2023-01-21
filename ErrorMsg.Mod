MODULE ErrorMsg;
CONST
  expModule*         = 1;
  expSemicol*        = 2;
  expIdent*          = 3;
  expEnd*            = 4;
  expPeriod*         = 5;
  expColon*          = 6;
  expBecomes*        = 7;
  expType*           = 8;
  expRparen*         = 30;

  notValue*          = 40;
  notInt*            = 41;

  divZero*           = 50;

  undecl*            = 60;
  multipleDecl*      = 61;
  noModule*          = 62;

  modNameMismatch*   = 90;

  longString*        = 110;
  intOverflow*       = 111;

  stringTodo*        = 200;

PROCEDURE Get*(n: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN
  IF n = expModule THEN s := 'Ожидается MODULE'
  ELSIF n = expSemicol THEN s := 'Ожидается точка с запятой'
  ELSIF n = expIdent THEN s := 'Ожидается имя'
  ELSIF n = expEnd THEN s := 'Ожидается END'
  ELSIF n = expPeriod THEN s := 'Ожидается точка'
  ELSIF n = expColon THEN s := 'Ожидается двоеточие'
  ELSIF n = expBecomes THEN s := 'Ожидается :='
  ELSIF n = expType THEN s := 'Ожидается тип'
  ELSIF n = expRparen THEN s := 'Ожидается )'
  ELSIF n = notValue THEN s := 'Это не значение'
  ELSIF n = notInt THEN s := 'Это не целое число'
  ELSIF n = divZero THEN s := 'Деление на ноль'
  ELSIF n = stringTodo THEN s := 'Строковые литералы не реализованы'
  ELSIF n = undecl THEN s := 'Необъявленное имя'
  ELSIF n = multipleDecl THEN s := 'Имя уже объявлено'
  ELSIF n = noModule THEN s := 'Модуль не существует'
  ELSIF n = modNameMismatch THEN s := 'Имя модуля не совпадает'
  ELSIF n = longString THEN s := 'Строка слишком длинная'
  ELSIF n = intOverflow THEN s := 'Целочисленное переполнение'
  ELSE s := 'Неопознанная ошибка'
  END
END Get;

END ErrorMsg.
