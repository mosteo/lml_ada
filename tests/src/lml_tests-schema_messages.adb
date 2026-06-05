with Lml_Tests.Support;

--  Message format specifics: a violation at the document root is located as
--  "(root)", and a nested violation carries the full JSON-pointer-style path.

procedure Lml_Tests.Schema_Messages is

   use Lml_Tests.Support;

begin
   --  Root-level violation.
   declare
      Schema : Yeison.Any := Y_Map;
   begin
      Put (Schema, "type", Y_Str ("object"));
      Assert_Invalid (Y_Int (1), Schema,
                      "(root): expected object, found integer",
                      "root location is (root)");
   end;

   --  Nested violation: /a/b must appear in the message.
   --  Schema = { properties: { a: { properties: { b: { type: number } } } } }
   declare
      Schema   : Yeison.Any := Y_Map;
      Top_Prop : Yeison.Any := Y_Map;  --  { a: <A_Schema> }
      A_Schema : Yeison.Any := Y_Map;  --  { properties: { b: ... } }
      A_Prop   : Yeison.Any := Y_Map;  --  { b: <B_Schema> }
      B_Schema : Yeison.Any := Y_Map;  --  { type: number }
      D        : Yeison.Any := Y_Map;
      Inner    : Yeison.Any := Y_Map;
   begin
      Put (B_Schema, "type", Y_Str ("number"));
      Put (A_Prop, "b", B_Schema);
      Put (A_Schema, "properties", A_Prop);
      Put (Top_Prop, "a", A_Schema);
      Put (Schema, "properties", Top_Prop);

      Put (Inner, "b", Y_Str ("oops"));
      Put (D, "a", Inner);
      Assert_Invalid (D, Schema,
                      "/a/b: expected number, found string",
                      "nested path is reported");
   end;
end Lml_Tests.Schema_Messages;
