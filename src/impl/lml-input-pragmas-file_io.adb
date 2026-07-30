with Ada.Strings.Wide_Wide_Unbounded;
with Ada.Wide_Wide_Text_IO;

package body LML.Input.Pragmas.File_IO is

   ---------------
   -- From_File --
   ---------------

   procedure From_File (Path    : String;
                        Builder : in out Output.Builder'Class;
                        Unit    : out Ada_Unit;
                        Options : LML.Options.Any'Class :=
                          LML.Options.No_Options)
   is
      use Ada.Strings.Wide_Wide_Unbounded;
      use Ada.Wide_Wide_Text_IO;

      LF     : constant Wide_Wide_Character := Wide_Wide_Character'Val (10);
      File   : File_Type;
      Buffer : Unbounded_Wide_Wide_String;
   begin
      Open (File, In_File, Path);
      while not End_Of_File (File) loop
         Append (Buffer, Get_Line (File));
         Append (Buffer, LF);
      end loop;
      Close (File);
      From_Pragmas (To_Wide_Wide_String (Buffer), Builder, Unit, Options);
   end From_File;

   ---------------
   -- From_File --
   ---------------

   procedure From_File (Path    : String;
                        Builder : in out Output.Builder'Class;
                        Options : LML.Options.Any'Class :=
                          LML.Options.No_Options)
   is
      Ignored : Ada_Unit;
   begin
      From_File (Path, Builder, Ignored, Options);
   end From_File;

end LML.Input.Pragmas.File_IO;
