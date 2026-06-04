with LML;
with LML.Input.YAML.Initialization;

with Lml_Tests.Support;

--  Parse YAML into Yeison and verify, exactly, that every major piece of YAML
--  syntax is read as intended:
--    * scalar typing under the core schema (int/real/bool/null vs string);
--    * all string styles: plain, plain multi-line, single- and double-quoted
--      (escapes and line continuation), literal "|" and folded ">" block
--      scalars with clip/strip chomping;
--    * sequences and mappings in both block and flow styles, nested and mixed;
--    * comments, empty values and empty flow collections;
--    * anchors/aliases remain unsupported.
--  AdaYaml is not preelaborable, so the parser is reached through a hook the
--  client must arm first via Initialize.

procedure Lml_Tests.Yaml_Import is

   use Lml_Tests.Support;
   use all type Yeison.Kinds;

   LF : constant Wide_Wide_Character := Wide_Wide_Character'Val (10);
   HT : constant Wide_Wide_Character := Wide_Wide_Character'Val (9);

   function Parse (Image : Text) return Yeison.Any
   is (LML.From_Text (Image, LML.YAML));
   --  Shorthand for parsing a YAML image into a Yeison value.

   procedure Same (Image : Text; Expected : Yeison.Any; Title : String) is
   begin
      Assert_Equal (Parse (Image), Expected, Title);
   end Same;

   procedure Str_Is (V : Yeison.Any; Key, Expected : Text; Title : String) is
   begin
      Assert_Equal (At_Key (V, Key), Y_Str (Expected), Title);
   end Str_Is;

begin
   LML.Input.YAML.Initialization.Initialize;

   --------------------------------------------------------------------------
   --  Core-schema scalar typing and nesting.                              --
   --------------------------------------------------------------------------
   --  "quoted" is double-quoted so it stays a string; "num_str" is quoted
   --  digits and must NOT become an integer.
   declare
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

      Value    : constant Yeison.Any := Parse (YAML_Text);
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

   --------------------------------------------------------------------------
   --  String styles: every way YAML can spell a string, read exactly.     --
   --------------------------------------------------------------------------
   declare
      Doc : constant Text :=
        "plain: hello world"  & LF &   --  plain (unquoted)
        "pmulti: one"         & LF &   --  plain multi-line: break -> space
        "  two"               & LF &
        "squote: 'it''s ok'"  & LF &   --  single-quoted: '' is one quote
        "dquote: ""a\tb\nc"""  & LF &  --  double-quoted: \t and \n escapes
        "dcont: ""foo \"       & LF &  --  double-quoted line continuation
        "  bar"""             & LF &
        "literal: |"          & LF &   --  literal block, clip: 1 trailing LF
        "  L1"                & LF &
        "  L2"                & LF &
        "lstrip: |-"          & LF &   --  literal block, strip: no trailing LF
        "  L1"                & LF &
        "  L2"                & LF &
        "folded: >"           & LF &   --  folded block, clip: breaks -> space
        "  w1"                & LF &
        "  w2"                & LF &
        "fstrip: >-"          & LF &   --  folded block, strip
        "  w1"                & LF &
        "  w2";

      V : constant Yeison.Any := Parse (Doc);
   begin
      Str_Is (V, "plain", "hello world", "plain scalar");
      Str_Is (V, "pmulti", "one two", "plain multi-line fold");
      Str_Is (V, "squote", "it's ok", "single-quoted '' quote");
      Str_Is (V, "dquote", "a" & HT & "b" & LF & "c", "double-quoted escapes");
      Str_Is (V, "dcont", "foo bar", "double-quoted continuation");
      Str_Is (V, "literal", "L1" & LF & "L2" & LF, "literal block (clip)");
      Str_Is (V, "lstrip", "L1" & LF & "L2", "literal block (strip)");
      Str_Is (V, "folded", "w1 w2" & LF, "folded block (clip)");
      Str_Is (V, "fstrip", "w1 w2", "folded block (strip)");

      --  Non-plain styles must always stay strings, never resolved.
      Assert (At_Key (V, "literal").Kind = Str_Kind,
              "literal block must be a string");
      Assert (At_Key (V, "dquote").Kind = Str_Kind,
              "double-quoted must be a string");
   end;

   --------------------------------------------------------------------------
   --  Sequences: block and flow forms must yield identical vectors.       --
   --------------------------------------------------------------------------
   declare
      E_ABC : Yeison.Any := Y_Vec;
   begin
      E_ABC.Append (Y_Str ("a"));
      E_ABC.Append (Y_Str ("b"));
      E_ABC.Append (Y_Str ("c"));
      Same ("- a" & LF & "- b" & LF & "- c", E_ABC, "block sequence");
      Same ("[a, b, c]", E_ABC, "flow sequence");
   end;

   declare
      E  : Yeison.Any := Y_Vec;
      I1 : Yeison.Any := Y_Vec;
      I2 : Yeison.Any := Y_Vec;
   begin
      I1.Append (Y_Int (1));
      I1.Append (Y_Int (2));
      I2.Append (Y_Int (3));
      E.Append (I1);
      E.Append (I2);
      Same ("[[1, 2], [3]]", E, "nested flow sequences");
      Same ("- - 1" & LF & "  - 2" & LF & "- - 3",
            E, "nested block sequences");
   end;

   declare
      E  : Yeison.Any := Y_Vec;
      M1 : Yeison.Any := Y_Map;
      M2 : Yeison.Any := Y_Map;
   begin
      Put (M1, "k", Y_Str ("v"));
      Put (M2, "x", Y_Str ("y"));
      E.Append (M1);
      E.Append (M2);
      Same ("[{k: v}, {x: y}]", E, "flow sequence of flow maps");
      Same ("- k: v" & LF & "- x: y", E, "block sequence of block maps");
   end;

   --------------------------------------------------------------------------
   --  Mappings: block and flow forms, nested and mixed with sequences.    --
   --------------------------------------------------------------------------
   declare
      E : Yeison.Any := Y_Map;
   begin
      Put (E, "a", Y_Int (1));
      Put (E, "b", Y_Int (2));
      Same ("a: 1" & LF & "b: 2", E, "block mapping");
      Same ("{a: 1, b: 2}", E, "flow mapping");
   end;

   declare
      E     : Yeison.Any := Y_Map;
      Inner : Yeison.Any := Y_Map;
      L     : Yeison.Any := Y_Vec;
   begin
      Put (Inner, "inner", Y_Str ("v"));
      L.Append (Y_Int (1));
      L.Append (Y_Int (2));
      Put (E, "outer", Inner);
      Put (E, "list", L);
      Same ("{outer: {inner: v}, list: [1, 2]}", E,
            "nested flow mapping and sequence");
      Same ("outer:"        & LF &
            "  inner: v"    & LF &
            "list:"         & LF &
            "  - 1"         & LF &
            "  - 2",
            E, "equivalent block mapping and sequence");
   end;

   --  Quoted keys carry spaces verbatim.
   declare
      E : Yeison.Any := Y_Map;
   begin
      Put (E, "a key", Y_Str ("value"));
      Same ("""a key"": value", E, "quoted key with spaces");
   end;

   --------------------------------------------------------------------------
   --  Comments are ignored, both trailing and whole-line.                 --
   --------------------------------------------------------------------------
   declare
      E : Yeison.Any := Y_Map;
   begin
      Put (E, "a", Y_Int (1));
      Put (E, "b", Y_Int (2));
      Same ("a: 1  # trailing comment" & LF &
            "# whole-line comment"     & LF &
            "b: 2", E, "comments are ignored");
   end;

   --------------------------------------------------------------------------
   --  Empty values, every null spelling, and empty flow collections.      --
   --------------------------------------------------------------------------
   declare
      V : constant Yeison.Any :=
        Parse ("a:"      & LF &   --  empty value -> null
               "b: ~"    & LF &
               "c: null" & LF &
               "d: Null" & LF &
               "e: NULL" & LF &
               "vec: []" & LF &   --  empty flow sequence
               "map: {}");        --  empty flow mapping
      E : Yeison.Any := Y_Map;
   begin
      Put (E, "a", Y_Nil);
      Put (E, "b", Y_Nil);
      Put (E, "c", Y_Nil);
      Put (E, "d", Y_Nil);
      Put (E, "e", Y_Nil);
      Put (E, "vec", Y_Vec);
      Put (E, "map", Y_Map);
      Assert_Equal (V, E, "empty values, null forms, empty flow collections");
      Assert (At_Key (V, "a").Kind = Nil_Kind, "empty value is nil");
      Assert (At_Key (V, "vec").Kind = Vec_Kind, "[] is an empty vector");
      Assert (At_Key (V, "map").Kind = Map_Kind, "{} is an empty map");
   end;

   --  null must also resolve to nil inside a sequence (flow), mirroring the
   --  JSON null regression.
   declare
      Null_Doc : constant Yeison.Any := Parse ("[1, null, 3]");
   begin
      Assert (Null_Doc.Kind = Vec_Kind,
              "expected a vector, got " & Null_Doc.Kind'Image);
      Assert (At_Index (Null_Doc, 1).Kind = Int_Kind,
              "first flow element should be an integer");
      Assert (At_Index (Null_Doc, 2).Kind = Nil_Kind,
              "null sequence element should parse to nil");
   end;

   --------------------------------------------------------------------------
   --  Anchors/aliases are explicitly unsupported in this version.         --
   --------------------------------------------------------------------------
   declare
      Ignore : Yeison.Any;
   begin
      Ignore := Parse ("a: &x 1" & LF & "b: *x");
      Assert (False, "aliased document should have raised Unsupported_Error");
   exception
      when LML.Unsupported_Error =>
         null;
   end;
end Lml_Tests.Yaml_Import;
