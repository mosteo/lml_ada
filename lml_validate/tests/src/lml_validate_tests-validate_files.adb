with Ada.Directories;
with Ada.Text_IO;

with Lml_Validate_App;

--  End-to-end check of the loading-and-validating path: write real files to
--  disk, validate the data against the schema, and confirm both the valid
--  and invalid verdicts.

procedure Lml_Validate_Tests.Validate_Files is

   use Ada.Text_IO;

   procedure Write (Path, Content : String) is
      File : File_Type;
   begin
      Create (File, Out_File, Path);
      Put (File, Content);
      Close (File);
   end Write;

   Schema_Path : constant String := "lvt_schema.json";
   Good_Path   : constant String := "lvt_good.json";
   Bad_Path    : constant String := "lvt_bad.json";

begin
   Write (Schema_Path,
          "{""type"": ""object"","
          & """required"": [""age""],"
          & """properties"": {""age"": "
          & "{""type"": ""integer"", ""minimum"": 0}}}");
   Write (Good_Path, "{""age"": 36}");
   Write (Bad_Path,  "{""age"": -1}");

   pragma Assert
     (Lml_Validate_App.Validate (Good_Path, Schema_Path).Is_Valid,
      "data within the schema should validate");

   pragma Assert
     (not Lml_Validate_App.Validate (Bad_Path, Schema_Path).Is_Valid,
      "negative age should fail the minimum constraint");

   Ada.Directories.Delete_File (Schema_Path);
   Ada.Directories.Delete_File (Good_Path);
   Ada.Directories.Delete_File (Bad_Path);
end Lml_Validate_Tests.Validate_Files;
