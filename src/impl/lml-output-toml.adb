package body LML.Output.TOML is

   ----------------
   -- New_Scalar --
   ----------------

   function New_Scalar (V : Scalar) return TOML_Value is
      use all type Scalar_Kinds;

      -----------------
      -- Create_Real --
      -----------------

      function Create_Real return TOML_Value
      is (Create_Float
          ((case V.As_Real.Class is
               when Yeison.Reals.Finite =>
                  Any_Float'(Regular, Valid_Float (V.As_Real.Value)),
               when Yeison.Reals.Infinite =>
                  Any_Float'(Infinity, V.As_Real.Positive),
               when Yeison.Reals.NaN      =>
                  Any_Float'(NaN, True)
           )));

   begin
      return
        (case V.Kind is
            when Bool_Kind =>
              Create_Boolean (V.As_Boolean),
            when Int_Kind  =>
              Create_Integer (Any_Integer (V.As_Integer)),
            when Real_Kind =>
              Create_Real,
            when Str_Kind  =>
              Create_String  (Encode (V.As_Text)));
   end New_Scalar;

   ----------------
   -- Set_In_Map --
   ----------------

   procedure Set_In_Map (Map : in out TOML_Value; Key : Text; Val : TOML_Value)
   is
   begin
      Map.Set (Encode (Key), Val);
   end Set_In_Map;

   -------------------
   -- Append_To_Vec --
   -------------------

   procedure Append_To_Vec (Vec : in out TOML_Value; Val : TOML_Value) is
   begin
      Vec.Append (Val);
   end Append_To_Vec;

end LML.Output.TOML;
