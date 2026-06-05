with Lml_Tests.Support;

--  Applicators allOf/anyOf/oneOf/not and the boolean schemas true/false.
--  Negative cases assert the combinator-specific diagnostic.

procedure Lml_Tests.Schema_Combinators is

   use Lml_Tests.Support;

   function TS (Name : Text) return Yeison.Any is
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "type", Y_Str (Name));
      return S;
   end TS;

begin
   --  anyOf [string, number]
   declare
      S    : Yeison.Any := Y_Map;
      Subs : Yeison.Any := Y_Vec;
   begin
      Subs.Append (TS ("string"));
      Subs.Append (TS ("number"));
      Put (S, "anyOf", Subs);
      Assert_Valid (Y_Str ("a"), S, "anyOf string");
      Assert_Valid (Y_Int (1), S, "anyOf number");
      Assert_Invalid (Y_Bool (True), S,
                      "value matches no anyOf subschema", "anyOf rejects");
   end;

   --  oneOf [string, boolean]: exactly one must match
   declare
      S    : Yeison.Any := Y_Map;
      Subs : Yeison.Any := Y_Vec;
   begin
      Subs.Append (TS ("string"));
      Subs.Append (TS ("boolean"));
      Put (S, "oneOf", Subs);
      Assert_Valid (Y_Str ("x"), S, "oneOf one match");
      Assert_Invalid (Y_Int (1), S,
                      "value must match exactly one oneOf subschema",
                      "oneOf zero matches");
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
      Assert_Valid (Y_Int (4), S, "allOf passes");
      Assert_Invalid (Y_Int (3), S,
                      "value is not a multiple of multipleOf",
                      "allOf fails multipleOf");
   end;

   --  not (string)
   declare
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "not", TS ("string"));
      Assert_Valid (Y_Int (1), S, "not-string accepts int");
      Assert_Invalid (Y_Str ("x"), S,
                      "value must not match the 'not' subschema",
                      "not-string rejects string");
   end;

   --  boolean schemas
   Assert_Valid (Y_Int (1), Y_Bool (True), "true schema accepts everything");
   Assert_Invalid (Y_Int (1), Y_Bool (False),
                   "false schema rejects every value",
                   "false schema rejects everything");
end Lml_Tests.Schema_Combinators;
