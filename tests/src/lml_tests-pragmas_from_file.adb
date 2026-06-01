with Ada.Directories;
with Ada.Text_IO;

with LML.Input.Pragmas.File_IO;
with LML.Output.Factory;

--  Exercise the From_File path. To stay independent of the test runner's
--  working directory, the fixture is written to a temporary file at runtime
--  (a verbatim copy of test/data/pragma_sample.ada), read back, then removed.

procedure Lml_Tests.Pragmas_From_File is

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
      begin
         Ada.Directories.Delete_File (Path);
         Assert (Contains (Out_Text, "hello from file"),
                 "missing file pragma: " & Str (Out_Text));
         Assert (Contains (Out_Text, "another pragma"),
                 "missing other pragma: " & Str (Out_Text));
         Assert (not Contains (Out_Text, "after unit decl"),
                 "post-unit pragma leaked: " & Str (Out_Text));
      end;
   exception
      when others =>
         if Ada.Directories.Exists (Path) then
            Ada.Directories.Delete_File (Path);
         end if;
         raise;
   end;
end Lml_Tests.Pragmas_From_File;
