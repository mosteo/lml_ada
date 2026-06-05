package LML.Output.JSON.Export with Preelaborate is

   function To_Yeison (This : Builder) return Yeison.Any;

private

   function To_Yeison (This : Builder) return Yeison.Any is (This.Root_Node);

end LML.Output.JSON.Export;
