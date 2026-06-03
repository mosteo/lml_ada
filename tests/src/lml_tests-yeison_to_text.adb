with LML;
with LML.Output;

with Lml_Tests.Support;

--  Build a non-trivial Yeison value (nested map, vector, and the three scalar
--  kinds common to all formats) and render it through LML.Output.To_Builder
--  for every supported output. For the formats LML can also read (JSON, TOML,
--  YAML) we re-parse the rendering and require it to equal the original value:
--  a true round-trip.

procedure Lml_Tests.Yeison_To_Text is

   use Lml_Tests.Support;

   Nested : Yeison.Any := Y_Map;
   List   : Yeison.Any := Y_Vec;
   Sample : Yeison.Any := Y_Map;

begin
   Put (Nested, "inner", Y_Str ("deep"));
   List.Append (Y_Str ("a"));
   List.Append (Y_Str ("b"));

   Put (Sample, "name",   Y_Str ("val"));
   Put (Sample, "count",  Y_Int (7));
   Put (Sample, "active", Y_Bool (True));
   Put (Sample, "nested", Nested);
   Put (Sample, "list",   List);

   for Format in LML.Supported_Outputs loop
      declare
         Rendered : constant Text :=
                      LML.Output.To_Builder (Sample, Format).To_Text;
      begin
         Check_Output (Rendered, Format, Sample, "yeison round-trip");
      end;
   end loop;
end Lml_Tests.Yeison_To_Text;
