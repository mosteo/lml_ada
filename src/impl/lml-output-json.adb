package body LML.Output.JSON is

   ----------------
   -- Set_In_Map --
   ----------------

   procedure Set_In_Map
     (Map : in out Yeison.Any; Key : Text; Val : Yeison.Any) is
   begin
      Map.Insert (Yeison.Make.Str (Key), Val);
   end Set_In_Map;

   -------------------
   -- Append_To_Vec --
   -------------------

   procedure Append_To_Vec (Vec : in out Yeison.Any; Val : Yeison.Any) is
   begin
      Vec.Append (Val);
   end Append_To_Vec;

end LML.Output.JSON;
