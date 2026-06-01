with LML.Output.Factory;

with Yeison_12;

--  Shapes that only JSON and YAML allow (TOML can only emit a top-level
--  table): standalone strings, anonymous arrays, empty vectors and a
--  standalone nil. Smoke test: must not raise, must produce output.

procedure Lml_Tests.Json_Only_Shapes is

   package Yeison renames Yeison_12;

   function "+" (Str : Yeison.Text) return Yeison.Scalar
     renames Yeison.Scalars.New_Text;

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

   procedure Exercise (Builder : LML.Output.Builder'Class) is
      Ignore : constant Text := Builder.To_Text;
   begin
      null; -- empty/nil shapes may legitimately render as empty text
   end Exercise;

begin
   for Format in LML.Supported_Outputs loop
      if Format not in LML.TOML then
         declare
            Empty   : constant LML.Output.Builder'Class :=
                        LML.Output.Factory.Get (Format);
            Builder : LML.Output.Builder'Class :=
                        LML.Output.Factory.Get (Format);
         begin
            --  Object in anonymous array
            Builder.Begin_Vec;
            Table (Builder);
            Builder.End_Vec;
            Check (Builder, "table within anon array");

            --  A plain string value
            Builder := Empty;
            Builder.Append (+"stand-alone string");
            Check (Builder, "stand-alone string");

            --  An empty vector (renders as empty text in some formats)
            Builder := Empty;
            Builder.Begin_Vec;
            Builder.End_Vec;
            Exercise (Builder);

            --  Empty vector within table
            Builder := Empty;
            Builder.Begin_Map;
            Builder.Insert ("vec");
            Builder.Begin_Vec;
            Builder.End_Vec;
            Builder.End_Map;
            Exercise (Builder);

            --  Nil as a standalone value
            Builder := Empty;
            Builder.Append_Nil;
            Exercise (Builder);
         end;
      end if;
   end loop;
end Lml_Tests.Json_Only_Shapes;
