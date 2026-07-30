with Ada.Directories;
with Ada.Text_IO;

with LML;
with LML.Input.Pragmas.File_IO;
with LML.Output.Factory;

with Lml_Tests.Support;

--  Exercise the From_File path. To stay independent of the test runner's
--  working directory, the fixture is written to a temporary file at runtime
--  (a verbatim copy of test/data/pragma_sample.ada), read back, then removed.
--  Default options apply, so identifier keys are lower-cased.

procedure Lml_Tests.Pragmas_From_File is

   use Lml_Tests.Support;

   Path : constant String := "lml_tests_pragma_sample.ada";

   Fixture : constant String :=
     "--  pragma_sample.ada: static fixture for From_File tests."   & ASCII.LF
     & "--"                                                         & ASCII.LF
     & "--  A comment containing pragma Sample_Pragma (Ignored, ""yes"")"
     & " should not"                                                & ASCII.LF
     & "--  be parsed."                                             & ASCII.LF
     & ""                                                           & ASCII.LF
     & "with Ada.Text_IO;"                                          & ASCII.LF
     & ""                                                           & ASCII.LF
     & "pragma Sample_Pragma (Name,    ""hello from file"");"       & ASCII.LF
     & "pragma Sample_Pragma (Count,   42);"                        & ASCII.LF
     & "pragma Sample_Pragma (Ratio,   1.5);"                       & ASCII.LF
     & "pragma Sample_Pragma (Enabled, True);"                      & ASCII.LF
     & "pragma Other_Pragma  (Tag,     ""another pragma"");"        & ASCII.LF
     & "pragma Empty_Pragma;"                                       & ASCII.LF
     & ""                                                           & ASCII.LF
     & "procedure Sample_Body is"                                   & ASCII.LF
     & "   pragma Sample_Pragma (Ignored, ""after unit decl"");"    & ASCII.LF
     & "begin"                                                      & ASCII.LF
     & "   null;"                                                   & ASCII.LF
     & "end Sample_Body;"                                           & ASCII.LF;

   procedure Write_Fixture is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (File, Fixture);
      Ada.Text_IO.Close (File);
   end Write_Fixture;

begin
   Write_Fixture;

   declare
      Builder : LML.Output.Builder'Class := LML.Output.Factory.Get (LML.JSON);
   begin
      LML.Input.Pragmas.File_IO.From_File (Path, Builder);

      declare
         Out_Text : constant Text := Builder.To_Text;
         Parsed   : constant Yeison.Any := LML.From_Text (Out_Text, LML.JSON);

         Expected : Yeison.Any := Y_Map;
         Sample   : Yeison.Any := Y_Map;
         Other    : Yeison.Any := Y_Map;
         Empty    : constant Yeison.Any := Y_Map;
      begin
         Ada.Directories.Delete_File (Path);

         --  Full structure, with inferred types and lower-cased keys. This
         --  subsumes the "values present" checks and additionally pins down
         --  that the post-unit-decl pragma and the in-comment pragma did NOT
         --  leak (they are simply absent from the expected structure).
         Put (Sample, "name",    Y_Str ("hello from file"));
         Put (Sample, "count",   Y_Int (42));
         Put (Sample, "ratio",   Y_Real (1.5));
         Put (Sample, "enabled", Y_Bool (True));
         Put (Other,  "tag",     Y_Str ("another pragma"));
         Put (Expected, "sample_pragma", Sample);
         Put (Expected, "other_pragma",  Other);
         Put (Expected, "empty_pragma",  Empty);

         Assert_Equal (Parsed, Expected, "pragmas from file");
      end;
   exception
      when others =>
         if Ada.Directories.Exists (Path) then
            Ada.Directories.Delete_File (Path);
         end if;
         raise;
   end;
end Lml_Tests.Pragmas_From_File;
