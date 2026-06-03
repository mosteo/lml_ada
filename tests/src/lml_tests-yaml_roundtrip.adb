with LML;
with LML.Output;
with LML.Output.Factory;
with LML.Output.YAML;

with Lml_Tests.Support;

--  YAML carries two emission styles (Compact, Expanded) that differ mostly
--  in how nested arrays are laid out. The generic output-shape tests only
--  exercise the default (Compact) style, so this test round-trips the riskiest
--  shapes -- an array of arrays of maps, plus nil as a map value and as a
--  vector element -- through *both* styles, requiring each rendering to parse
--  back equal to the original. This is where an emitter/parser indentation
--  mismatch would show up.

procedure Lml_Tests.Yaml_Roundtrip is

   use Lml_Tests.Support;

   Sample : Yeison.Any := Y_Map;
   Deep   : Yeison.Any := Y_Vec;
   Outer  : Yeison.Any := Y_Vec;
   Row    : Yeison.Any := Y_Map;
   Vec    : Yeison.Any := Y_Vec;

begin
   --  Sample = { deep => [ [ {k1=>a, k2=>b} ] ],
   --             n    => nil,
   --             v    => [ x, nil, y ] }
   Put (Row, "k1", Y_Str ("a"));
   Put (Row, "k2", Y_Str ("b"));
   Outer.Append (Row);
   Deep.Append (Outer);
   Put (Sample, "deep", Deep);

   Put (Sample, "n", Y_Nil);

   Vec.Append (Y_Str ("x"));
   Vec.Append (Y_Nil);
   Vec.Append (Y_Str ("y"));
   Put (Sample, "v", Vec);

   for Style in LML.Output.YAML.Styles loop
      declare
         B : LML.Output.Builder'Class := LML.Output.Factory.Get (LML.YAML);
      begin
         LML.Output.YAML.Builder (B).Set_Style (Style);
         LML.Output.Build (Sample, B);
         Check_Output (B.To_Text, LML.YAML, Sample,
                       "yaml roundtrip " & Style'Image);
      end;
   end loop;
end Lml_Tests.Yaml_Roundtrip;
