MODULE SymTable;
IMPORT Out, S := Scanner, E := ErrorMsg, Strings, Kernel, Lang;

CONST
  (** Object Classes **)
  Head*  = 0;
  Const* = 1; (** Non-standard procedures also go here *)
  Var*   = 2; (** Variables and value parameters *)
  Par*   = 3; (** Var-parameters *)
  Typ*   = 5;
  Mod*   = 8;

  (** Type Forms **)
  Bool*  = 2;
  Char*  = 3;
  Int*   = 4;
  SFunc* = 7;
  NoTyp* = 9;
  Proc*  = 10;

TYPE
  Object* = POINTER TO ObjectDesc;
  Type* = POINTER TO TypeDesc;

  ObjectDesc* = RECORD
    name*: ARRAY 64 OF CHAR;
    class*: INTEGER; (** See Object Classes *)
    dsc*: Object;
    next*: Object;
    type*: Type;
    val*: INTEGER (** Address for variables, number for procedures *)
  END;

  TypeDesc* = RECORD
    form*: INTEGER;
    nofpars*: INTEGER;
    dsc*: Object;
    base*: Type;
    size*: INTEGER (** In bytes *)
  END;

VAR
  topScope: Object;
  dummy*: Object;

  (** Standard Types **)
  boolType*, charType*, intType*, noType*: Type;

PROCEDURE InitUniverse;
VAR U: Object;
BEGIN
  U := topScope;
  NEW(U.next);
  U := U.next;
  Lang.FindUniObj('BOOLEAN', U.name);
  U.class := Typ;
  U.type := boolType;

  NEW(U.next);
  U := U.next;
  Lang.FindUniObj('CHAR', U.name);
  U.class := Typ;
  U.type := charType;

  NEW(U.next);
  U := U.next;
  Lang.FindUniObj('INTEGER', U.name);
  U.class := Typ;
  U.type := intType;

  NEW(U.next);
  U := U.next;
  Lang.FindUniObj('ORD', U.name);
  U.class := SFunc;
  U.val := 31;
  U.type := intType;

  NEW(U.next);
  U := U.next;
  Lang.FindUniObj('CHR', U.name);
  U.class := SFunc;
  U.val := 32;
  U.type := charType;

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

(** Returns TRUE if types t1 and t2 are assignment-compatible (t1 := t2) *)
PROCEDURE TypesCompatible*(t1, t2: Type): BOOLEAN;
RETURN t1.form = t2.form END TypesCompatible;

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

PROCEDURE ThisImport*(M: Object): Object;
VAR p: Object;
BEGIN
  p := M.dsc;
  WHILE (p # NIL) & (p.name # S.id) DO p := p.next END
RETURN p END ThisImport;

PROCEDURE NewObject*(class: INTEGER; name: ARRAY OF CHAR): Object;
VAR p: Object;
BEGIN
  Strings.Copy(name, dummy.name);
  p := topScope;
  WHILE p.next.name # name DO p := p.next END;
  IF p.next = dummy THEN
    NEW(p.next);
    p := p.next;
    p.next := dummy;
    p.class := class;
    Strings.Copy(name, p.name);
    dummy.name := ''
  ELSE S.Mark(E.multipleDecl); p := p.next
  END
RETURN p END NewObject;

(** num is Lang-internal number of module M *)
PROCEDURE ImportIn*(M: Object; num: INTEGER);
VAR p: Object;
BEGIN
  (* In.Char *)
  NEW(M.dsc); M := M.dsc;
  M.class := Const; Lang.FindModObj(num, 'Char', M.name); M.val := 1;
  NEW(M.type); M.type.form := Proc;
  M.type.nofpars := 1; M.type.base := noType;
  (* Parameter of In.Char *)
  NEW(M.type.dsc); p := M.type.dsc;
  p.class := Par; p.name := 'c'; p.type := charType;

  (* In.Int *)
  NEW(M.next); M := M.next;
  M.class := Const; Lang.FindModObj(num, 'Int', M.name); M.val := 2;
  NEW(M.type); M.type.form := Proc;
  M.type.nofpars := 1; M.type.base := noType;
  (* Parameter of In.Int *)
  NEW(M.type.dsc); p := M.type.dsc;
  p.class := Par; p.name := 'i'; p.type := intType
END ImportIn;

(** num is Lang-internal number of module M *)
PROCEDURE ImportOut*(M: Object; num: INTEGER);
VAR p: Object;
BEGIN
  (* Out.Char *)
  NEW(M.dsc); M := M.dsc;
  M.class := Const; Lang.FindModObj(num, 'Char', M.name); M.val := 5;
  NEW(M.type); M.type.form := Proc;
  M.type.nofpars := 1; M.type.base := noType;
  (* Parameter of Out.Char *)
  NEW(M.type.dsc); p := M.type.dsc;
  p.class := Var; p.name := 'c'; p.type := charType;

  (* Out.Int *)
  NEW(M.next); M := M.next;
  M.class := Const; Lang.FindModObj(num, 'Int', M.name); M.val := 6;
  NEW(M.type); M.type.form := Proc;
  M.type.nofpars := 2; M.type.base := noType;
  (* Parameters of Out.Int *)
  NEW(M.type.dsc); p := M.type.dsc;
  p.class := Var; p.name := 'i'; p.type := intType;
  NEW(p.next); p := p.next;
  p.class := Var; p.name := 'n'; p.type := intType;

  (* Out.Ln *)
  NEW(M.next); M := M.next;
  M.class := Const;Lang.FindModObj(num, 'Ln', M.name); M.val := 7;
  NEW(M.type); M.type.form := Proc;
  M.type.nofpars := 0; M.type.base := noType
END ImportOut;

(** Loads symbol data of module to M by M.name *)
PROCEDURE Import*(M: Object);
VAR s: ARRAY 32 OF CHAR;
  num: INTEGER;
BEGIN
  Lang.FindModule(M.name, s, num);
  IF s = 'In' THEN ImportIn(M, num)
  ELSIF s = 'Out' THEN ImportOut(M, num)
  ELSE S.Mark(E.noModule)
  END
END Import;

PROCEDURE PrintIndent(n: INTEGER);
BEGIN WHILE n > 0 DO Out.String('  '); DEC(n) END
END PrintIndent;

PROCEDURE Debug*(scope: Object; indent: INTEGER);
VAR p: Object;
BEGIN
  WHILE scope # NIL DO
    p := scope;
    WHILE p # NIL DO
      PrintIndent(indent);
      IF p = dummy THEN Out.String('Болванка')
      ELSIF p.class = Head THEN Out.String('Заголовок')
      ELSIF p.class = Var THEN
        Out.String('Переменная "'); Out.String(p.name);
        Out.String('" типа с формой '); Out.Int(p.type.form, 0);
        Out.String(' по адресу '); Out.Int(p.val, 0)
      ELSIF p.class = Typ THEN
        Out.String('Тип "'); Out.String(p.name);
        Out.String('", ссылается на тип с формой ');
        Out.Int(p.type.form, 0)
      ELSIF p.class = Const THEN
        Out.String('Постоянная "'); Out.String(p.name);
        Out.String('"');
        IF p.type.form = Proc THEN Out.String(' процедурного типа с ');
          Out.Int(p.type.nofpars, 0); Out.String(' параметрами'); Out.Ln;
          Debug(p.type.dsc, indent + 1)
        ELSE Out.String(' типа с формой'); Out.Int(p.type.form, 0)
        END
      ELSIF p.class = Mod THEN
        Out.String('Модуль "'); Out.String(p.name);
        Out.String('":'); Out.Ln; Debug(p.dsc, indent + 1)
      ELSE Out.String('Неведома зверушка')
      END;
      Out.Ln;
      p := p.next
    END;
    scope := scope.dsc;
    IF scope # NIL THEN
      PrintIndent(indent);
      Out.String('--- Следующая область видимости ---'); Out.Ln
    END
  END
END Debug;

PROCEDURE ShowDebug*;
BEGIN Debug(topScope, 0)
END ShowDebug;

PROCEDURE Init*;
BEGIN
  NEW(dummy); dummy.name := '';
  OpenScope;
  InitUniverse;
  OpenScope
END Init;

PROCEDURE CreateType(form, size: INTEGER): Type;
VAR T: Type;
BEGIN NEW(T); T.form := form; T.size := size
RETURN T END CreateType;

BEGIN
  boolType := CreateType(Bool , 1);
  charType := CreateType(Char , 2);
  intType  := CreateType(Int  , 4);
  noType   := CreateType(NoTyp, 0)
END SymTable.
