with LML.Schemas;

with Lml_Tests.Support;

--  Object keywords: properties recursion, required, additionalProperties
--  (the boolean false form) and min/maxProperties.

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
      Assert (LML.Schemas.Is_Valid (D, Schema), "valid object");
   end;

   declare
      D : Yeison.Any := Y_Map;
   begin
      Put (D, "age", Y_Int (36));
      Assert (not LML.Schemas.Is_Valid (D, Schema), "missing required name");
   end;

   declare
      D : Yeison.Any := Y_Map;
   begin
      Put (D, "name", Y_Int (1));
      Assert (not LML.Schemas.Is_Valid (D, Schema), "name has wrong type");
   end;

   declare
      D : Yeison.Any := Y_Map;
   begin
      Put (D, "name", Y_Str ("Ada"));
      Put (D, "extra", Y_Bool (True));
      Assert (not LML.Schemas.Is_Valid (D, Schema),
              "extra property rejected");
   end;

   --  min/maxProperties
   declare
      S2 : Yeison.Any := Y_Map;
      D  : Yeison.Any := Y_Map;
   begin
      Put (S2, "minProperties", Y_Int (2));
      Put (D, "a", Y_Int (1));
      Assert (not LML.Schemas.Is_Valid (D, S2), "below minProperties");
      Put (D, "b", Y_Int (2));
      Assert (LML.Schemas.Is_Valid (D, S2), "meets minProperties");
   end;
end Lml_Tests.Schema_Object;
