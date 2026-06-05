package body LML.Output.Tree is

   -----------
   -- Clear --
   -----------

   procedure Clear (This : in out Builder) is
   begin
      This := (others => <>);
   end Clear;

   --------------
   -- Has_Root --
   --------------

   function Has_Root (This : Builder) return Boolean
   is (Has_Value (This.Root));

   ---------------
   -- Root_Node --
   ---------------

   function Root_Node (This : Builder) return Node
   is (This.Root);

   -----------------
   -- Is_Building --
   -----------------

   function Is_Building (This : Builder) return Boolean
   is (not This.Stack.Is_Empty);

   ----------------
   -- First_Open --
   ----------------

   function First_Open (This : Builder) return Node
   is (if This.Stack.Is_Empty then No_Node else This.Stack.First_Element);

   ---------------
   -- Last_Open --
   ---------------

   function Last_Open (This : Builder) return Node
   is (if This.Stack.Is_Empty then No_Node else This.Stack.Last_Element);

   -----------------
   -- Ensure_Open --
   -----------------

   procedure Ensure_Open (This : Builder) is
   begin
      if Has_Value (This.Root) then
         raise Constraint_Error with "data structure is already complete";
      end if;
   end Ensure_Open;

   -----------------
   -- Append_Node --
   -----------------

   procedure Append_Node (This : in out Builder; V : Node) is
   begin
      This.Ensure_Open;

      if not This.Stack.Is_Empty then
         declare
            Top : Node := This.Stack.Last_Element;
         begin
            if Is_Map (Top) then
               Set_In_Map (Top, This.Pop, V);
            else
               Append_To_Vec (Top, V);
            end if;
            This.Stack.Replace_Element (This.Stack.Last, Top);
         end;
      elsif not Is_Composite (V) then
         --  A stand-alone value that is itself the whole data structure.
         This.Root := V;
      end if;
   end Append_Node;

   -------------
   -- To_Text --
   -------------

   overriding function To_Text (This : Builder) return Text is
   begin
      if not This.Stack.Is_Empty then
         raise Constraint_Error with "incomplete data structure";
      else
         return Image (This.Root);
      end if;
   end To_Text;

   -----------------
   -- Append_Impl --
   -----------------

   overriding procedure Append_Impl (This : in out Builder; Val : Scalar) is
   begin
      This.Append_Node (New_Scalar (Val));
   end Append_Impl;

   ---------------------
   -- Append_Nil_Impl --
   ---------------------

   overriding procedure Append_Nil_Impl (This : in out Builder) is
   begin
      This.Append_Node (New_Nil);
   end Append_Nil_Impl;

   --------------------
   -- Begin_Map_Impl --
   --------------------

   overriding procedure Begin_Map_Impl (This : in out Builder) is
   begin
      This.Ensure_Open;
      This.Stack.Append (Empty_Map);
   end Begin_Map_Impl;

   ------------------
   -- End_Map_Impl --
   ------------------

   overriding procedure End_Map_Impl (This : in out Builder) is
   begin
      if Has_Value (This.Root) then
         raise Program_Error with "Two roots in structure?";
      end if;

      declare
         Last : constant Node := This.Stack.Last_Element;
      begin
         This.Stack.Delete_Last;
         if This.Stack.Is_Empty then
            This.Root := Last;
         else
            This.Append_Node (Last);
         end if;
      end;
   end End_Map_Impl;

   --------------------
   -- Begin_Vec_Impl --
   --------------------

   overriding procedure Begin_Vec_Impl (This : in out Builder) is
   begin
      This.Ensure_Open;
      This.Stack.Append (Empty_Vec);
   end Begin_Vec_Impl;

   ------------------
   -- End_Vec_Impl --
   ------------------

   overriding procedure End_Vec_Impl (This : in out Builder) is
   begin
      This.End_Map_Impl;
   end End_Vec_Impl;

end LML.Output.Tree;
