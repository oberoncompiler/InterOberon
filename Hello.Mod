МОДУЛЬ Белорусификация;
ИМПОРТ Ввод, Вывод;
ПЕРЕМЕННЫЕ
  а, б, в, г: ЛИТЕРА;
НАЧАЛО
  Вывод.Литера('В'); Вывод.Литера('в'); Вывод.Литера('е');
  Вывод.Литера('д'); Вывод.Литера('и'); Вывод.Литера('т');
  Вывод.Литера('е'); Вывод.Литера(' '); Вывод.Литера('4');
  Вывод.Литера(' '); Вывод.Литера('б'); Вывод.Литера('у');
  Вывод.Литера('к'); Вывод.Литера('в'); Вывод.Литера('ы'); Вывод.Перенос;

  Ввод.Литера(а); Ввод.Литера(б);
  Ввод.Литера(в); Ввод.Литера(г);

  Вывод.Перенос;

  г := "w";

  ЕСЛИ а = ЛИТ(0) ТОГДА Вывод.Литера("*") ИНАЧЕ Вывод.Литера(а) КОНЕЦ;
  ЕСЛИ б = ЛИТ(0) ТОГДА Вывод.Литера("*") ИНАЧЕ Вывод.Литера(б) КОНЕЦ;
  ЕСЛИ в = ЛИТ(0) ТОГДА Вывод.Литера("*") ИНАЧЕ Вывод.Литера(в) КОНЕЦ;
  ЕСЛИ г = ЛИТ(0) ТОГДА Вывод.Литера("*") ИНАЧЕ Вывод.Литера(г) КОНЕЦ;

  Вывод.Перенос
КОНЕЦ Белорусификация.
