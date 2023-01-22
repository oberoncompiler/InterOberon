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
  expStatement*      = 31;

  notValue*          = 40;
  notInt*            = 41;
  notUsed*           = 42;
  notProcedure*      = 43;

  divZero*           = 50;

  assignConst*       = 59;
  incompatible*      = 60;
  undecl*            = 61;
  multipleDecl*      = 62;
  noModule*          = 63;
  noParams*          = 64;

  modNameMismatch*   = 90;

  longString*        = 110;
  intOverflow*       = 111;
  regOverflow*       = 112;

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
  ELSIF n = expStatement THEN s := 'Ожидается оператор'
  ELSIF n = notValue THEN s := 'Это не значение'
  ELSIF n = notInt THEN s := 'Это не целое число'
  ELSIF n = notUsed THEN s := 'Возвращаемое значение не используется'
  ELSIF n = notProcedure THEN s := 'Это не процедура'
  ELSIF n = divZero THEN s := 'Деление на ноль'
  ELSIF n = assignConst THEN s := 'Присваивание в константу'
  ELSIF n = incompatible THEN s := 'Типы несовместимы'
  ELSIF n = undecl THEN s := 'Необъявленное имя'
  ELSIF n = multipleDecl THEN s := 'Имя уже объявлено'
  ELSIF n = noModule THEN s := 'Модуль не существует'
  ELSIF n = noParams THEN s := 'Ожидаются параметры процедуры'
  ELSIF n = modNameMismatch THEN s := 'Имя модуля не совпадает'
  ELSIF n = longString THEN s := 'Строка слишком длинная'
  ELSIF n = intOverflow THEN s := 'Целочисленное переполнение'
  ELSIF n = regOverflow THEN s := 'Переполнение стека регистров'
  ELSIF n = stringTodo THEN s := 'Строковые литералы не реализованы'
  ELSE s := 'Неопознанная ошибка'
  END
END Get;

END ErrorMsg.
