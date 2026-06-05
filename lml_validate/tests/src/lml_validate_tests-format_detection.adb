with LML;

with Lml_Validate_App;

--  Format_Of maps file extensions (case-insensitively) to LML formats and
--  rejects anything it does not recognise.

procedure Lml_Validate_Tests.Format_Detection is

   use type LML.Formats;
   use Lml_Validate_App;

   Raised : Boolean := False;

begin
   pragma Assert (Format_Of ("a.json")     = LML.JSON);
   pragma Assert (Format_Of ("a.JSON")     = LML.JSON);   --  case-insensitive
   pragma Assert (Format_Of ("dir/b.yaml") = LML.YAML);
   pragma Assert (Format_Of ("b.yml")      = LML.YAML);
   pragma Assert (Format_Of ("c.toml")     = LML.TOML);
   pragma Assert (Format_Of ("d.ads")      = LML.Pragmas);
   pragma Assert (Format_Of ("e.adb")      = LML.Pragmas);

   --  An unknown or missing extension must raise Bad_Extension.
   begin
      declare
         Dummy : constant LML.Formats := Format_Of ("noextension");
      begin
         pragma Unreferenced (Dummy);
      end;
   exception
      when Lml_Validate_App.Bad_Extension =>
         Raised := True;
   end;
   pragma Assert (Raised, "extension-less name must raise Bad_Extension");
end Lml_Validate_Tests.Format_Detection;
