with LML.Schemas;

with Lml_Tests.Support;

--  Applicators allOf/anyOf/oneOf/not and the boolean schemas true/false.

procedure Lml_Tests.Schema_Combinators is

   use Lml_Tests.Support;

   function Type_Schema (Name : Text) return Yeison.Any is
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "type", Y_Str (Name));
      return S;
   end Type_Schema;

begin
   --  anyOf [string, number]
   declare
      S    : Yeison.Any := Y_Map;
      Subs : Yeison.Any := Y_Vec;
   begin
      Subs.Append (Type_Schema ("string"));
      Subs.Append (Type_Schema ("number"));
      Put (S, "anyOf", Subs);
      Assert (LML.Schemas.Is_Valid (Y_Str ("a"), S), "anyOf string");
      Assert (LML.Schemas.Is_Valid (Y_Int (1), S), "anyOf number");
      Assert (not LML.Schemas.Is_Valid (Y_Bool (True), S), "anyOf rejects");
   end;

   --  oneOf [string, boolean]: exactly one must match
   declare
      S    : Yeison.Any := Y_Map;
      Subs : Yeison.Any := Y_Vec;
   begin
      Subs.Append (Type_Schema ("string"));
      Subs.Append (Type_Schema ("boolean"));
      Put (S, "oneOf", Subs);
      Assert (LML.Schemas.Is_Valid (Y_Str ("x"), S), "oneOf one match");
      Assert (not LML.Schemas.Is_Valid (Y_Int (1), S), "oneOf zero matches");
   end;

   --  allOf [number, multipleOf 2]
   declare
      S    : Yeison.Any := Y_Map;
      Subs : Yeison.Any := Y_Vec;
      A    : Yeison.Any := Y_Map;
      B    : Yeison.Any := Y_Map;
   begin
      Put (A, "type", Y_Str ("number"));
      Put (B, "multipleOf", Y_Int (2));
      Subs.Append (A);
      Subs.Append (B);
      Put (S, "allOf", Subs);
      Assert (LML.Schemas.Is_Valid (Y_Int (4), S), "allOf passes");
      Assert (not LML.Schemas.Is_Valid (Y_Int (3), S),
              "allOf fails multipleOf");
   end;

   --  not (string)
   declare
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "not", Type_Schema ("string"));
      Assert (LML.Schemas.Is_Valid (Y_Int (1), S), "not-string accepts int");
      Assert (not LML.Schemas.Is_Valid (Y_Str ("x"), S),
              "not-string rejects string");
   end;

   --  boolean schemas
   Assert (LML.Schemas.Is_Valid (Y_Int (1), Y_Bool (True)),
           "true schema accepts everything");
   Assert (not LML.Schemas.Is_Valid (Y_Int (1), Y_Bool (False)),
           "false schema rejects everything");
end Lml_Tests.Schema_Combinators;
