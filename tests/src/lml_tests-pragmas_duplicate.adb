with LML.Input.Pragmas;
with LML.Output.Factory;

--  A duplicate (pragma_name, key) pair must raise Duplicate_Pragma.

procedure Lml_Tests.Pragmas_Duplicate is

   LF : constant Wide_Wide_Character := Wide_Wide_Character'Val (10);

   Builder : LML.Output.Builder'Class := LML.Output.Factory.Get (LML.JSON);
begin
   LML.Input.Pragmas.From_Pragmas
     ("pragma Alire_Test (Name, ""first"");" & LF
      & "pragma Alire_Test (Name, ""second"");",
      Builder);
   raise Program_Error with "expected Duplicate_Pragma, none raised";
exception
   when LML.Input.Pragmas.Duplicate_Pragma =>
      null; -- expected
end Lml_Tests.Pragmas_Duplicate;
