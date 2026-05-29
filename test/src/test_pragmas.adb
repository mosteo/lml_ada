with Ada.Exceptions;
with Ada.Wide_Wide_Text_IO; use Ada.Wide_Wide_Text_IO;

with LML;
with LML.Input.Pragmas;
with LML.Input.Pragmas.File_IO;
with LML.Output.Factory;
with LML.Options.Pragmas;

package body Test_Pragmas is

   subtype Text is Wide_Wide_String;

   LF : constant Wide_Wide_Character := Wide_Wide_Character'Val (10);

   procedure Show (Title : Text; Image : Text) is
      Builder : LML.Output.Builder'Class :=
        LML.Output.Factory.Get (LML.JSON);
   begin
      LML.Input.Pragmas.From_Pragmas (Image, Builder);
      Put_Line ("*** " & Title & " ***");
      Put_Line (Builder.To_Text);
   end Show;

   ---------
   -- Run --
   ---------

   procedure Run is
   begin
      Put_Line ("PRAGMA INPUT TESTS");

      --  All three supported value kinds in one prelude.
      Show ("supported triple",
            "pragma Alire_Test (Name,        ""A test"");"  & LF
            & "pragma Alire_Test (Should_Fail, True);"      & LF
            & "pragma Alire_Test (Timeout,    11.1);");

      --  Empty input.
      Show ("empty input", "");

      --  Real Ada-ish prelude: with clauses, a comment containing the
      --  word "pragma", a string literal containing it too, and then
      --  the unit declaration that must stop our scan.
      Show ("prelude then procedure",
            "with Ada.Text_IO;"                            & LF
            & "--  this comment mentions pragma X (Y, Z);" & LF
            & "pragma Alire_Test (Name, ""prelude"");"    & LF
            & "procedure P is"                             & LF
            & "   S : String := ""pragma Alire_Test"
            & " (Ignored, True);"";"                      & LF
            & "begin null; end P;"                         & LF
            & "pragma Alire_Test (After_Unit, True);");

      --  Mixed shapes: simple positional + simple named land in the
      --  output; expression-valued ones (multiplication, concatenation)
      --  are silently dropped.
      Show ("mixed supported and unsupported",
            "pragma Alire_Test (Name, ""ok"");"            & LF
            & "pragma Alire_Test (Named => ""named"");"    & LF
            & "pragma Alire_Test (Expr, 1.0 * 60.0);"      & LF
            & "pragma Alire_Test (Cat,  ""a"" & ""b"");"   & LF
            & "pragma Alire_Test (Should_Fail, False);");

      --  Signed numeric literal.
      Show ("signed real", "pragma Alire_Test (Drift, -1.5);");
      --  Named (=>) form is accepted as equivalent to the positional one.
      Show ("named form",
            "pragma Alire_Test (Name => ""named"");"       & LF
            & "pragma Alire_Test (Count => 7);"            & LF
            & "pragma Alire_Test (Flag  =>  False);");

      --  Valueless form: a key with no value yields Nil, serialised as
      --  JSON null.
      Show ("valueless yields null",
            "pragma Alire_Test (Should_Fail);"             & LF
            & "pragma Alire_Test (Other, 1);"              & LF
            & "pragma Alire_Test (Spaced   ) ;");

      --  Two pragmas with different names should not collide.
      Show ("two distinct pragma names",
            "pragma Alire_Test (Name, ""A"");"             & LF
            & "pragma Other_Pragma (Tag,  ""B"");");

      --  Whitespace variants: tabs, multiple spaces, and the pragma
      --  body split across lines should all parse identically.
      Show ("compact (no extra spaces)",
            "pragma Alire_Test(Name,""compact"");");

      Show ("extra spaces around punctuation",
            "pragma   Alire_Test  (  Name  ,  ""spaced""  )  ;");

      Show ("tab-separated",
            "pragma Alire_Test" & Wide_Wide_Character'Val (9)
            & "(Name" & Wide_Wide_Character'Val (9)
            & ",""tabbed"");");

      Show ("split across lines",
            "pragma Alire_Test"    & LF
            & "  ( Name"           & LF
            & "  , ""multiline"""  & LF
            & "  );");

      Show ("comment between tokens",
            "pragma Alire_Test -- the pragma name" & LF
            & "  ( Name         -- the key"        & LF
            & "  , ""annotated""" & LF
            & "  );");

      --  Duplicate (name, key) must raise Duplicate_Pragma.
      declare
         Builder : LML.Output.Builder'Class :=
           LML.Output.Factory.Get (LML.JSON);
      begin
         LML.Input.Pragmas.From_Pragmas
           ("pragma Alire_Test (Name, ""first"");" & LF
            & "pragma Alire_Test (Name, ""second"");",
            Builder);
         Put_Line ("*** duplicate key (expected to RAISE) ***");
         Put_Line ("FAIL: no exception was raised");
         Put_Line (Builder.To_Text);
      exception
         when E : LML.Input.Pragmas.Duplicate_Pragma =>
            Put_Line ("*** duplicate key ***");
            Put_Line ("got expected Duplicate_Pragma: "
                      & LML.Decode
                        (Ada.Exceptions.Exception_Message (E)));
      end;

      --  Strict mode: a well-formed strict pragma parses normally.
      declare
         Builder : LML.Output.Builder'Class :=
           LML.Output.Factory.Get (LML.JSON);
      begin
         LML.Input.Pragmas.From_Pragmas
           ("pragma Alire_Test (Name, ""strict_ok"");",
            Builder, LML.Options.Pragmas.Strict_On ("Alire_Test"));
         Put_Line ("*** strict (well-formed) ***");
         Put_Line (Builder.To_Text);
      end;

      --  Strict mode: a malformed strict pragma raises Invalid_Pragma_Syntax.
      declare
         Builder : LML.Output.Builder'Class :=
           LML.Output.Factory.Get (LML.JSON);
      begin
         LML.Input.Pragmas.From_Pragmas
           ("pragma Alire_Test (Timeout, 1.0 * 60.0);",
            Builder, LML.Options.Pragmas.Strict_On ("Alire_Test"));
         Put_Line ("*** strict (malformed) (expected to RAISE) ***");
         Put_Line ("FAIL: no exception was raised");
         Put_Line (Builder.To_Text);
      exception
         when E : LML.Invalid_Pragma_Syntax =>
            Put_Line ("*** strict (malformed) ***");
            Put_Line ("got expected Invalid_Pragma_Syntax: "
                      & LML.Decode
                        (Ada.Exceptions.Exception_Message (E)));
      end;

      --  File I/O: read a static fixture and verify the same pragmas
      --  land in the output (comments and post-unit pragmas excluded).
      declare
         Builder : LML.Output.Builder'Class :=
           LML.Output.Factory.Get (LML.JSON);
      begin
         LML.Input.Pragmas.File_IO.From_File
           ("data/pragma_sample.ada", Builder);
         Put_Line ("*** From_File ***");
         Put_Line (Builder.To_Text);
      end;
   end Run;

end Test_Pragmas;
