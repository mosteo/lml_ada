with Ada.Wide_Wide_Text_IO; use Ada.Wide_Wide_Text_IO;

with LML.Output.TOML;

--  with TOML; use TOML;

procedure Test is
   Builder : LML.Output.TOML.Builder;

   procedure String_In_Table is
   begin
      Builder.Begin_Map;
      Builder.Insert ("key");
      Builder.Append ("Stand-alone string");
      Builder.End_Map;
   end String_In_Table;

   procedure Table is
   begin
      Builder.Begin_Map;
      Builder.Insert ("key1");
      Builder.Append ("val1");
      Builder.Insert ("key2");
      Builder.Append ("val2");
      Builder.End_Map;
   end Table;

begin
   --  Output a simple string in anonymous table
   String_In_Table;
   Put_Line (Builder.To_Text);

   --  Output within a named table
   Builder.Clear;
   Builder.Begin_Map;
   Builder.Insert ("table");
   String_In_Table;
   Builder.End_Map;
   Put_Line (Builder.To_Text);

   --  Doubly-nested table
   Builder.Clear;
   Builder.Begin_Map;
   Builder.Insert ("parent");
   Builder.Begin_Map;
   Builder.Insert ("child");
   String_In_Table;
   Builder.End_Map;
   Builder.End_Map;
   Put_Line (Builder.To_Text);

   --  Output an array of strings inside the top-level anon table
   Builder.Clear;
   Builder.Begin_Map;
   Builder.Insert ("vector");
   Builder.Begin_Vec;
   Builder.Append ("item1");
   Builder.Append ("item2");
   Builder.End_Vec;
   Builder.End_Map;
   Put_Line (Builder.To_Text);

   --  Output an array of records
   Builder.Clear;
   Builder.Begin_Map;
   Builder.Insert ("vector");
   Builder.Begin_Vec;
   Table;
   Table;
   Builder.End_Vec;
   Builder.End_Map;
   Put_Line (Builder.To_Text);

   --  Output table containing array
   Builder.Clear;
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
end Test;
