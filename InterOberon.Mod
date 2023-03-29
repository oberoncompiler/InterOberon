MODULE InterOberon;
IMPORT Parser, Args, Out, Risc, Lang;

PROCEDURE Usage;
VAR s: ARRAY 256 OF CHAR;
BEGIN
  Args.Get(0, s);
  Out.String('InterOberon compiler, 2022-2023'); Out.Ln; Out.Ln;
  Out.String('Usage:'); Out.Ln;
  Out.String('  '); Out.String(s); Out.String(' <module_name>'); Out.Ln
END Usage;

PROCEDURE RunCompiler;
VAR s: ARRAY 256 OF CHAR;
  res: INTEGER;
BEGIN
  Args.Get(1, s);
  IF Parser.Load(s) THEN
    IF Parser.Compile() THEN
      Out.String('Модуль '); Out.String(Parser.modName);
      Out.String(' спецскомпилирован.'); Out.Ln; Out.Ln;
      Out.String('Запускается виртуальная машина.'); Out.Ln;
      res := Risc.RunFile(Parser.modName);
      Out.Ln;
      IF res = Risc.noError THEN
        Out.String('Машина отработала без ошибок.'); Out.Ln
      ELSIF res = Risc.cantLoad THEN
        Out.String('Невозможно загрузить модуль.'); Out.Ln
      ELSE
        Out.String('Машина остановилась с кодом ошибки ');
        Out.Int(res, 0); Out.Char('.'); Out.Ln
      END
    ELSE
      Out.String('Спецкомпиляция полностью провалена!'); Out.Ln
    END
  ELSE
    Out.String('File not loaded.'); Out.Ln
  END
END RunCompiler;

BEGIN
  IF Args.Count() = 1 THEN
    RunCompiler
  ELSE
    Usage
  END
END InterOberon.
