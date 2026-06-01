with LML;

with Yeison_12;

--  Parse a JSON document into a Yeison value and check the round-tripped
--  structure: it must be a map carrying the expected keys.

procedure Lml_Tests.Json_Import is

   package Yeison renames Yeison_12;
   use all type Yeison.Kinds;

   JSON_Text : constant Text :=
     "{ ""vec"": [1, 2, 3], ""key"": ""val"", ""map"": {""k"":""v""}}";

   Value : constant Yeison.Any := LML.From_Text (JSON_Text, LML.JSON);
   Image : constant Text := Value.Image;
begin
   Assert (Value.Kind = Map_Kind, "expected a map, got " & Value.Kind'Image);
   Assert (Image'Length > 0, "empty image");
   Assert (Contains (Image, "vec"), "missing vec in: " & Str (Image));
   Assert (Contains (Image, "key"), "missing key in: " & Str (Image));
   Assert (Contains (Image, "val"), "missing val in: " & Str (Image));
   Assert (Contains (Image, "map"), "missing map in: " & Str (Image));
end Lml_Tests.Json_Import;
