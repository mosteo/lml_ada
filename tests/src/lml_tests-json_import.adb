with LML;

with Lml_Tests.Support;

--  Parse a JSON document into a Yeison value and check it equals an
--  independently-built structure: types (int vs string), nesting and the
--  vector contents must all match, not merely "the keys appear somewhere".

procedure Lml_Tests.Json_Import is

   use Lml_Tests.Support;
   use all type Yeison.Kinds;

   JSON_Text : constant Text :=
     "{ ""vec"": [1, 2, 3], ""key"": ""val"", ""map"": {""k"":""v""}}";

   Value : constant Yeison.Any := LML.From_Text (JSON_Text, LML.JSON);

   Expected : Yeison.Any := Y_Map;
   Vec      : Yeison.Any := Y_Vec;
   Inner    : Yeison.Any := Y_Map;

begin
   Vec.Append (Y_Int (1));
   Vec.Append (Y_Int (2));
   Vec.Append (Y_Int (3));
   Put (Inner, "k", Y_Str ("v"));
   Put (Expected, "vec", Vec);
   Put (Expected, "key", Y_Str ("val"));
   Put (Expected, "map", Inner);

   Assert (Value.Kind = Map_Kind, "expected a map, got " & Value.Kind'Image);
   Assert_Equal (Value, Expected, "json import structure");

   --  Spot-check the inferred kinds: numbers must not become strings.
   Assert (At_Index (At_Key (Value, "vec"), 1).Kind = Int_Kind,
           "first vec element should be an integer");
   Assert (At_Key (Value, "key").Kind = Str_Kind,
           "key should map to a string");

   --  Regression: JSON null must parse to Yeison nil, both as a map value and
   --  inside an array. (LML emits JSON null on output, so reading must be
   --  symmetric; previously any null raised Program_Error.)
   declare
      Null_Doc : constant Yeison.Any :=
        LML.From_Text ("{ ""a"": null, ""b"": [1, null, 3] }", LML.JSON);
      Expected : Yeison.Any := Y_Map;
      Arr      : Yeison.Any := Y_Vec;
   begin
      Arr.Append (Y_Int (1));
      Arr.Append (Y_Nil);
      Arr.Append (Y_Int (3));
      Put (Expected, "a", Y_Nil);
      Put (Expected, "b", Arr);

      Assert (At_Key (Null_Doc, "a").Kind = Nil_Kind,
              "null map value should parse to nil");
      Assert (At_Index (At_Key (Null_Doc, "b"), 2).Kind = Nil_Kind,
              "null array element should parse to nil");
      Assert_Equal (Null_Doc, Expected, "json null parsing");
   end;
end Lml_Tests.Json_Import;
