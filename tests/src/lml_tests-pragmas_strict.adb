with LML.Input.Pragmas;
with LML.Options.Pragmas;
with LML.Output.Factory;

--  Strict mode: a well-formed strict pragma parses normally, while a malformed
--  one (an expression value) raises Invalid_Pragma_Syntax instead of being
--  silently dropped.

procedure Lml_Tests.Pragmas_Strict is

   Strict : constant LML.Options.Pragmas.Input_Options :=
     LML.Options.Pragmas.Strict_On ("Alire_Test");

begin
   --  Well-formed strict pragma: must parse and produce output.
   declare
      Builder : LML.Output.Builder'Class := LML.Output.Factory.Get (LML.JSON);
   begin
      LML.Input.Pragmas.From_Pragmas
        ("pragma Alire_Test (Name, ""strict_ok"");", Builder, Strict);
      Assert (Contains (Builder.To_Text, "strict_ok"),
              "strict well-formed: " & Str (Builder.To_Text));
   end;

   --  Malformed strict pragma: must raise Invalid_Pragma_Syntax.
   declare
      Builder : LML.Output.Builder'Class := LML.Output.Factory.Get (LML.JSON);
   begin
      LML.Input.Pragmas.From_Pragmas
        ("pragma Alire_Test (Timeout, 1.0 * 60.0);", Builder, Strict);
      raise Program_Error with "expected Invalid_Pragma_Syntax, none raised";
   exception
      when LML.Invalid_Pragma_Syntax =>
         null; -- expected
   end;
end Lml_Tests.Pragmas_Strict;
