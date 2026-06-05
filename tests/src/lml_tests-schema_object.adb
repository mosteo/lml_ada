with Lml_Tests.Support;

--  Object keywords: properties recursion, required, additionalProperties
--  (the boolean false form) and min/maxProperties. Negative cases assert the
--  diagnostic, including the instance path of the offending property.

procedure Lml_Tests.Schema_Object is

   use Lml_Tests.Support;

   Schema : Yeison.Any := Y_Map;
   Props  : Yeison.Any := Y_Map;
   P_Name : Yeison.Any := Y_Map;
   P_Age  : Yeison.Any := Y_Map;
   Req    : Yeison.Any := Y_Vec;

begin
   Put (P_Name, "type", Y_Str ("string"));
   Put (P_Age,  "type", Y_Str ("number"));
   Put (Props, "name", P_Name);
   Put (Props, "age",  P_Age);
   Put (Schema, "type", Y_Str ("object"));
   Put (Schema, "properties", Props);
   Req.Append (Y_Str ("name"));
   Put (Schema, "required", Req);
   Put (Schema, "additionalProperties", Y_Bool (False));

   declare
      D : Yeison.Any := Y_Map;
   begin
      Put (D, "name", Y_Str ("Ada"));
      Put (D, "age", Y_Int (36));
      Assert_Valid (D, Schema, "valid object");
   end;

   declare
      D : Yeison.Any := Y_Map;
   begin
      Put (D, "age", Y_Int (36));
      Assert_Invalid (D, Schema,
                      "missing required property name", "missing required");
   end;

   --  Wrong-typed property: the path must point at /name.
   declare
      D : Yeison.Any := Y_Map;
   begin
      Put (D, "name", Y_Int (1));
      Assert_Invalid (D, Schema,
                      "/name: expected string, found integer",
                      "property wrong type, with path");
   end;

   --  Additional property: the path must point at /extra.
   declare
      D : Yeison.Any := Y_Map;
   begin
      Put (D, "name", Y_Str ("Ada"));
      Put (D, "extra", Y_Bool (True));
      Assert_Invalid (D, Schema,
                      "/extra: additional property not allowed",
                      "extra property rejected, with path");
   end;

   --  min/maxProperties
   declare
      S2 : Yeison.Any := Y_Map;
      D  : Yeison.Any := Y_Map;
   begin
      Put (S2, "minProperties", Y_Int (2));
      Put (D, "a", Y_Int (1));
      Assert_Invalid (D, S2,
                      "object has fewer than minProperties members",
                      "below minProperties");
      Put (D, "b", Y_Int (2));
      Assert_Valid (D, S2, "meets minProperties");
   end;
end Lml_Tests.Schema_Object;
