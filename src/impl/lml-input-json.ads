with JSON.Types;

with LML.Output;

with Yeison_12;

package LML.Input.JSON with Preelaborate is

   package J renames Standard.JSON;
   package Yeison renames Yeison_12;

   package Types is new J.Types (Yeison.Big_Int, Yeison.Big_Real);

   function From_String (Image : Text) return Yeison.Any;
   --  We cannot readily use Types.JSON_Value because that type is tied to a
   --  limited parser, so we convert it internally to Yeison.Any. If you want
   --  to avoid this extra copy, you can use From_JSON or Build below directly
   --  and the resulting populated Builder to directly get your desired
   --  output.

   procedure From_JSON (This    : Types.JSON_Value;
                        Builder : in out Output.Builder'Class);

   procedure From_JSON (Image   : Text;
                        Builder : in out Output.Builder'Class);

end LML.Input.JSON;
