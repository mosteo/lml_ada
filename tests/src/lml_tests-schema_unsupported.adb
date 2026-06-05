with LML;
with LML.Schemas;

with Lml_Tests.Support;

--  Unsupported keywords that could mask an invalid document ($ref) must
--  raise LML.Unsupported_Error rather than silently pass.

procedure Lml_Tests.Schema_Unsupported is

   use Lml_Tests.Support;

   Schema : Yeison.Any := Y_Map;
   Raised : Boolean := False;

begin
   Put (Schema, "$ref", Y_Str ("#/$defs/Foo"));

   begin
      declare
         Result : constant Boolean :=
           LML.Schemas.Validate (Y_Int (1), Schema).Is_Valid;
      begin
         pragma Unreferenced (Result);
      end;
   exception
      when LML.Unsupported_Error =>
         Raised := True;
   end;

   Assert (Raised, "$ref must raise LML.Unsupported_Error");
end Lml_Tests.Schema_Unsupported;
