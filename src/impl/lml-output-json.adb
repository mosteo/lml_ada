--  with Ada.Wide_Wide_Text_IO; use Ada.Wide_Wide_Text_IO;

package body LML.Output.JSON is

   use all type Yeison.Kinds;

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
      if This.Root.Has_Value then
         raise Constraint_Error with "data structure is already complete";
      end if;
   end Ensure_Open;

   -------------
   -- To_Text --
   -------------

   overriding
   function To_Text (This : Builder) return Text is
   begin
      if not This.Stack.Is_Empty then
         raise Constraint_Error with "incomplete data structure";
      else
         return This.Root.Image (Format => Yeison.Impl.JSON);
      end if;
   end To_Text;

   -----------------
   -- Append_JSON --
   -----------------

   procedure Append_JSON (This : in out Builder; V : Yeison.Any) is
   begin
      This.Ensure_Open;

      if not This.Stack.Is_Empty then
         case This.Stack.Last_Element.Kind is
            when Map_Kind =>
               This.Stack.Reference (This.Stack.Last)
                         .Insert (Yeison.Make.Str (This.Pop), V);
            when Vec_Kind =>
               This.Stack.Reference (This.Stack.Last).Append (V);
            when others =>
               raise Program_Error
                 with "cannot append, parent is not a collection";
         end case;
      elsif V.Kind not in Yeison.Impl.Composite_Kinds then
         --  A single value that is in itself the data structure
         This.Root := V;
      end if;
   end Append_JSON;

   -----------------
   -- Append_Impl --
   -----------------

   overriding procedure Append_Impl (This : in out Builder; Val : Scalar) is
   begin
      This.Append_JSON (Yeison.Make.Scalar (Val));
   end Append_Impl;

   --------------------
   -- Begin_Map_Impl --
   --------------------

   overriding procedure Begin_Map_Impl (This : in out Builder) is
      New_Table : constant Yeison.Any := Yeison.Empty_Map;
   begin
      This.Ensure_Open;
      This.Stack.Append (New_Table);
   end Begin_Map_Impl;

   ------------------
   -- End_Map_Impl --
   ------------------

   overriding procedure End_Map_Impl (This : in out Builder) is
   begin
      if This.Root.Has_Value then
         raise Program_Error with "Two roots in structure?";
      end if;

      --  Insert the completed table into the parent value
      declare
         Last : constant Yeison.Any := This.Stack.Last_Element;
      begin
         This.Stack.Delete_Last;
         if This.Stack.Is_Empty then
            This.Root := Last;
         else
            This.Append_JSON (Last);
         end if;
      end;
   end End_Map_Impl;

   --------------------
   -- Begin_Vec_Impl --
   --------------------

   overriding procedure Begin_Vec_Impl (This : in out Builder) is
      New_Vector : constant Yeison.Any := Yeison.Empty_Vec;
   begin
      This.Ensure_Open;
      This.Stack.Append (New_Vector);
   end Begin_Vec_Impl;

   ------------------
   -- End_Vec_Impl --
   ------------------

   overriding procedure End_Vec_Impl (This : in out Builder) is
   begin
      This.End_Map_Impl;
   end End_Vec_Impl;

end LML.Output.JSON;
