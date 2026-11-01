with JSON.Types;

with LML.Options;
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

   function From_UTF_8 (Image : Text_UTF8) return Yeison.Any;
   --  As From_String, for text that is already UTF-8. Converting it to Text
   --  and back needs temporary copies on the stack, four times its size for
   --  Text, which may exhaust the stack with megabytes of input.

   procedure From_JSON (This    : Types.JSON_Value;
                        Builder : in out Output.Builder'Class);

   procedure From_JSON (Image   : Text;
                        Builder : in out Output.Builder'Class;
                        Options : LML.Options.Any'Class :=
                          LML.Options.No_Options);

end LML.Input.JSON;
