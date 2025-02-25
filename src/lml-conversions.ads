with LML.Output;

package LML.Conversions with Preelaborate is

private

   generic
      type From is private;
      with procedure Build (This    : From;
                            Builder : in out Output.Builder'Class);
      --  Some procedure in LML.Input.XXX
      type Output_Builder is new LML.Output.Builder with private;
      --  The destination type builder
   function Obj_To_Text (This : From) return Text;
   --  Direct type-to-type conversion (no images involved)

end LML.Conversions;
