with LML.Output;

package LML.Input.Pragmas.File_IO is

   procedure From_File (Path    : String;
                        Builder : in out Output.Builder'Class);
   --  Read the Filesystem-encoded Ada source file at Path and call
   --  From_Pragmas on its content. Propagates Duplicate_Pragma on
   --  duplicate (pragma_name, key) pairs and any I/O exception from
   --  Ada.Streams.Stream_IO on file errors.

end LML.Input.Pragmas.File_IO;
