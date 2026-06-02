with LML.Input.Pragmas;
with LML.Options.Pragmas;
with LML.Output.Factory;

--  Drive the pragma parser over a range of well-formed inputs (positional,
--  named, valueless, signed numbers, and assorted whitespace/comment layouts)
--  and assert the JSON output carries the expected payloads. Mostly a smoke
--  test that none of the layouts raise, with a few content checks.
--
--  Key casing is asserted verbatim here, so the parser is run with
--  Preserve_Key_Case; the default lower-casing is covered by Pragmas_Case.

procedure Lml_Tests.Pragmas_Basic is

   LF : constant Wide_Wide_Character := Wide_Wide_Character'Val (10);

   function Run (Image : Text) return Text is
      Builder : LML.Output.Builder'Class :=
        LML.Output.Factory.Get (LML.JSON);
   begin
      LML.Input.Pragmas.From_Pragmas
        (Image, Builder, LML.Options.Pragmas.Preserve_Key_Case);
      return Builder.To_Text;
   end Run;

begin
   --  All three supported value kinds in one prelude.
   declare
      Out_Text : constant Text :=
        Run ("pragma Alire_Test (Name,        ""A test"");" & LF
             & "pragma Alire_Test (Should_Fail, True);"     & LF
             & "pragma Alire_Test (Timeout,    11.1);");
   begin
      Assert (Contains (Out_Text, "A test"),
              "supported triple: " & Str (Out_Text));
      Assert (Contains (Out_Text, "Should_Fail"),
              "supported triple: " & Str (Out_Text));
   end;

   --  Empty input parses to empty output without raising.
   declare
      Ignore : constant Text := Run ("");
   begin
      null;
   end;

   --  Real Ada-ish prelude: with clauses, a comment and a string literal that
   --  both mention "pragma", and a unit declaration that stops the scan.
   declare
      Out_Text : constant Text :=
        Run ("with Ada.Text_IO;"                            & LF
             & "--  this comment mentions pragma X (Y, Z);" & LF
             & "pragma Alire_Test (Name, ""prelude"");"     & LF
             & "procedure P is"                             & LF
             & "   S : String := ""pragma Alire_Test"
             & " (Ignored, True);"";"                       & LF
             & "begin null; end P;"                         & LF
             & "pragma Alire_Test (After_Unit, True);");
   begin
      Assert (Contains (Out_Text, "prelude"), "prelude: " & Str (Out_Text));
      Assert (not Contains (Out_Text, "After_Unit"),
              "post-unit pragma leaked: " & Str (Out_Text));
      Assert (not Contains (Out_Text, "Ignored"),
              "string-literal pragma leaked: " & Str (Out_Text));
   end;

   --  Mixed shapes: simple positional + simple named land in the output;
   --  expression-valued ones are silently dropped.
   declare
      Out_Text : constant Text :=
        Run ("pragma Alire_Test (Name, ""ok"");"          & LF
             & "pragma Alire_Test (Named => ""named"");"  & LF
             & "pragma Alire_Test (Expr, 1.0 * 60.0);"    & LF
             & "pragma Alire_Test (Cat,  ""a"" & ""b"");" & LF
             & "pragma Alire_Test (Should_Fail, False);");
   begin
      Assert (Contains (Out_Text, "ok"),    "mixed: " & Str (Out_Text));
      Assert (Contains (Out_Text, "named"), "mixed: " & Str (Out_Text));
      Assert (not Contains (Out_Text, "Expr"),
              "expression pragma leaked: " & Str (Out_Text));
   end;

   --  Signed numeric literal.
   declare
      Ignore : constant Text := Run ("pragma Alire_Test (Drift, -1.5);");
   begin
      null;
   end;

   --  Named (=>) form is accepted as equivalent to the positional one.
   declare
      Ignore : constant Text :=
        Run ("pragma Alire_Test (Name => ""named"");" & LF
             & "pragma Alire_Test (Count => 7);"      & LF
             & "pragma Alire_Test (Flag  =>  False);");
   begin
      null;
   end;

   --  Valueless form: a key with no value yields Nil, serialised as JSON null.
   declare
      Out_Text : constant Text :=
        Run ("pragma Alire_Test (Should_Fail);" & LF
             & "pragma Alire_Test (Other, 1);"  & LF
             & "pragma Alire_Test (Spaced   ) ;");
   begin
      Assert (Contains (Out_Text, "null"), "valueless: " & Str (Out_Text));
   end;

   --  Two pragmas with different names should not collide.
   declare
      Out_Text : constant Text :=
        Run ("pragma Alire_Test (Name, ""A"");" & LF
             & "pragma Other_Pragma (Tag,  ""B"");");
   begin
      Assert (Contains (Out_Text, "Alire_Test"),
              "two names: " & Str (Out_Text));
      Assert (Contains (Out_Text, "Other_Pragma"),
              "two names: " & Str (Out_Text));
   end;

   --  Whitespace variants: compact, extra spaces, tabs, multi-line bodies and
   --  comments between tokens should all parse to the same value.
   declare
      Compact  : constant Text :=
        Run ("pragma Alire_Test(Name,""compact"");");
      Spaced   : constant Text :=
        Run ("pragma   Alire_Test  (  Name  ,  ""spaced""  )  ;");
      Tabbed   : constant Text :=
        Run ("pragma Alire_Test" & Wide_Wide_Character'Val (9)
             & "(Name" & Wide_Wide_Character'Val (9)
             & ",""tabbed"");");
      Split    : constant Text :=
        Run ("pragma Alire_Test"   & LF
             & "  ( Name"          & LF
             & "  , ""multiline""" & LF
             & "  );");
      Comments : constant Text :=
        Run ("pragma Alire_Test -- the pragma name" & LF
             & "  ( Name         -- the key"        & LF
             & "  , ""annotated"""                  & LF
             & "  );");
   begin
      Assert (Contains (Compact, "compact"),    "compact: "  & Str (Compact));
      Assert (Contains (Spaced, "spaced"),      "spaced: "   & Str (Spaced));
      Assert (Contains (Tabbed, "tabbed"),      "tabbed: "   & Str (Tabbed));
      Assert (Contains (Split, "multiline"),    "split: "    & Str (Split));
      Assert (Contains (Comments, "annotated"), "comments: " & Str (Comments));
   end;
end Lml_Tests.Pragmas_Basic;
