MODULE InterOberon;
IMPORT Parser, Args, Out, Risc, Lang;

PROCEDURE Usage;
VAR s: ARRAY 256 OF CHAR;
BEGIN
  Args.Get(0, s);
  Out.String('InterOberon compiler, 2022-2023'); Out.Ln; Out.Ln;
  Out.String('Usage:'); Out.Ln;
  Out.String('  '); Out.String(s); Out.String(' <moduleName>'); Out.Ln
END Usage;

PROCEDURE RunCompiler;
VAR s: ARRAY 256 OF CHAR;
  res: INTEGER;
BEGIN
  Args.Get(1, s);
  IF Parser.Load(s) THEN
    IF Parser.Compile() THEN
      Lang.Write(Lang.compileOk1); Out.Char(' ');
      Out.String(Parser.modName); Out.Char(' ');
      Lang.Write(Lang.compileOk2); Out.Ln; Out.Ln;
      Lang.Write(Lang.vmStarting); Out.Ln;
      res := Risc.RunFile(Parser.modName);
      Out.Ln;
      IF res = Risc.noError THEN
        Lang.Write(Lang.vmOk); Out.Ln
      ELSIF res = Risc.cantLoad THEN
        Lang.Write(Lang.cantLoadMod); Out.Ln
      ELSE
        Lang.Write(Lang.vmHalt);
        Out.Int(res, 0); Out.Char('.'); Out.Ln
      END
    ELSE
      Lang.Write(Lang.compileFail); Out.Ln
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
