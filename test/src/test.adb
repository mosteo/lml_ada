with Ada.Wide_Wide_Text_IO; use Ada.Wide_Wide_Text_IO;

with LML.Output.Factory;

--  with TOML; use TOML;

procedure Test is

   procedure String_In_Table (Builder : in out LML.Output.Builder'Class) is
   begin
      Builder.Begin_Map;
      Builder.Insert ("key");
      Builder.Append ("Stand-alone string");
      Builder.End_Map;
   end String_In_Table;

   procedure Table (Builder : in out LML.Output.Builder'Class) is
   begin
      Builder.Begin_Map;
      Builder.Insert ("key1");
      Builder.Append ("val1");
      Builder.Insert ("key2");
      Builder.Append ("val2");
      Builder.End_Map;
   end Table;

begin
   for Format in LML.Formats loop
      declare
         Empty   : constant LML.Output.Builder'Class :=
                     LML.Output.Factory.Get (Format);
         Builder : LML.Output.Builder'Class := LML.Output.Factory.Get (Format);
      begin

         --  Output a simple string in anonymous table
         String_In_Table (Builder);
         Put_Line (Builder.To_Text);

         --  Output within a named table
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("table");
         String_In_Table (Builder);
         Builder.End_Map;
         Put_Line (Builder.To_Text);

         --  Doubly-nested table
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("parent");
         Builder.Begin_Map;
         Builder.Insert ("child");
         String_In_Table (Builder);
         Builder.End_Map;
         Builder.End_Map;
         Put_Line (Builder.To_Text);

         --  Output an array of strings inside the top-level anon table
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("vector");
         Builder.Begin_Vec;
         Builder.Append ("item1");
         Builder.Append ("item2");
         Builder.End_Vec;
         Builder.End_Map;
         Put_Line (Builder.To_Text);

         --  Output an array of records
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("vector");
         Builder.Begin_Vec;
         Table (Builder);
         Table (Builder);
         Builder.End_Vec;
         Builder.End_Map;
         Put_Line (Builder.To_Text);

         --  Output table containing array
         Builder := Empty;
         Builder.Begin_Map;
         Builder.Insert ("table");
         Builder.Begin_Map;
         Builder.Insert ("vector");
         Builder.Begin_Vec;
         Builder.Append ("item1");
         Builder.Append ("item2");
         Builder.End_Vec;
         Builder.End_Map;
         Builder.End_Map;
         Put_Line (Builder.To_Text);

         --  Object in anonymous array. Our TOML lib doesn't allow it out of a
         --  table.
         if Format not in LML.TOML then
            Builder := Empty;
            Builder.Begin_Vec;
            Table (Builder);
            Builder.End_Vec;
            Put_Line (Builder.To_Text);
         end if;

      end;
   end loop;
end Test;
