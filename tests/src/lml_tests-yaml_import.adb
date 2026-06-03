with LML;
with LML.Input.YAML.Initialization;

with Lml_Tests.Support;

--  Parse a YAML document into a Yeison value and check it equals an
--  independently-built structure: scalar typing (core schema: int/real/bool/
--  null vs string), nesting and sequence contents must all match. AdaYaml is
--  not preelaborable, so the parser is reached through a hook that the client
--  must arm first via Initialize.

procedure Lml_Tests.Yaml_Import is

   use Lml_Tests.Support;
   use all type Yeison.Kinds;

   LF : constant Wide_Wide_Character := Wide_Wide_Character'Val (10);

   --  A document mixing a map, a nested sequence, and every core-schema scalar
   --  kind. "quoted" is double-quoted so it must stay a string; "num_str" is
   --  quoted digits and must NOT become an integer.
   YAML_Text : constant Text :=
     "map:"            & LF &
     "  k: v"          & LF &
     "vec:"            & LF &
     "  - 1"           & LF &
     "  - 2"           & LF &
     "  - 3"           & LF &
     "an_int: 42"      & LF &
     "a_real: 3.5"     & LF &
     "a_bool: true"    & LF &
     "a_null: null"    & LF &
     "a_tilde: ~"      & LF &
     "quoted: ""val""" & LF &
     "num_str: ""007""";

   Alias_Doc : constant Text := "a: &x 1" & LF & "b: *x";

begin
   LML.Input.YAML.Initialization.Initialize;

   declare
      Value : constant Yeison.Any := LML.From_Text (YAML_Text, LML.YAML);

      Expected : Yeison.Any := Y_Map;
      Inner    : Yeison.Any := Y_Map;
      Vec      : Yeison.Any := Y_Vec;
   begin
      Put (Inner, "k", Y_Str ("v"));
      Vec.Append (Y_Int (1));
      Vec.Append (Y_Int (2));
      Vec.Append (Y_Int (3));

      Put (Expected, "map", Inner);
      Put (Expected, "vec", Vec);
      Put (Expected, "an_int", Y_Int (42));
      Put (Expected, "a_real", Y_Real (3.5));
      Put (Expected, "a_bool", Y_Bool (True));
      Put (Expected, "a_null", Y_Nil);
      Put (Expected, "a_tilde", Y_Nil);
      Put (Expected, "quoted", Y_Str ("val"));
      Put (Expected, "num_str", Y_Str ("007"));

      Assert (Value.Kind = Map_Kind,
              "expected a map, got " & Value.Kind'Image);
      Assert_Equal (Value, Expected, "yaml import structure");

      --  Spot-check the inferred kinds: plain scalars must resolve to their
      --  core-schema type, quoted ones must stay strings.
      Assert (At_Index (At_Key (Value, "vec"), 1).Kind = Int_Kind,
              "first vec element should be an integer");
      Assert (At_Key (Value, "an_int").Kind = Int_Kind,
              "an_int should be an integer");
      Assert (At_Key (Value, "a_real").Kind = Real_Kind,
              "a_real should be a real");
      Assert (At_Key (Value, "a_bool").Kind = Bool_Kind,
              "a_bool should be a boolean");
      Assert (At_Key (Value, "a_null").Kind = Nil_Kind,
              "a_null should be nil");
      Assert (At_Key (Value, "a_tilde").Kind = Nil_Kind,
              "a_tilde (~) should be nil");
      Assert (At_Key (Value, "quoted").Kind = Str_Kind,
              "quoted scalar should stay a string");
      Assert (At_Key (Value, "num_str").Kind = Str_Kind,
              "quoted digits should stay a string, not an integer");
   end;

   --  null must also resolve to nil inside a sequence, mirroring the JSON null
   --  regression.
   declare
      Null_Doc : constant Yeison.Any :=
        LML.From_Text ("[1, null, 3]", LML.YAML);
   begin
      Assert (Null_Doc.Kind = Vec_Kind,
              "expected a vector, got " & Null_Doc.Kind'Image);
      Assert (At_Index (Null_Doc, 1).Kind = Int_Kind,
              "first flow element should be an integer");
      Assert (At_Index (Null_Doc, 2).Kind = Nil_Kind,
              "null sequence element should parse to nil");
   end;

   --  Anchors/aliases are explicitly unsupported in this version.
   declare
      Ignore : Yeison.Any;
   begin
      Ignore := LML.From_Text (Alias_Doc, LML.YAML);
      Assert (False, "aliased document should have raised Unsupported_Error");
   exception
      when LML.Unsupported_Error =>
         null;
   end;
end Lml_Tests.Yaml_Import;
