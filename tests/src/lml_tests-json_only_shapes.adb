with LML;
with LML.Output.Factory;

with Lml_Tests.Support;

--  Shapes that only JSON and YAML allow (TOML can only emit a top-level
--  table): a table inside an anonymous array, a standalone string, empty
--  vectors and a standalone nil. For JSON the output is re-parsed and compared
--  against an oracle; for YAML a non-empty smoke check is kept. The two empty
--  shapes may legitimately render as empty text, so they are smoke-only.

procedure Lml_Tests.Json_Only_Shapes is

   use Lml_Tests.Support;
   use type LML.Formats;

   function "+" (S : Yeison.Text) return Yeison.Scalar
     renames Yeison.Scalars.New_Text;

   procedure Each
     (Drive    : access procedure (B : in out LML.Output.Builder'Class);
      Expected : Yeison.Any;
      Title    : String) is
   begin
      for Format in LML.Supported_Outputs loop
         if Format /= LML.TOML then
            declare
               B : LML.Output.Builder'Class := LML.Output.Factory.Get (Format);
            begin
               Drive (B);
               Check_Output (B.To_Text, Format, Expected, Title);
            end;
         end if;
      end loop;
   end Each;

   --------------------
   -- Shape drivers  --
   --------------------

   procedure Table (B : in out LML.Output.Builder'Class) is
   begin
      B.Begin_Map;
      B.Insert ("key1"); B.Append (+"val1");
      B.Insert ("key2"); B.Append (+"val2");
      B.End_Map;
   end Table;

   procedure Arr_Of_Map (B : in out LML.Output.Builder'Class) is
   begin
      B.Begin_Vec;
      Table (B);
      B.End_Vec;
   end Arr_Of_Map;

   procedure Standalone_String (B : in out LML.Output.Builder'Class) is
   begin
      B.Append (+"stand-alone string");
   end Standalone_String;

   procedure Empty_Vec_In_Map (B : in out LML.Output.Builder'Class) is
   begin
      B.Begin_Map;
      B.Insert ("vec");
      B.Begin_Vec;
      B.End_Vec;
      B.End_Map;
   end Empty_Vec_In_Map;

   procedure Standalone_Nil (B : in out LML.Output.Builder'Class) is
   begin
      B.Append_Nil;
   end Standalone_Nil;

   --------------------
   -- Oracles        --
   --------------------

   E_Arr_Of_Map : Yeison.Any := Y_Vec;
   E_String     : constant Yeison.Any := Y_Str ("stand-alone string");
   E_Empty_Map  : Yeison.Any := Y_Map;
   E_Nil        : constant Yeison.Any := Y_Nil;

   Row : Yeison.Any := Y_Map;

begin
   Put (Row, "key1", Y_Str ("val1"));
   Put (Row, "key2", Y_Str ("val2"));
   E_Arr_Of_Map.Append (Row);
   Put (E_Empty_Map, "vec", Y_Vec);

   Each (Arr_Of_Map'Access,        E_Arr_Of_Map, "table within anon array");
   Each (Standalone_String'Access, E_String,     "stand-alone string");
   Each (Empty_Vec_In_Map'Access,  E_Empty_Map,  "empty vector within table");
   Each (Standalone_Nil'Access,    E_Nil,        "stand-alone nil");

   --  A standalone empty vector may render as empty text in either format, so
   --  there is no oracle to compare against: just require it not to raise.
   for Format in LML.Supported_Outputs loop
      if Format /= LML.TOML then
         declare
            B : LML.Output.Builder'Class := LML.Output.Factory.Get (Format);
         begin
            B.Begin_Vec;
            B.End_Vec;
            declare
               Ignore : constant Text := B.To_Text;
            begin
               null;
            end;
         end;
      end if;
   end loop;
end Lml_Tests.Json_Only_Shapes;
