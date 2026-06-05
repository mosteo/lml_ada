with Lml_Tests.Support;

--  String length and numeric keywords: minimum/maximum, exclusive bounds
--  and multipleOf (integer and real). Negative cases assert the reason.

procedure Lml_Tests.Schema_String_Number is

   use Lml_Tests.Support;

begin
   --  string length
   declare
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "minLength", Y_Int (2));
      Put (S, "maxLength", Y_Int (4));
      Assert_Valid (Y_Str ("abc"), S, "length in range");
      Assert_Invalid (Y_Str ("a"), S,
                      "string is shorter than minLength", "too short");
      Assert_Invalid (Y_Str ("abcde"), S,
                      "string is longer than maxLength", "too long");
   end;

   --  numeric bounds incl. exclusiveMaximum
   declare
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "minimum", Y_Int (0));
      Put (S, "maximum", Y_Int (10));
      Put (S, "exclusiveMaximum", Y_Int (10));
      Assert_Valid (Y_Int (5), S, "in range");
      Assert_Invalid (Y_Int (-1), S, "value is below minimum", "below min");
      Assert_Invalid (Y_Int (10), S,
                      "value is not below exclusiveMaximum",
                      "not below exclusiveMaximum");
   end;

   --  multipleOf, integer
   declare
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "multipleOf", Y_Int (3));
      Assert_Valid (Y_Int (9), S, "9 is a multiple of 3");
      Assert_Invalid (Y_Int (10), S,
                      "value is not a multiple of multipleOf",
                      "10 is not a multiple of 3");
   end;

   --  multipleOf, real
   declare
      S : Yeison.Any := Y_Map;
   begin
      Put (S, "multipleOf", Y_Real (0.5));
      Assert_Valid (Y_Real (1.5), S, "1.5 is a multiple of 0.5");
      Assert_Invalid (Y_Real (1.6), S,
                      "value is not a multiple of multipleOf",
                      "1.6 is not a multiple of 0.5");
   end;
end Lml_Tests.Schema_String_Number;
