with LML.Conversions.TOML_JSON;

with TOML; use TOML;

--  Direct TOML -> JSON conversion. Builds an array holding a string and a
--  table and checks the JSON image contains both payloads.

procedure Lml_Tests.Toml_Json is
   Sample : TOML_Value;
begin
   Sample := Create_Array;
   Sample.Append (Create_String ("some string"));
   Sample.Append (Create_Table);
   Sample.Item (2).Set ("key", Create_String ("val"));

   declare
      Image : constant Text := LML.Conversions.TOML_JSON.Image (Sample);
   begin
      Assert (Contains (Image, "some string"),
              "missing string in: " & Str (Image));
      Assert (Contains (Image, "key"), "missing key in: "   & Str (Image));
      Assert (Contains (Image, "val"), "missing value in: " & Str (Image));
   end;
end Lml_Tests.Toml_Json;
