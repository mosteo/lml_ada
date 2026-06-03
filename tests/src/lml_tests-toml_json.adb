with LML;
with LML.Conversions.TOML_JSON;

with TOML; use TOML;

with Lml_Tests.Support;

--  Direct TOML -> JSON conversion. Builds an array holding a string and a
--  table, converts it, and re-parses the JSON image to assert it carries the
--  exact structure (a 2-element vector: a string then a one-key table), not
--  just that the payload substrings appear somewhere.

procedure Lml_Tests.Toml_Json is

   use Lml_Tests.Support;
   use all type Yeison.Kinds;

   Sample : TOML_Value;

   Expected : Yeison.Any := Y_Vec;
   Table    : Yeison.Any := Y_Map;

begin
   Sample := Create_Array;
   Sample.Append (Create_String ("some string"));
   Sample.Append (Create_Table);
   Sample.Item (2).Set ("key", Create_String ("val"));

   Put (Table, "key", Y_Str ("val"));
   Expected.Append (Y_Str ("some string"));
   Expected.Append (Table);

   declare
      Image  : constant Text := LML.Conversions.TOML_JSON.Image (Sample);
      Parsed : constant Yeison.Any := LML.From_Text (Image, LML.JSON);
   begin
      Assert (Parsed.Kind = Vec_Kind,
              "expected a vector, got " & Parsed.Kind'Image);
      Assert_Equal (Parsed, Expected, "toml->json structure");
   end;
end Lml_Tests.Toml_Json;
