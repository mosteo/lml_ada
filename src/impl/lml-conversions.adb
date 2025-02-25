package body LML.Conversions is

   -----------------
   -- Obj_To_Text --
   -----------------

   function Obj_To_Text (This : From) return Text is
      Builder : Output_Builder;
   begin
      Build (This, Builder);
      return Builder.To_Text;
   end Obj_To_Text;

end LML.Conversions;
