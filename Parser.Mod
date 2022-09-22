MODULE Parser;
IMPORT Scanner, Out;

PROCEDURE Load*(fname: ARRAY OF CHAR): BOOLEAN;
RETURN Scanner.Load(fname) END Load;

PROCEDURE Compile*;
BEGIN
  Scanner.Test
END Compile;

END Parser.