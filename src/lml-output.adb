package body LML.Output is

   ----------------------
   -- Check_Completion --
   ----------------------

   procedure Check_Completion (This : in out Builder'Class) is
   begin
      if This.Level = 0 then
         This.On_Completion;
      end if;
   end Check_Completion;

   -----------
   -- Write --
   -----------

   procedure Append (This : in out Builder'Class; V : Text) is
   begin
      This.Append_Impl (V);
      This.First := False;
      This.Check_Completion;
   end Append;

   ------------
   -- Insert --
   ------------

   procedure Insert (This : in out Builder'Class; K : Text) is
   begin
      This.Keys.Append (K);
      This.Insert_Impl (K);
   end Insert;

   ---------------
   -- Begin_Map --
   ---------------

   procedure Begin_Map (This : in out Builder'Class) is
   begin
      This.Begin_Map_Impl;
      This.First := True;
      This.Level := This.Level + 1;
   end Begin_Map;

   -------------
   -- End_Map --
   -------------

   procedure End_Map (This : in out Builder'Class) is
   begin
      This.End_Map_Impl;
      This.Level := This.Level - 1;
      This.Check_Completion;
   end End_Map;

   ---------------
   -- Begin_Vec --
   ---------------

   procedure Begin_Vec (This : in out Builder'Class) is
   begin
      This.Begin_Vec_Impl;
      This.First := True;
      This.Level := This.Level + 1;
   end Begin_Vec;

   -------------
   -- End_Vec --
   -------------

   procedure End_Vec (This : in out Builder'Class) is
   begin
      This.End_Vec_Impl;
      This.Level := This.Level - 1;
      This.Check_Completion;
   end End_Vec;

   ---------
   -- Pop --
   ---------

   function Pop (This : in out Builder'Class) return Text is
   begin
      return Key : constant Text := This.Keys.Last_Element do
         This.Keys.Delete_Last;
         if not This.Keys.Is_Empty then
            raise Program_Error with "dangling key";
         end if;
      end return;
   end Pop;

end LML.Output;
