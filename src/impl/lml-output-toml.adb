package body LML.Output.TOML is

   -----------
   -- Clear --
   -----------

   procedure Clear (This : in out Builder) is
   begin
      This := (others => <>);
   end Clear;

   -----------------
   -- Ensure_Open --
   -----------------

   procedure Ensure_Open (This : Builder) is
   begin
      if This.Root /= No_TOML_Value then
         raise Constraint_Error with "data structure is already complete";
      end if;
   end Ensure_Open;

   -------------
   -- To_Text --
   -------------

   overriding
   function To_Text (This : Builder) return Text is
   begin
      return Decode (This.Root.Dump_As_String);
   end To_Text;

   -----------------
   -- Append_TOML --
   -----------------

   procedure Append_TOML (This : in out Builder; V : TOML_Value) is
   begin
      This.Ensure_Open;
      if not This.Parent.Is_Empty then
         case This.Parent.Last_Element.Kind is
            when TOML_Table =>
               This.Parent.Last_Element.Set (Encode (This.Pop), V);
            when TOML_Array =>
               This.Parent.Last_Element.Append (V);
            when others =>
               raise Program_Error
                 with "cannot append, parent is not a collection";
         end case;
      elsif V.Kind not in Composite_Value_Kind then
         --  The stand-alone value is the data structure itself
         This.Root := V;
      end if;
   end Append_TOML;

   -----------------
   -- Append_Impl --
   -----------------

   overriding procedure Append_Impl (This : in out Builder; V : Scalar) is
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
      This.Append_TOML
        (case V.Kind is
            when Bool_Kind =>
              Create_Boolean (V.As_Boolean),
            when Int_Kind  =>
              Create_Integer (Any_Integer (V.As_Integer)),
            when Real_Kind =>
              Create_Real,
            when Str_Kind  =>
              Create_String  (Encode (V.As_Text))
        );
   end Append_Impl;

   ---------------------
   -- Append_Nil_Impl --
   ---------------------

   overriding procedure Append_Nil_Impl (This : in out Builder) is
      pragma Unreferenced (This);
   begin
      raise LML.Unsupported_Error with
        "TOML does not support null values";
   end Append_Nil_Impl;

   --------------------
   -- Begin_Map_Impl --
   --------------------

   overriding procedure Begin_Map_Impl (This : in out Builder) is
      New_Table : constant TOML_Value := Create_Table;
   begin
      This.Ensure_Open;
      This.Append_TOML (New_Table);
      This.Parent.Append (New_Table);
   end Begin_Map_Impl;

   ------------------
   -- End_Map_Impl --
   ------------------

   overriding procedure End_Map_Impl (This : in out Builder) is
   begin
      if This.Root.Is_Present then
         raise Program_Error with "Two roots in structure?";
      end if;

      if This.Parent.Length in 1 then
         This.Root := This.Parent.Last_Element;
      end if;

      This.Parent.Delete_Last;
   end End_Map_Impl;

   --------------------
   -- Begin_Vec_Impl --
   --------------------

   overriding procedure Begin_Vec_Impl (This : in out Builder) is
      New_Vector : constant TOML_Value := Create_Array;
   begin
      This.Ensure_Open;
      This.Append_TOML (New_Vector);
      This.Parent.Append (New_Vector);
   end Begin_Vec_Impl;

   ------------------
   -- End_Vec_Impl --
   ------------------

   overriding procedure End_Vec_Impl (This : in out Builder) is
   begin
      This.End_Map_Impl;
   end End_Vec_Impl;

end LML.Output.TOML;
