with LML.Options;
with LML.Output;

package LML.Input.Pragmas.File_IO is

   procedure From_File (Path    : String;
                        Builder : in out Output.Builder'Class;
                        Options : LML.Options.Any'Class :=
                          LML.Options.No_Options);
   --  Read the Filesystem-encoded Ada source file at Path and call
   --  From_Pragmas on its content. Propagates Duplicate_Pragma on
   --  duplicate (pragma_name, key) pairs, Invalid_Pragma_Syntax when
   --  a strict pragma cannot be parsed, and any I/O exception from
   --  Ada.Streams.Stream_IO on file errors.

   procedure From_File (Path    : String;
                        Builder : in out Output.Builder'Class;
                        Unit    : out Ada_Unit;
                        Options : LML.Options.Any'Class :=
                          LML.Options.No_Options);
   --  As above, but also report the kind of unit the file declares (see
   --  From_Pragmas).

end LML.Input.Pragmas.File_IO;
