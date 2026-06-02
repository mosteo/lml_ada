with LML.Output;

with Yeison_12;

--  Build a Yeison value and render it through the per-format builders via
--  LML.Output.To_Builder. Asserts non-empty output for every supported format.

procedure Lml_Tests.Yeison_To_Text is

   package Yeison renames Yeison_12;
   use Yeison.Operators;

   Sample : constant Yeison.Any :=
              Yeison.Empty_Map.Insert (+"key", +"val");

begin
   for Format in LML.Supported_Outputs loop
      declare
         Builder : constant LML.Output.Builder'Class :=
                     LML.Output.To_Builder (Sample, Format);
      begin
         Assert (Builder.To_Text'Length > 0,
                 "empty output for " & Format'Image);
         Assert (Contains (Builder.To_Text, "key"),
                 "missing key in " & Format'Image);
         Assert (Contains (Builder.To_Text, "val"),
                 "missing value in " & Format'Image);
      end;
   end loop;
end Lml_Tests.Yeison_To_Text;
