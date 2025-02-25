with Ada.Strings.UTF_Encoding.Wide_Wide_Strings;

with Yeison_12;

package LML with Preelaborate is

   package Yeison renames Yeison_12;

   type Formats is (JSON, TOML, YAML);

   subtype Scalar       is Yeison.Scalar;
   subtype Scalar_Kinds is Yeison.Scalar_Kinds;

   package Scalars renames Yeison.Scalars;

   subtype Text is Wide_Wide_String;

   subtype Text_UTF8 is String;

   function Encode (T : Text; Output_BOM : Boolean  := False) return Text_UTF8
                    renames Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Encode;

   function Decode (T : Text_UTF8) return Text
                    renames Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Decode;

   --  Yeison can be used as a hub for conversions, if one is not constructing
   --  the data structures from scratch with LML.Input or LML.Output. Check
   --  LML.Convert.* nonetheless for direct conversions.

   function From_Text (Image  : Text;
                       Format : Formats)
                       return Yeison.Any
     with Pre => Format in JSON | TOML; -- Other formats currently unsupported

   function To_Text (This   : Yeison.Any;
                     Format : Formats)
                     return Text;

   --  See LML.Output.Build too

end LML;
