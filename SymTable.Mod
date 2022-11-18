MODULE SymTable;
IMPORT Out;

CONST
  (** Object Classes **)
  Head* = 0;
  Var*  = 2;
  Typ*  = 5;
  Mod*  = 8;

  (** Type Forms **)
  Bool*  = 2;
  Char*  = 3;
  Int*   = 4;
  NoTyp* = 9;

TYPE
  Object* = POINTER TO ObjectDesc;
  Type* = POINTER TO TypeDesc;

  ObjectDesc* = RECORD
    name*: ARRAY 64 OF CHAR;
    class*: INTEGER; (** See Object Classes *)
    dsc*: Object;
    next*: Object;
    type*: Type
  END;

  TypeDesc* = RECORD
    form*: INTEGER
  END;

VAR
  topScope: Object;

PROCEDURE InitUniverse(U: Object);
BEGIN
  NEW(U.next);
  U := U.next;
  U.name := 'BOOLEAN';
  U.class := Typ;
  NEW(U.type);
  U.type.form := Bool;

  NEW(U.next);
  U := U.next;
  U.name := 'CHAR';
  U.class := Typ;
  NEW(U.type);
  U.type.form := Char;

  NEW(U.next);
  U := U.next;
  U.name := 'INTEGER';
  U.class := Typ;
  NEW(U.type);
  U.type.form := Int
END InitUniverse;

PROCEDURE Init*;
BEGIN
  NEW(topScope);
  topScope.class := Head;
  NEW(topScope.dsc);
  topScope.dsc.class := Head;
  InitUniverse(topScope.dsc)
END Init;

END SymTable.
