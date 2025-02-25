with JSON.Types;

with LML.Output;

with Yeison_12;

package LML.Input.JSON with Preelaborate is

   package J renames Standard.JSON;
   package Yeison renames Yeison_12;

   package Types is new J.Types (Yeison.Big_Int, Yeison.Big_Real);
   subtype JSON_Value is Types.JSON_Value;

   function From_String (Image : Text) return JSON_Value;

   procedure From_JSON (This    : JSON_Value;
                        Builder : in out Output.Builder'Class);

end LML.Input.JSON;
