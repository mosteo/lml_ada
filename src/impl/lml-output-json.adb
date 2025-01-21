package body LML.Output.JSON is

   use all type Yeison.Kinds;

   -----------
   -- Clear --
   -----------

   procedure Clear (This : in out Builder) is
   begin
      This := (others => <>);
   end Clear;

   -------------
   -- To_Text --
   -------------

   overriding
   function To_Text (This : in out Builder) return Text is
   begin
      return This.Root.Image (Format => Yeison.Impl.JSON, Compact => False);
   end To_Text;

   -----------------
   -- Append_JSON --
   -----------------

   procedure Append_JSON (This : in out Builder; V : Yeison.Any) is
   begin
      if not This.Parent.Is_Empty then
         case This.Parent.Last_Element.Kind is
            when Map_Kind =>
               This.Parent.Last_Element.Insert (Yeison.Make_Str (This.Pop), V);
            when Vec_Kind =>
               This.Parent.Last_Element.Append (V);
            when others =>
               raise Program_Error
                 with "cannot append, parent is not a collection";
         end case;
      elsif V.Kind not in Yeison.Impl.Composite_Kinds then
         raise Program_Error
           with "cannot append scalar while parent is empty";
      end if;
   end Append_JSON;

   -----------------
   -- Append_Impl --
   -----------------

   overriding procedure Append_Impl (This : in out Builder; V : Text) is
   begin
      This.Append_JSON (Yeison.Make_Str (V));
   end Append_Impl;

   --------------------
   -- Begin_Map_Impl --
   --------------------

   overriding procedure Begin_Map_Impl (This : in out Builder) is
      New_Table : constant Yeison.Any := Yeison.Empty_Map;
   begin
      This.Append_JSON (New_Table);
      This.Parent.Append (New_Table);
   end Begin_Map_Impl;

   ------------------
   -- End_Map_Impl --
   ------------------

   overriding procedure End_Map_Impl (This : in out Builder) is
   begin
      if This.Root.Is_Valid then
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
      New_Vector : constant Yeison.Any := Yeison.Empty_Vec;
   begin
      This.Append_JSON (New_Vector);
      This.Parent.Append (New_Vector);
   end Begin_Vec_Impl;

   ------------------
   -- End_Vec_Impl --
   ------------------

   overriding procedure End_Vec_Impl (This : in out Builder) is
   begin
      This.End_Map_Impl;
   end End_Vec_Impl;

end LML.Output.JSON;
