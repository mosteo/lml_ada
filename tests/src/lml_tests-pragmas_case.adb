with LML.Input.Pragmas;
with LML.Options;
with LML.Options.Pragmas;
with LML.Output.Factory;

--  Exercise the Lower_Case_Keys option of the pragma parser. Identifier keys
--  (the pragma name and each key) are normalized to lower case by default,
--  and kept verbatim when the option is disabled. Values are never touched in
--  either mode. Also covers the degenerate case of a source with no pragma at
--  all, which must yield an empty object without raising.

procedure Lml_Tests.Pragmas_Case is

   Source : constant Text := "pragma Alire_Test (NaMe, ""KeepMe"");";
   --  Mixed-case pragma name and key; the value mixes case too.

   function Run (Image   : Text;
                 Options : LML.Options.Any'Class) return Text
   is
      Builder : LML.Output.Builder'Class :=
        LML.Output.Factory.Get (LML.JSON);
   begin
      LML.Input.Pragmas.From_Pragmas (Image, Builder, Options);
      return Builder.To_Text;
   end Run;

begin
   --  Default: the pragma name and key are lower-cased, the value preserved.
   declare
      Out_Text : constant Text := Run (Source, LML.Options.No_Options);
   begin
      Assert (Contains (Out_Text, "alire_test"),
              "default lower name: " & Str (Out_Text));
      Assert (Contains (Out_Text, "name"),
              "default lower key: " & Str (Out_Text));
      Assert (not Contains (Out_Text, "NaMe"),
              "default must not keep key casing: " & Str (Out_Text));
      Assert (not Contains (Out_Text, "Alire_Test"),
              "default must not keep name casing: " & Str (Out_Text));
      Assert (Contains (Out_Text, "KeepMe"),
              "value casing must be preserved: " & Str (Out_Text));
   end;

   --  Disabled: keys keep their source casing.
   declare
      Out_Text : constant Text :=
        Run (Source, LML.Options.Pragmas.Preserve_Key_Case);
   begin
      Assert (Contains (Out_Text, "Alire_Test"),
              "verbatim name: " & Str (Out_Text));
      Assert (Contains (Out_Text, "NaMe"),
              "verbatim key: " & Str (Out_Text));
      Assert (Contains (Out_Text, "KeepMe"),
              "value casing must be preserved: " & Str (Out_Text));
   end;

   --  No pragma at all: a source with ordinary code but no pragma must
   --  yield an empty object ("{}") without raising, regardless of options.
   declare
      Out_Text : constant Text :=
        Run ("with Ada.Text_IO; procedure P is begin null; end P;",
             LML.Options.No_Options);
   begin
      Assert (not Contains (Out_Text, "alire_test"),
              "no-pragma source must yield no keys: " & Str (Out_Text));
      Assert (Contains (Out_Text, "{}"),
              "no-pragma source must yield an empty object: "
              & Str (Out_Text));
   end;
end Lml_Tests.Pragmas_Case;
