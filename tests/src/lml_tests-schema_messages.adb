with LML.Schemas;

with Lml_Tests.Support;

--  The failure message must locate the violation: instance path plus a
--  reason mentioning the expected type.

procedure Lml_Tests.Schema_Messages is

   use Lml_Tests.Support;

   Schema : Yeison.Any := Y_Map;
   Props  : Yeison.Any := Y_Map;
   Age    : Yeison.Any := Y_Map;
   D      : Yeison.Any := Y_Map;

begin
   Put (Age, "type", Y_Str ("number"));
   Put (Props, "age", Age);
   Put (Schema, "type", Y_Str ("object"));
   Put (Schema, "properties", Props);

   Put (D, "age", Y_Str ("old"));

   declare
      R : constant LML.Schemas.Result := LML.Schemas.Validate (D, Schema);
   begin
      Assert (not LML.Schemas.Is_Valid (R), "expected invalid result");
      Assert (Contains (LML.Schemas.Error (R), "/age"),
              "message carries instance path; got: "
              & Str (LML.Schemas.Error (R)));
      Assert (Contains (LML.Schemas.Error (R), "number"),
              "message names the expected type; got: "
              & Str (LML.Schemas.Error (R)));
   end;
end Lml_Tests.Schema_Messages;
