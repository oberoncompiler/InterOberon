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
  expBool*           = 9;
  expThen*           = 10;
  expDo*             = 11;
  expUntil*          = 12;
  expLparen*         = 30;
  expRparen*         = 31;
  expStatement*      = 32;

  notValue*          = 40;
  notInt*            = 41;
  notUsed*           = 42;
  notProcedure*      = 43;

  badDiv*            = 50;
  divByZero*         = 51;
  badVarPar*         = 52;

  assignConst*       = 59;
  incompatible*      = 60;
  undecl*            = 61;
  multipleDecl*      = 62;
  noModule*          = 63;
  noParams*          = 64;
  fewerParams*       = 65;
  moreParams*        = 66;
  onlyEqlNeq*        = 67;

  modNameMismatch*   = 90;
  unknownLang*       = 91;

  longString*        = 110;
  intOverflow*       = 111;
  regOverflow*       = 112;

  unknownKW*         = 114;
  stringTodo*        = 115;

PROCEDURE Get*(n: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN
  IF    n = expModule       THEN s := 'Ожидается MODULE'
  ELSIF n = expSemicol      THEN s := 'Ожидается точка с запятой'
  ELSIF n = expIdent        THEN s := 'Ожидается имя'
  ELSIF n = expEnd          THEN s := 'Ожидается END'
  ELSIF n = expPeriod       THEN s := 'Ожидается точка'
  ELSIF n = expColon        THEN s := 'Ожидается двоеточие'
  ELSIF n = expBecomes      THEN s := 'Ожидается :='
  ELSIF n = expType         THEN s := 'Ожидается тип'
  ELSIF n = expBool         THEN s := 'Ожидается значение булевого типа'
  ELSIF n = expThen         THEN s := 'Ожидается THEN'
  ELSIF n = expDo           THEN s := 'Ожидается DO'
  ELSIF n = expUntil        THEN s := 'Ожидается UNTIL'
  ELSIF n = expLparen       THEN s := 'Ожидается ('
  ELSIF n = expRparen       THEN s := 'Ожидается )'
  ELSIF n = expStatement    THEN s := 'Ожидается оператор'
  ELSIF n = notValue        THEN s := 'Это не значение'
  ELSIF n = notInt          THEN s := 'Это не целое число'
  ELSIF n = notUsed         THEN s := 'Возвращаемое значение не используется'
  ELSIF n = notProcedure    THEN s := 'Это не процедура'
  ELSIF n = badDiv          THEN s := 'Делитель не положительный'
  ELSIF n = divByZero       THEN s := 'Деление на нуль'
  ELSIF n = badVarPar       THEN s := 'Некорректный VAR-параметр'
  ELSIF n = assignConst     THEN s := 'Присваивание в константу'
  ELSIF n = incompatible    THEN s := 'Типы несовместимы'
  ELSIF n = undecl          THEN s := 'Необъявленное имя'
  ELSIF n = multipleDecl    THEN s := 'Имя уже объявлено'
  ELSIF n = noModule        THEN s := 'Модуль не существует'
  ELSIF n = noParams        THEN s := 'Ожидаются параметры процедуры'
  ELSIF n = fewerParams     THEN s := 'Слишком мало параметров'
  ELSIF n = moreParams      THEN s := 'Слишком много параметров'
  ELSIF n = onlyEqlNeq      THEN s := 'Можно сравнивать только на = и #'
  ELSIF n = modNameMismatch THEN s := 'Имя модуля не совпадает'
  ELSIF n = unknownLang     THEN s := 'Невозможно определить язык'
  ELSIF n = longString      THEN s := 'Строка слишком длинная'
  ELSIF n = intOverflow     THEN s := 'Целочисленное переполнение'
  ELSIF n = regOverflow     THEN s := 'Переполнение стека регистров'
  ELSIF n = unknownKW       THEN s := 'Неизвестное ключевое слово (ошибка в языковом файле)'
  ELSIF n = stringTodo      THEN s := 'Строковые литералы не реализованы'
  ELSE                           s := 'Неопознанная ошибка'
  END
END Get;

END ErrorMsg.
