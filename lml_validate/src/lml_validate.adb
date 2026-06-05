with Ada.Command_Line;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Text_IO;

with LML;

with Lml_Validate_App;

--  Command-line entry point: validate a data file against a schema file.
--
--    lml_validate <data-file> <schema-file>
--
--  Both file formats are inferred from their extensions. Exit status is
--  Success when the data is valid, Failure otherwise (invalid data, bad
--  usage, I/O error, malformed input, or an unsupported schema feature).

procedure Lml_Validate is

   use Ada.Command_Line;

   package App renames Lml_Validate_App;

   procedure Put_Error (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,
                            "lml_validate: " & Message);
   end Put_Error;

begin
   if Argument_Count /= 2 then
      Put_Error ("usage: lml_validate <data-file> <schema-file>");
      Set_Exit_Status (Failure);
      return;
   end if;

   declare
      Result : constant App.Schemas.Result :=
        App.Validate (Data_Path   => Argument (1),
                      Schema_Path => Argument (2));
   begin
      if Result.Is_Valid then
         Ada.Text_IO.Put_Line ("VALID");
         Set_Exit_Status (Success);
      else
         Put_Error ("INVALID: " & LML.Encode (Result.Error));
         Set_Exit_Status (Failure);
      end if;
   end;

exception
   when App.Bad_Extension =>
      Put_Error ("unrecognised file extension; expected one of "
                 & ".json .yaml .yml .toml .ads .adb");
      Set_Exit_Status (Failure);

   when Ada.IO_Exceptions.Name_Error =>
      Put_Error ("no such file");
      Set_Exit_Status (Failure);

   when E : LML.Unsupported_Error =>
      Put_Error ("unsupported schema feature: "
                 & Ada.Exceptions.Exception_Message (E));
      Set_Exit_Status (Failure);

   when E : others =>
      Put_Error ("could not validate: "
                 & Ada.Exceptions.Exception_Message (E));
      Set_Exit_Status (Failure);
end Lml_Validate;
