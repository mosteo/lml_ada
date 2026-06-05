with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with LML;
with LML.Input.YAML.Initialization;

with Lml_Tests.Support;

--  Integration test against the real sample schema, parsed from YAML into a
--  Yeison value via LML.From_Text:
--
--    * every document under the schema's own `examples:` must validate;
--    * crafted documents must be rejected: an unknown top-level pragma
--      (additionalProperties:false), Timeout given as a string (type), and
--      the conditional rule -- Auxiliary_File:true together with another key
--      fails maxProperties:1, while Auxiliary_File:true alone passes.

procedure Lml_Tests.Schema_Sample_Pragmas is

   use Lml_Tests.Support;

   function Read_File (Name : String) return Text is
      use Ada.Text_IO;
      use Ada.Strings.Unbounded;
      File : File_Type;
      Buf  : Unbounded_String;
   begin
      Open (File, In_File, Name);
      while not End_Of_File (File) loop
         Append (Buf, Get_Line (File));
         Append (Buf, ASCII.LF);
      end loop;
      Close (File);
      return LML.Decode (To_String (Buf));
   end Read_File;

   function Find_Schema return String is
      --  The Alire runner's working directory is the test crate root, so
      --  the repo's schemas/ lives one or two levels up; try a few.
      Rel : constant String := "schemas/test-pragmas.yaml";
   begin
      if Ada.Directories.Exists (Rel) then
         return Rel;
      elsif Ada.Directories.Exists ("../" & Rel) then
         return "../" & Rel;
      elsif Ada.Directories.Exists ("../../" & Rel) then
         return "../../" & Rel;
      else
         raise Program_Error with "sample schema not found: " & Rel;
      end if;
   end Find_Schema;

   Schema : Yeison.Any;

begin
   LML.Input.YAML.Initialization.Initialize;
   Schema := LML.From_Text (Read_File (Find_Schema), LML.YAML);

   --  Every embedded example must validate against the schema.
   declare
      Examples : constant Yeison.Any := At_Key (Schema, "examples");
   begin
      for Ex of Examples loop
         Assert_Valid (Ex, Schema, "schema's own example must validate");
      end loop;
   end;

   --  Unknown top-level pragma: rejected by additionalProperties:false.
   declare
      D : Yeison.Any := Y_Map;
   begin
      Put (D, "Unknown_Pragma", Y_Map);
      Assert_Invalid (D, Schema,
                      "/Unknown_Pragma: additional property not allowed",
                      "unknown top-level pragma must be rejected");
   end;

   --  Timeout as a string: rejected by type:number.
   declare
      D     : Yeison.Any := Y_Map;
      Inner : Yeison.Any := Y_Map;
   begin
      Put (Inner, "Timeout", Y_Str ("soon"));
      Put (D, "Alire_Test", Inner);
      Assert_Invalid (D, Schema,
                      "/Alire_Test/Timeout: expected number, found string",
                      "Timeout as a string must be rejected");
   end;

   --  Auxiliary_File:true with another key: fails the then/maxProperties rule.
   declare
      D     : Yeison.Any := Y_Map;
      Inner : Yeison.Any := Y_Map;
   begin
      Put (Inner, "Auxiliary_File", Y_Bool (True));
      Put (Inner, "Name", Y_Str ("x"));
      Put (D, "Alire_Test", Inner);
      Assert_Invalid (D, Schema,
                      "/Alire_Test: object has more than maxProperties",
                      "Auxiliary_File with extra key must fail maxProperties");
   end;

   --  Auxiliary_File:true alone: valid.
   declare
      D     : Yeison.Any := Y_Map;
      Inner : Yeison.Any := Y_Map;
   begin
      Put (Inner, "Auxiliary_File", Y_Bool (True));
      Put (D, "Alire_Test", Inner);
      Assert_Valid (D, Schema, "Auxiliary_File alone must be valid");
   end;
end Lml_Tests.Schema_Sample_Pragmas;
