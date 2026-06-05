with LML;
with LML.Schemas;

package Lml_Validate_App is

   --  Core logic of the lml_validate tool: load a data file and a schema
   --  file (each in any format LML understands, chosen from the file name
   --  extension) and validate the former against the latter. The thin main
   --  procedure adds only command-line parsing and process reporting.

   package Yeison renames LML.Yeison;
   package Schemas renames LML.Schemas;

   Bad_Extension : exception;
   --  A file name carries no extension, or one we do not map to a format.

   function Format_Of (Path : String) return LML.Formats;
   --  Infer the markup format from Path's extension (case-insensitive):
   --  .json, .yaml/.yml, .toml, or .ads/.adb (Ada pragmas). Raises
   --  Bad_Extension for anything else.

   function Load (Path : String) return Yeison.Any;
   --  Read the UTF-8 file at Path and parse it with the format given by
   --  Format_Of. Propagates Bad_Extension, any I/O exception on file
   --  errors, and whatever the parser raises on malformed input.

   function Validate (Data_Path, Schema_Path : String) return Schemas.Result;
   --  Load both files and validate the data against the schema. May raise
   --  the exceptions documented for Load, as well as LML.Unsupported_Error
   --  when the schema uses a feature the validator cannot honour.

end Lml_Validate_App;
