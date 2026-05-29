with Yeison_12;

package LML.Options.Pragmas with Preelaborate is

   package Yeison renames Yeison_12;

   type Input_Options is new Any with record
      Strict : Yeison.Vec := Yeison.Empty_Vec;
      --  Pragma names (case-insensitive) that must parse successfully.
      --  A parse failure for a listed name raises
      --  LML.Invalid_Pragma_Syntax. Ignored by non-pragma formats.
   end record;

   function Strict_On (Pragma_Name : String) return Input_Options;
   --  Return options with the given pragma name added to Strict, as a
   --  convenience for the common case of a single strict pragma.

   function No_Input_Options return Input_Options is
     (Any with Strict => Yeison.Empty_Vec);
   --  Function to remain preelaborable

end LML.Options.Pragmas;
