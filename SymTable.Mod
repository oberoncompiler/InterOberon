MODULE SymTable;
IMPORT Out, S := Scanner, E := ErrorMsg, Strings, Kernel;

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
  dummy*: Object;

PROCEDURE InitUniverse;
VAR U: Object;
BEGIN
  U := topScope;
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
  U.type.form := Int;

  U.next := dummy
END InitUniverse;

PROCEDURE OpenScope*;
VAR p: Object;
BEGIN
  p := topScope;
  NEW(topScope);
  topScope.dsc := p;
  topScope.class := Head;

  (* Remove dummy from previous top scope *)
  IF p # NIL THEN
    WHILE p.next # dummy DO p := p.next END;
    p.next := NIL
  END;

  topScope.next := dummy
END OpenScope;

PROCEDURE CloseScope*;
VAR p: Object;
BEGIN
  topScope := topScope.dsc;
  p := topScope;
  WHILE p.next # NIL DO p := p.next END;
  p.next := dummy
END CloseScope;

PROCEDURE ThisObject*(): Object;
VAR scope, p: Object;
BEGIN
  scope := topScope;
  REPEAT
    p := scope.next;
    WHILE (p.next # NIL) & (p.name # S.id) DO
      p := p.next
    END;
    scope := scope.dsc
  UNTIL (scope = NIL) OR (p.name = S.id);
  IF p.name # S.id THEN p := NIL END
RETURN p END ThisObject;

PROCEDURE NewObject*(class: INTEGER; name: ARRAY OF CHAR);
VAR p: Object;
BEGIN
  Strings.Copy(S.id, dummy.name);
  p := topScope.next;
  WHILE p.name # S.id DO p := p.next END;
  IF p = dummy THEN
    p.class := class;
    NEW(p.next);
    dummy := p.next;
    dummy.name := ''
  ELSE S.Mark(E.multipleDecl)
  END
END NewObject;

PROCEDURE ShowDebug*;
VAR scope, p: Object;
BEGIN
  scope := topScope;
  WHILE scope # NIL DO
    Out.String('--- Область видимости ---'); Out.Ln;
    p := scope;
    WHILE p # NIL DO
      IF p = dummy THEN Out.String('Болванка')
      ELSIF p.class = Head THEN Out.String('Заголовок')
      ELSIF p.class = Var THEN
        Out.String('Переменная "'); Out.String(p.name);
        Out.String('" типа с формой '); Out.Int(p.type.form, 0)
      ELSIF p.class = Typ THEN
        Out.String('Тип "'); Out.String(p.name);
        Out.String('", ссылается на тип с формой ');
        Out.Int(p.type.form, 0)
      ELSE Out.String('Неведома зверушка')
      END;
      Out.Ln;
      p := p.next
    END;
    scope := scope.dsc
  END
END ShowDebug;

PROCEDURE Init*;
BEGIN
  NEW(dummy); dummy.name := '';
  OpenScope;
  InitUniverse;
  OpenScope
END Init;

END SymTable.
