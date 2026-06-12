package body LML.Options.Pragmas is

   ---------------
   -- Strict_On --
   ---------------

   function Strict_On (Pragma_Name : String) return Input_Options is
   begin
      return (Any with
              Strict => Yeison.Operators.To_Vec
                ((1 => Yeison.Make.Str (LML.Decode (Pragma_Name)))),
              Lower_Case_Keys => True);
   end Strict_On;

end LML.Options.Pragmas;
