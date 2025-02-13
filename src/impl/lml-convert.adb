package body LML.Convert is

   -----------------
   -- Obj_To_Text --
   -----------------

   --  generic
   --     type From is private;
   --     with procedure Build (This    : From;
   --                           Builder : in out Output.Builder'Class);
   --     --  Some procedure in LML.Input.XXX
   --     type Output_Builder is new LML.Output.Builder with private;
   --     --  The destination type builder
   function Obj_To_Text (This : From) return Text is
      Builder : Output_Builder;
   begin
      Build (This, Builder);
      return Builder.To_Text;
   end Obj_To_Text;

end LML.Convert;
