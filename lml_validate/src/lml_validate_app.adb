with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with LML.Input.YAML.Initialization;

package body Lml_Validate_App is

   ---------------
   -- Format_Of --
   ---------------

   function Format_Of (Path : String) return LML.Formats is
      use Ada.Characters.Handling;
      Ext : constant String := To_Lower (Ada.Directories.Extension (Path));
   begin
      if Ext = "json" then
         return LML.JSON;
      elsif Ext = "yaml" or else Ext = "yml" then
         return LML.YAML;
      elsif Ext = "toml" then
         return LML.TOML;
      elsif Ext = "ads" or else Ext = "adb" then
         return LML.Pragmas;
      else
         raise Bad_Extension with
           "cannot determine format from file name: " & Path;
      end if;
   end Format_Of;

   ---------------
   -- Read_File --
   ---------------

   function Read_File (Path : String) return LML.Text is
      use Ada.Strings.Unbounded;
      use Ada.Text_IO;

      LF     : constant Character := Character'Val (10);
      File   : File_Type;
      Buffer : Unbounded_String;
   begin
      --  Read raw bytes line by line (each Character is one byte), then
      --  decode the accumulated UTF-8 into the wide-wide Text the parsers
      --  expect. Get_Line drops the newline, so we restore it.
      Open (File, In_File, Path);
      while not End_Of_File (File) loop
         Append (Buffer, Get_Line (File));
         Append (Buffer, LF);
      end loop;
      Close (File);
      return LML.Decode (To_String (Buffer));
   end Read_File;

   ----------
   -- Load --
   ----------

   function Load (Path : String) return Yeison.Any is
      use type LML.Formats;
      Format : constant LML.Formats := Format_Of (Path);
   begin
      --  YAML input is reached through a hook the client must arm once;
      --  Initialize only assigns an access value, so it is idempotent.
      if Format = LML.YAML then
         LML.Input.YAML.Initialization.Initialize;
      end if;
      return LML.From_Text (Read_File (Path), Format);
   end Load;

   --------------
   -- Validate --
   --------------

   function Validate (Data_Path, Schema_Path : String) return Schemas.Result is
     (Schemas.Validate (Data   => Load (Data_Path),
                        Schema => Load (Schema_Path)));

end Lml_Validate_App;
