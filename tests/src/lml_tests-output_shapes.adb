with LML.Output.Factory;
with LML.Output.YAML;

with Yeison_12;

--  Exercise every builder shape on every supported output format and assert
--  that something non-empty comes out. This is a smoke test: its real value is
--  that none of the builder paths raise at runtime.

procedure Lml_Tests.Output_Shapes is

   package Yeison renames Yeison_12;

   function "+" (Str : Yeison.Text) return Yeison.Scalar
     renames Yeison.Scalars.New_Text;

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

   procedure Check (Builder : LML.Output.Builder'Class; Title : Text) is
   begin
      Assert (Builder.To_Text'Length > 0, "empty output for " & Str (Title));
   end Check;

begin
   for Format in LML.Supported_Outputs loop
      declare
         Empty   : constant LML.Output.Builder'Class :=
                     LML.Output.Factory.Get (Format);
         Builder : LML.Output.Builder'Class := LML.Output.Factory.Get (Format);
      begin
         --  Output a simple string in anonymous table
         String_In_Table (Builder);
         Check (Builder, "string in anon table");

         --  Output within a named table
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("table");
         String_In_Table (Builder);
         Builder.End_Map;
         Check (Builder, "table within table");

         --  A simple table
         Builder := Empty;
         Table (Builder);
         Check (Builder, "anon table");

         --  Doubly-nested table
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("parent");
         Builder.Begin_Map;
         Builder.Insert ("child");
         String_In_Table (Builder);
         Builder.End_Map;
         Builder.End_Map;
         Check (Builder, "doubly-nested table");

         --  Output an array of strings inside the top-level anon table
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("vector");
         Builder.Begin_Vec;
         Builder.Append (+"item1");
         Builder.Append (+"item2");
         Builder.End_Vec;
         Builder.End_Map;
         Check (Builder, "array within table");

         --  Output an array of records
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("vector");
         Builder.Begin_Vec;
         Table (Builder);
         Table (Builder);
         Builder.End_Vec;
         Builder.End_Map;
         Check (Builder, "array of tables");

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
         Check (Builder, "array within nested table");

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
         Check (Builder, "array of arrays within table");

         --  Array of arrays of arrays of maps. For YAML we show both styles.
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
            Check (Builder, "array of arrays of arrays of maps within table");

            if Format in LML.YAML and then First then
               First := False;
               goto YAML_Showcase;
            end if;
         end;
      end;
   end loop;
end Lml_Tests.Output_Shapes;
