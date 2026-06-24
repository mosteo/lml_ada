with LML;
with LML.Input.Pragmas;
with LML.Options.Pragmas;
with LML.Output.Factory;

with Lml_Tests.Support;

--  Drive the pragma parser over a range of well-formed inputs (positional,
--  named, valueless, signed numbers, and assorted whitespace/comment layouts)
--  and assert the JSON output carries the expected payloads. Mostly a smoke
--  test that none of the layouts raise, with a few content checks.
--
--  Key casing is asserted verbatim here, so the parser is run with
--  Preserve_Key_Case; the default lower-casing is covered by Pragmas_Case.

procedure Lml_Tests.Pragmas_Basic is

   use Lml_Tests.Support;
   use all type Yeison.Kinds;

   LF : constant Wide_Wide_Character := Wide_Wide_Character'Val (10);

   function Run (Image : Text) return Text is
      Builder : LML.Output.Builder'Class :=
        LML.Output.Factory.Get (LML.JSON);
   begin
      LML.Input.Pragmas.From_Pragmas
        (Image, Builder, LML.Options.Pragmas.Preserve_Key_Case);
      return Builder.To_Text;
   end Run;

   function Parse (Image : Text) return Yeison.Any is
     (LML.From_Text (Run (Image), LML.JSON));
   --  Parse the JSON the pragma parser emits back into Yeison, so tests can
   --  assert exact values and inferred types rather than mere substrings.

begin
   --  All three supported value kinds in one prelude. Beyond the payload, the
   --  inferred types must be right: a string stays a string, True becomes a
   --  boolean (not the text "True") and the numeric literal becomes a real.
   declare
      Pragma_Map : constant Yeison.Any :=
        Parse ("pragma Alire_Test (Name,        ""A test"");" & LF
               & "pragma Alire_Test (Should_Fail, True);"     & LF
               & "pragma Alire_Test (Timeout,    11.1);");
      Body_Map   : constant Yeison.Any := At_Key (Pragma_Map, "Alire_Test");
   begin
      Assert_Equal (At_Key (Body_Map, "Name"), Y_Str ("A test"),
                    "supported triple: Name");
      Assert_Equal (At_Key (Body_Map, "Should_Fail"), Y_Bool (True),
                    "supported triple: Should_Fail");
      Assert (At_Key (Body_Map, "Timeout").Kind = Real_Kind,
              "supported triple: Timeout should be a real, got "
              & At_Key (Body_Map, "Timeout").Kind'Image);
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

   --  Valueless form: a key with no value yields Nil (JSON null), while a
   --  sibling numeric value parses as an integer.
   declare
      Body_Map : constant Yeison.Any :=
        At_Key (Parse ("pragma Alire_Test (Should_Fail);" & LF
                       & "pragma Alire_Test (Other, 1);"  & LF
                       & "pragma Alire_Test (Spaced   ) ;"),
                "Alire_Test");
   begin
      Assert (At_Key (Body_Map, "Should_Fail").Kind = Nil_Kind,
              "valueless key should be nil");
      Assert (At_Key (Body_Map, "Spaced").Kind = Nil_Kind,
              "valueless spaced key should be nil");
      Assert_Equal (At_Key (Body_Map, "Other"), Y_Int (1), "valueless: Other");
   end;

   --  Wholly empty pragma `pragma X;` (no parentheses) yields an empty
   --  object: a map with no keys, distinct from the valueless
   --  `pragma X (Key);` Nil form above.
   declare
      Parsed   : constant Yeison.Any := Parse ("pragma Alire_Test;");
      Body_Map : constant Yeison.Any := At_Key (Parsed, "Alire_Test");
   begin
      Assert (Body_Map.Kind = Map_Kind,
              "empty pragma should be an (empty) map, got "
              & Body_Map.Kind'Image);
   end;

   --  An empty pragma is idempotent and merges with keyed forms of the
   --  same name: declaring it twice plus a keyed form neither raises nor
   --  loses the keyed value.
   declare
      Body_Map : constant Yeison.Any :=
        At_Key (Parse ("pragma Alire_Test;"             & LF
                       & "pragma Alire_Test (Name, ""x"");" & LF
                       & "pragma Alire_Test;"),
                "Alire_Test");
   begin
      Assert_Equal (At_Key (Body_Map, "Name"), Y_Str ("x"),
                    "empty pragma must not clobber keyed sibling");
   end;

   --  Two pragmas with different names should not collide: each becomes its
   --  own top-level object carrying its own key. The structural equality
   --  subsumes "both names appear" and additionally pins down the nesting,
   --  values and that nothing else leaked.
   declare
      Parsed   : constant Yeison.Any :=
        Parse ("pragma Alire_Test (Name, ""A"");" & LF
               & "pragma Other_Pragma (Tag,  ""B"");");
      Expected : Yeison.Any := Y_Map;
      First    : Yeison.Any := Y_Map;
      Second   : Yeison.Any := Y_Map;
   begin
      Put (First,  "Name", Y_Str ("A"));
      Put (Second, "Tag",  Y_Str ("B"));
      Put (Expected, "Alire_Test",   First);
      Put (Expected, "Other_Pragma", Second);
      Assert_Equal (Parsed, Expected, "two distinct pragma names");
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
