with Ada.Strings.UTF_Encoding.Wide_Wide_Strings;

package LML with Preelaborate is

   subtype Text is Wide_Wide_String;

   subtype Text_UTF8 is String;

   function Encode (T : Text; Output_BOM : Boolean  := False) return Text_UTF8
                    renames Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Encode;

   function Decode (T : Text_UTF8) return Text
                    renames Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Decode;

end LML;
