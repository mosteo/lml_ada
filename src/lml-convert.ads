with LML.Output;

package LML.Convert with Preelaborate is

   type Reimager is access function (Image : Text) return Output.Builder'Class;

   function Factory (From, Into : Formats) return Reimager with
     Pre => From /= Into;
   --  Returns null for unavailable conversions. At the moment, it always
   --  return null.

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

   -------------
   -- Factory --
   -------------

   function Factory (From, Into : Formats) return Reimager is (null);

end LML.Convert;
