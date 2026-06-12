with Yeison_12;

package LML.Options.Pragmas with Preelaborate is

   package Yeison renames Yeison_12;

   type Input_Options is new Options.Any with record
      Strict : Yeison.Vec := Yeison.Empty_Vec;
      --  Pragma names (case-insensitive) that must parse successfully.
      --  A parse failure for a listed name raises
      --  LML.Invalid_Pragma_Syntax. Ignored by non-pragma formats.

      Lower_Case_Keys : Boolean := True;
      --  When set, the identifiers used as keys (the pragma name and each
      --  pragma key) are normalized to lower case as they are recorded,
      --  mirroring Ada's case-insensitive identifiers. Values are never
      --  touched. Lets callers look keys up without worrying about source
      --  casing.
   end record;

   function Strict_On (Pragma_Name : String) return Input_Options;
   --  Return options with the given pragma name added to Strict, as a
   --  convenience for the common case of a single strict pragma.

   function No_Input_Options return Input_Options is
     (Any with Strict => Yeison.Empty_Vec, Lower_Case_Keys => True);
   --  Function to remain preelaborable

   function Preserve_Key_Case return Input_Options is
     (Any with Strict => Yeison.Empty_Vec, Lower_Case_Keys => False);
   --  Options that keep identifier keys exactly as written, disabling the
   --  default lower-case normalization.

end LML.Options.Pragmas;
