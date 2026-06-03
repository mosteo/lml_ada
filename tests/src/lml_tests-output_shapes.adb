with LML;
with LML.Output.Factory;

with Lml_Tests.Support;

--  Drive every builder shape on every supported output format. For the formats
--  LML can read back (JSON, TOML) the produced text is re-parsed and compared,
--  structurally, against an independently-built oracle: this catches wrong
--  nesting, dropped elements or swapped values, not merely that output is
--  non-empty. For YAML (output only) we keep a non-empty smoke check.

procedure Lml_Tests.Output_Shapes is

   use Lml_Tests.Support;

   function "+" (S : Yeison.Text) return Yeison.Scalar
     renames Yeison.Scalars.New_Text;

   procedure Check_Shape
     (Drive    : access procedure (B : in out LML.Output.Builder'Class);
      Expected : Yeison.Any;
      Title    : String) is
   begin
      for Format in LML.Supported_Outputs loop
         declare
            B : LML.Output.Builder'Class := LML.Output.Factory.Get (Format);
         begin
            Drive (B);
            Check_Output (B.To_Text, Format, Expected, Title);
         end;
      end loop;
   end Check_Shape;

   --------------------
   -- Shape drivers  --
   --------------------

   procedure Simple_Map (B : in out LML.Output.Builder'Class) is
   begin
      B.Begin_Map;
      B.Insert ("key1"); B.Append (+"val1");
      B.Insert ("key2"); B.Append (+"val2");
      B.End_Map;
   end Simple_Map;

   procedure Nested_Map (B : in out LML.Output.Builder'Class) is
   begin
      B.Begin_Map;
      B.Insert ("outer");
      B.Begin_Map;
      B.Insert ("inner"); B.Append (+"x");
      B.End_Map;
      B.End_Map;
   end Nested_Map;

   procedure Vec_Of_Strings (B : in out LML.Output.Builder'Class) is
   begin
      B.Begin_Map;
      B.Insert ("vec");
      B.Begin_Vec;
      B.Append (+"a"); B.Append (+"b");
      B.End_Vec;
      B.End_Map;
   end Vec_Of_Strings;

   procedure Vec_Of_Maps (B : in out LML.Output.Builder'Class) is
   begin
      B.Begin_Map;
      B.Insert ("rows");
      B.Begin_Vec;
      B.Begin_Map; B.Insert ("k"); B.Append (+"v1"); B.End_Map;
      B.Begin_Map; B.Insert ("k"); B.Append (+"v2"); B.End_Map;
      B.End_Vec;
      B.End_Map;
   end Vec_Of_Maps;

   procedure Vec_Of_Vecs (B : in out LML.Output.Builder'Class) is
   begin
      B.Begin_Map;
      B.Insert ("grid");
      B.Begin_Vec;
      B.Begin_Vec; B.Append (+"a"); B.Append (+"b"); B.End_Vec;
      B.Begin_Vec; B.Append (+"c"); B.End_Vec;
      B.End_Vec;
      B.End_Map;
   end Vec_Of_Vecs;

   procedure Deep (B : in out LML.Output.Builder'Class) is
   begin
      B.Begin_Map;
      B.Insert ("deep");
      B.Begin_Vec;
      B.Begin_Vec;
      B.Begin_Map;
      B.Insert ("k1"); B.Append (+"a");
      B.Insert ("k2"); B.Append (+"b");
      B.End_Map;
      B.End_Vec;
      B.End_Vec;
      B.End_Map;
   end Deep;

   --------------------
   -- Oracles        --
   --------------------

   function Map_Of (K1, V1, K2, V2 : Text) return Yeison.Any is
      M : Yeison.Any := Y_Map;
   begin
      Put (M, K1, Y_Str (V1));
      Put (M, K2, Y_Str (V2));
      return M;
   end Map_Of;

   E_Simple : constant Yeison.Any := Map_Of ("key1", "val1", "key2", "val2");
   E_Nested : Yeison.Any := Y_Map;
   E_Vstr   : Yeison.Any := Y_Map;
   E_Vmaps  : Yeison.Any := Y_Map;
   E_Vvecs  : Yeison.Any := Y_Map;
   E_Deep   : Yeison.Any := Y_Map;

   Tmp_Map  : Yeison.Any := Y_Map;
   Tmp_Vec  : Yeison.Any := Y_Vec;
   Tmp_Vec2 : Yeison.Any := Y_Vec;

begin
   --  E_Nested = { outer => { inner => x } }
   Put (Tmp_Map, "inner", Y_Str ("x"));
   Put (E_Nested, "outer", Tmp_Map);

   --  E_Vstr = { vec => [a, b] }
   Tmp_Vec := Y_Vec;
   Tmp_Vec.Append (Y_Str ("a"));
   Tmp_Vec.Append (Y_Str ("b"));
   Put (E_Vstr, "vec", Tmp_Vec);

   --  E_Vmaps = { rows => [ {k=>v1}, {k=>v2} ] }
   Tmp_Vec := Y_Vec;
   Tmp_Map := Y_Map; Put (Tmp_Map, "k", Y_Str ("v1")); Tmp_Vec.Append (Tmp_Map);
   Tmp_Map := Y_Map; Put (Tmp_Map, "k", Y_Str ("v2")); Tmp_Vec.Append (Tmp_Map);
   Put (E_Vmaps, "rows", Tmp_Vec);

   --  E_Vvecs = { grid => [ [a, b], [c] ] }
   Tmp_Vec  := Y_Vec;
   Tmp_Vec2 := Y_Vec;
   Tmp_Vec2.Append (Y_Str ("a")); Tmp_Vec2.Append (Y_Str ("b"));
   Tmp_Vec.Append (Tmp_Vec2);
   Tmp_Vec2 := Y_Vec; Tmp_Vec2.Append (Y_Str ("c"));
   Tmp_Vec.Append (Tmp_Vec2);
   Put (E_Vvecs, "grid", Tmp_Vec);

   --  E_Deep = { deep => [ [ {k1=>a, k2=>b} ] ] }
   Tmp_Vec  := Y_Vec;
   Tmp_Vec2 := Y_Vec;
   Tmp_Vec2.Append (Map_Of ("k1", "a", "k2", "b"));
   Tmp_Vec.Append (Tmp_Vec2);
   Put (E_Deep, "deep", Tmp_Vec);

   Check_Shape (Simple_Map'Access,     E_Simple, "simple map");
   Check_Shape (Nested_Map'Access,     E_Nested, "nested map");
   Check_Shape (Vec_Of_Strings'Access, E_Vstr,   "vector of strings");
   Check_Shape (Vec_Of_Maps'Access,    E_Vmaps,  "vector of maps");
   Check_Shape (Vec_Of_Vecs'Access,    E_Vvecs,  "vector of vectors");
   Check_Shape (Deep'Access,           E_Deep,   "deeply nested");
end Lml_Tests.Output_Shapes;
