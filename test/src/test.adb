with Ada.Wide_Wide_Text_IO; use Ada.Wide_Wide_Text_IO;

with LML.Conversions.TOML_JSON;
with LML.Output.Factory;
with LML.Output.YAML;

with Test_Pragmas;

with TOML; use TOML;

with Yeison_12;

procedure Test is

   package Yeison renames Yeison_12;
   use Yeison.Operators;

   function "+" (Str : Yeison.Text) return Yeison.Scalar
     renames Yeison.Scalars.New_Text;

   Sample : constant Yeison.Any
     := Yeison.Empty_Map
       .Insert (+"key", +"val");
   --      .Insert (+"vec", To_Vec ((+1, +"two")))
   --      .Insert (+"map", Yeison.Empty_Map.Insert (+"key", +"val"));

   TOML_Sample : TOML_Value;

   subtype Text is Wide_Wide_String;

   procedure String_In_Table (Builder : in out LML.Output.Builder'Class) is
   begin
      Builder.Begin_Map;
      Builder.Insert ("key");
      Builder.Append (+"Stand-alone string");
      Builder.End_Map;
   end String_In_Table;

   procedure Table (Builder : in out LML.Output.Builder'Class) is
   begin
      Builder.Begin_Map;
      Builder.Insert ("key1");
      Builder.Append (+"val1");
      Builder.Insert ("key2");
      Builder.Append (+"val2");
      Builder.End_Map;
   end Table;

   procedure Report (Builder : LML.Output.Builder'Class; Title : Text)
   is
   begin
      Put_Line ("*** " & Title & " ***");
      Put_Line (Builder.To_Text);
   end Report;

begin
   --  Initialize TOML sample

   TOML_Sample := Create_Array;
   TOML_Sample.Append (Create_String ("some string"));
   TOML_Sample.Append (Create_Table);
   TOML_Sample.Item (2).Set ("key", Create_String ("val"));

   for Format in LML.Formats loop
      if Format in LML.Pragmas then
         goto Continue;  -- Pragmas is input-only
      end if;
      declare
         Empty   : constant LML.Output.Builder'Class :=
                     LML.Output.Factory.Get (Format);
         Builder : LML.Output.Builder'Class := LML.Output.Factory.Get (Format);
      begin
         Put_Line ("OUTPUT FORMAT: " & Format'Wide_Wide_Image);

         --  Output a simple string in anonymous table
         String_In_Table (Builder);
         Report (Builder, "string in anon table");

         --  Output within a named table
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("table");
         String_In_Table (Builder);
         Builder.End_Map;
         Report (Builder, "table within table");

         --  A simple table
         Builder := Empty;
         Table (Builder);
         Report (Builder, "anon table");

         --  Doubly-nested table
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("parent");
         Builder.Begin_Map;
         Builder.Insert ("child");
         String_In_Table (Builder);
         Builder.End_Map;
         Builder.End_Map;
         Report (Builder, "doubly-nested table");

         --  Output an array of strings inside the top-level anon table
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("vector");
         Builder.Begin_Vec;
         Builder.Append (+"item1");
         Builder.Append (+"item2");
         Builder.End_Vec;
         Builder.End_Map;
         Report (Builder, "array within table");

         --  Output an array of records
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("vector");
         Builder.Begin_Vec;
         Table (Builder);
         Table (Builder);
         Builder.End_Vec;
         Builder.End_Map;
         Report (Builder, "array of tables");

         --  Output table containing array
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("table");
         Builder.Begin_Map;
         Builder.Insert ("vector");
         Builder.Begin_Vec;
         Builder.Append (+"item1");
         Builder.Append (+"item2");
         Builder.End_Vec;
         Builder.End_Map;
         Builder.End_Map;
         Report (Builder, "array within table");

         Report (LML.Output.To_Builder (Sample, Format), "yeison to text");

         --  TOML only allows outputting a table, whereas JSON can output plain
         --  values or anonymous arrays. Thus, following cases can only be
         --  tested on JSON.

         --  Array of arrays
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("vec");
         Builder.Begin_Vec;
         for I in 1 .. 2 loop
            Builder.Begin_Vec;
            Builder.Append (+I'Wide_Wide_Image);
            Builder.Append (+Integer'(I + 1)'Wide_Wide_Image);
            Builder.End_Vec;
         end loop;
         Builder.End_Vec;
         Builder.End_Map;
         Report (Builder, "array of arrays within table");

         --  Array of arrays of arrays of maps

         --  For this particular case we show both YAML styles
         declare
            First : Boolean := True;
         begin
            <<YAML_Showcase>>

            Builder := Empty;
            if Format in LML.YAML and then not First then
               LML.Output.YAML.Builder (Builder)
                 .Set_Style (LML.Output.YAML.Expanded);
            end if;

            Builder.Begin_Map;
            Builder.Insert ("vec");
            Builder.Begin_Vec;
            for I in 1 .. 2 loop
               Builder.Begin_Vec;
               for J in Wide_Wide_Character'('a') .. 'b' loop
                  Builder.Begin_Vec;
                  Builder.Begin_Map;
                  Builder.Insert ("key1");
                  Builder.Append (+("" & J));
                  Builder.Insert ("key2");
                  Builder.Append (+("" & Wide_Wide_Character'Succ (J)));
                  Builder.End_Map;
                  Builder.End_Vec;
               end loop;
               Builder.End_Vec;
            end loop;
            Builder.End_Vec;
            Builder.End_Map;
            Report (Builder, "array of arrays of arrays of maps within table");

            if Format in LML.YAML and then First then
               First := False;
               goto YAML_Showcase;
            end if;
         end;

         ----------------------------------------------------------------------

         if Format not in LML.TOML then
            --  Object in anonymous array. Our TOML lib doesn't allow it out of
            --  a table.
            Builder := Empty;
            Builder.Begin_Vec;
            Table (Builder);
            Builder.End_Vec;
            Report (Builder, "table within anon array");

            --  A plain string value
            Builder := Empty;
            Builder.Append (+"stand-alone string");
            Report (Builder, "stand-alone string");

            --  An empty vector
            Builder := Empty;
            Builder.Begin_Vec;
            Builder.End_Vec;
            Report (Builder, "empty anon vec");

            --  Empty vector within table
            Builder := Empty;
            Builder.Begin_Map;

            Builder.Insert ("vec");
            Builder.Begin_Vec;
            Builder.End_Vec;

            Builder.End_Map;
            Report (Builder, "empty vector within table");
         end if;
      end;
      <<Continue>>
   end loop;

   --  Direct TOML -> JSON conversion
   Put_Line ("TOML -> JSON: "
             & LML.Conversions.TOML_JSON.Image (TOML_Sample));

   --  JSON -> Yeison import
   declare
      JSON_Text_Sample : constant Text
        := "{ ""vec"": [1, 2, 3], ""key"": ""val"", ""map"": {""k"":""v""}}";
   begin
      Put_Line ("JSON -> YSON: "
                & LML.From_Text (JSON_Text_Sample, LML.JSON).Image);
   end;

   --  Pragma input parser
   Test_Pragmas.Run;
end Test;
