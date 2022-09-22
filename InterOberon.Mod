MODULE InterOberon;
IMPORT Parser, Args, Out;

PROCEDURE Usage;
VAR s: ARRAY 256 OF CHAR;
BEGIN
  Args.Get(0, s);
  Out.String('InterOberon compiler, 2022'); Out.Ln; Out.Ln;
  Out.String('Usage:'); Out.Ln;
  Out.String('  '); Out.String(s); Out.String(' <module_name>'); Out.Ln
END Usage;

PROCEDURE RunCompiler;
VAR s: ARRAY 256 OF CHAR;
BEGIN
  (*Args.Get(1, s);*) s := 'Hello.Mod';
  IF Parser.Load(s) THEN
    Parser.Compile
  ELSE
    Out.String('File not found.'); Out.Ln
  END
END RunCompiler;

BEGIN
  IF TRUE OR (*!FIXME*) (Args.Count = 1) THEN
    RunCompiler
  ELSE
    Usage
  END
END InterOberon.