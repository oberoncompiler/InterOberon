MODULE Risc;
IMPORT Out, Files, Strings;

CONST
  version* = 1; (** Machine code file version *)
  (** 'RSC' + CHR(version) as INTEGER *)
  fileMark* = ORD('R') + 256 * (ORD('S') + 256 * (ORD('C') + 256 * version));

  (** Error codes **)
  noError*  = 0;
  cantLoad* = -1;

  (** Machine characteristics **)
  memLen* = 4096; (** Size of RAM in words (4 bytes) *)

VAR
  mem: ARRAY memLen OF INTEGER; (** Memory *)
  PC: INTEGER; (** Program counter (index in mem of next instruction) *)

PROCEDURE Run*(): INTEGER;
VAR res: INTEGER;
BEGIN
  res := noError;
  PC := 0;
RETURN res END Run;

PROCEDURE ReadMemory(VAR R: Files.Rider): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
  ok := TRUE;
  (*!TODO*)
RETURN ok END ReadMemory;

PROCEDURE ReadMark(VAR R: Files.Rider): BOOLEAN;
VAR n: INTEGER;
BEGIN Files.ReadInt(R, n);
RETURN ~R.eof & (n = fileMark) END ReadMark;

PROCEDURE Load*(fname: ARRAY OF CHAR): BOOLEAN;
VAR F: Files.File;
  R: Files.Rider;
BEGIN
  F := Files.Old(fname);
  IF F # NIL THEN
    Files.Set(R, F, 0);
    IF ~ReadMark(R) & ~ReadMemory(R) THEN
      F := NIL
    END
  END
RETURN F # NIL END Load;

PROCEDURE RunFile*(modName: ARRAY OF CHAR): INTEGER;
VAR fname: ARRAY 64 OF CHAR;
  res: INTEGER;
BEGIN
  Strings.Copy(modName, fname); Strings.Append('.o', fname);
  IF Load(fname) THEN
    res := Run()
  ELSE
    res := cantLoad
  END
RETURN res END RunFile;

END Risc.
