pragma Warnings (Off);
with Ada.Assertions; use Ada.Assertions;
--  Make Assert visible to children (unused at this level)
pragma Warnings (On);
with Ada.Strings.Wide_Wide_Fixed;
with Ada.Strings.UTF_Encoding.Wide_Wide_Strings;

package Lml_Tests is

   subtype Text is Wide_Wide_String;

   function Contains (Haystack, Needle : Text) return Boolean is
     (Ada.Strings.Wide_Wide_Fixed.Index (Haystack, Needle) /= 0);
   --  Convenience for asserting on builder output.

   function Str (T : Text) return String is
     (Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Encode (T));
   --  Encode wide text for inclusion in (String-typed) Assert messages.

end Lml_Tests;
