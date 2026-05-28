package LML.Options with Preelaborate is

   --  Abstract options class that each input/output format can subclass for
   --  their own input/output loaders/builders.

   type Any is abstract tagged null record;

   type Default_No_Options is new Any with null record;

   No_Options : constant Default_No_Options := (Any with null record);

end LML.Options;