with LML.Schemas;

with Lml_Tests.Support;

--  The `type` keyword, one assertion per JSON-Schema type name, plus the
--  number/integer distinction (an integral-valued real counts as integer)
--  and the array-of-names union form.

procedure Lml_Tests.Schema_Types is

   use Lml_Tests.Support;

   function Type_Schema (Name : Text) return Yeison.Any is
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "type", Y_Str (Name));
      return S;
   end Type_Schema;

   function OK (Data : Yeison.Any; Name : Text) return Boolean is
     (LML.Schemas.Is_Valid (Data, Type_Schema (Name)));

begin
   Assert (OK (Y_Str ("hi"), "string"), "string accepts string");
   Assert (not OK (Y_Int (1), "string"), "string rejects int");

   Assert (OK (Y_Bool (True), "boolean"), "boolean accepts bool");
   Assert (not OK (Y_Str ("x"), "boolean"), "boolean rejects string");

   Assert (OK (Y_Nil, "null"), "null accepts nil");
   Assert (not OK (Y_Int (0), "null"), "null rejects int");

   Assert (OK (Y_Map, "object"), "object accepts map");
   Assert (not OK (Y_Vec, "object"), "object rejects vec");
   Assert (OK (Y_Vec, "array"), "array accepts vec");
   Assert (not OK (Y_Map, "array"), "array rejects map");

   Assert (OK (Y_Int (3), "integer"), "integer accepts int");
   Assert (OK (Y_Int (3), "number"), "number accepts int");
   Assert (OK (Y_Real (3.5), "number"), "number accepts real");
   Assert (not OK (Y_Real (3.5), "integer"), "integer rejects 3.5");
   Assert (OK (Y_Real (4.0), "integer"), "integer accepts integral real");

   --  type as an array of names (union)
   declare
      S     : Yeison.Any := Y_Map;
      Names : Yeison.Any := Y_Vec;
   begin
      Names.Append (Y_Str ("string"));
      Names.Append (Y_Str ("null"));
      Put (S, "type", Names);
      Assert (LML.Schemas.Is_Valid (Y_Str ("a"), S),
              "type union accepts string");
      Assert (LML.Schemas.Is_Valid (Y_Nil, S),
              "type union accepts null");
      Assert (not LML.Schemas.Is_Valid (Y_Int (1), S),
              "type union rejects int");
   end;
end Lml_Tests.Schema_Types;
