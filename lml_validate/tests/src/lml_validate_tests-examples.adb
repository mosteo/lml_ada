with Ada.Directories;

with LML;

with Lml_Validate_App;

--  Every file under examples/valid must validate against the sample schema,
--  and every file under examples/invalid must be rejected. This keeps the
--  shipped examples honest as both the validator and the schema evolve.

procedure Lml_Validate_Tests.Examples is

   package Dirs renames Ada.Directories;

   --  The Alire runner's working directory is the test crate root, so the
   --  repository's schemas/ and examples/ live a couple of levels up; probe
   --  a few prefixes and reuse the one that resolves.

   function Repo_Prefix return String is
      Probe : constant String := "schemas/test-pragmas.yaml";
   begin
      if Dirs.Exists (Probe) then
         return "";
      elsif Dirs.Exists ("../" & Probe) then
         return "../";
      elsif Dirs.Exists ("../../" & Probe) then
         return "../../";
      elsif Dirs.Exists ("../../../" & Probe) then
         return "../../../";
      else
         raise Program_Error with "cannot locate " & Probe;
      end if;
   end Repo_Prefix;

   Prefix      : constant String := Repo_Prefix;
   Schema_Path : constant String := Prefix & "schemas/test-pragmas.yaml";
   Examples    : constant String := Prefix & "lml_validate/examples";

   --  Validate every data file in Examples/Subdir and check its verdict
   --  against Expect_Valid. Files without a recognised extension (e.g. a
   --  README) are skipped.

   procedure Check_Dir (Subdir : String; Expect_Valid : Boolean) is
      Dir    : constant String := Dirs.Compose (Examples, Subdir);
      Search : Dirs.Search_Type;
      Item   : Dirs.Directory_Entry_Type;
      Count  : Natural := 0;
   begin
      Dirs.Start_Search
        (Search    => Search,
         Directory => Dir,
         Pattern   => "*",
         Filter    => (Dirs.Ordinary_File => True, others => False));

      while Dirs.More_Entries (Search) loop
         Dirs.Get_Next_Entry (Search, Item);
         declare
            Name : constant String := Dirs.Simple_Name (Item);
            Path : constant String := Dirs.Full_Name (Item);
         begin
            declare
               Result : constant Lml_Validate_App.Schemas.Result :=
                 Lml_Validate_App.Validate (Path, Schema_Path);
            begin
               Count := Count + 1;
               if Expect_Valid then
                  Assert (Result.Is_Valid,
                          Subdir & "/" & Name
                          & ": expected VALID but got: "
                          & LML.Encode (Result.Error));
               else
                  Assert (not Result.Is_Valid,
                          Subdir & "/" & Name
                          & ": expected INVALID but it validated");
               end if;
            exception
               when Lml_Validate_App.Bad_Extension =>
                  null;  --  not a data file; ignore
            end;
         end;
      end loop;
      Dirs.End_Search (Search);

      Assert (Count > 0, "no example files found in " & Dir);
   end Check_Dir;

begin
   Check_Dir ("valid",   Expect_Valid => True);
   Check_Dir ("invalid", Expect_Valid => False);
end Lml_Validate_Tests.Examples;
