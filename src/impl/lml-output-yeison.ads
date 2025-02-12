with LML.Output.JSON;

with Yeison_12;

package LML.Output.Yeison with Preelaborate is

   package Yeison renames Yeison_12;

   type Builder is new JSON.Builder with null record;

   function To_Yeison (This : Builder) return Yeison.Any;

end LML.Output.Yeison;
