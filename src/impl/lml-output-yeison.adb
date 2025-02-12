with LML.Output.JSON.Export;

package body LML.Output.Yeison is

   ---------------
   -- To_Yeison --
   ---------------

   function To_Yeison (This : Builder) return Yeison.Any
   is (JSON.Export.To_Yeison (JSON.Builder (This)));

end LML.Output.Yeison;
