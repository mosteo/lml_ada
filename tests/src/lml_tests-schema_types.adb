with Lml_Tests.Support;

--  The `type` keyword, one assertion per JSON-Schema type name, plus the
--  number/integer distinction (an integral-valued real counts as integer)
--  and the array-of-names union form. Negative cases pin down the diagnostic,
--  not merely the verdict.

procedure Lml_Tests.Schema_Types is

   use Lml_Tests.Support;

   function TS (Name : Text) return Yeison.Any is
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "type", Y_Str (Name));
      return S;
   end TS;

begin
   Assert_Valid (Y_Str ("hi"), TS ("string"), "string accepts string");
   Assert_Invalid (Y_Int (1), TS ("string"),
                   "expected string, found integer", "string rejects int");

   Assert_Valid (Y_Bool (True), TS ("boolean"), "boolean accepts bool");
   Assert_Invalid (Y_Str ("x"), TS ("boolean"),
                   "expected boolean, found string", "boolean rejects str");

   Assert_Valid (Y_Nil, TS ("null"), "null accepts nil");
   Assert_Invalid (Y_Int (0), TS ("null"),
                   "expected null, found integer", "null rejects int");

   Assert_Valid (Y_Map, TS ("object"), "object accepts map");
   Assert_Invalid (Y_Vec, TS ("object"),
                   "expected object, found array", "object rejects vec");
   Assert_Valid (Y_Vec, TS ("array"), "array accepts vec");
   Assert_Invalid (Y_Map, TS ("array"),
                   "expected array, found object", "array rejects map");

   Assert_Valid (Y_Int (3), TS ("integer"), "integer accepts int");
   Assert_Valid (Y_Int (3), TS ("number"), "number accepts int");
   Assert_Valid (Y_Real (3.5), TS ("number"), "number accepts real");
   Assert_Invalid (Y_Real (3.5), TS ("integer"),
                   "expected integer, found number", "integer rejects 3.5");
   Assert_Valid (Y_Real (4.0), TS ("integer"), "integer accepts 4.0");

   --  type as an array of names (union)
   declare
      S     : Yeison.Any := Y_Map;
      Names : Yeison.Any := Y_Vec;
   begin
      Names.Append (Y_Str ("string"));
      Names.Append (Y_Str ("null"));
      Put (S, "type", Names);
      Assert_Valid (Y_Str ("a"), S, "type union accepts string");
      Assert_Valid (Y_Nil, S, "type union accepts null");
      Assert_Invalid (Y_Int (1), S,
                      "type integer is not in the allowed set",
                      "type union rejects int");
   end;
end Lml_Tests.Schema_Types;
