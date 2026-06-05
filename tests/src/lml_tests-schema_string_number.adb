with LML.Schemas;

with Lml_Tests.Support;

--  String length and numeric keywords: minimum/maximum, exclusive bounds
--  and multipleOf (integer and real).

procedure Lml_Tests.Schema_String_Number is

   use Lml_Tests.Support;

begin
   --  string length
   declare
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "minLength", Y_Int (2));
      Put (S, "maxLength", Y_Int (4));
      Assert (LML.Schemas.Is_Valid (Y_Str ("abc"), S), "length in range");
      Assert (not LML.Schemas.Is_Valid (Y_Str ("a"), S), "too short");
      Assert (not LML.Schemas.Is_Valid (Y_Str ("abcde"), S), "too long");
   end;

   --  numeric bounds incl. exclusiveMaximum
   declare
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "minimum", Y_Int (0));
      Put (S, "maximum", Y_Int (10));
      Put (S, "exclusiveMaximum", Y_Int (10));
      Assert (LML.Schemas.Is_Valid (Y_Int (5), S), "in range");
      Assert (not LML.Schemas.Is_Valid (Y_Int (-1), S), "below minimum");
      Assert (not LML.Schemas.Is_Valid (Y_Int (10), S),
              "not below exclusiveMaximum");
   end;

   --  multipleOf, integer
   declare
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "multipleOf", Y_Int (3));
      Assert (LML.Schemas.Is_Valid (Y_Int (9), S), "9 is a multiple of 3");
      Assert (not LML.Schemas.Is_Valid (Y_Int (10), S),
              "10 is not a multiple of 3");
   end;

   --  multipleOf, real
   declare
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "multipleOf", Y_Real (0.5));
      Assert (LML.Schemas.Is_Valid (Y_Real (1.5), S),
              "1.5 is a multiple of 0.5");
      Assert (not LML.Schemas.Is_Valid (Y_Real (1.6), S),
              "1.6 is not a multiple of 0.5");
   end;
end Lml_Tests.Schema_String_Number;
