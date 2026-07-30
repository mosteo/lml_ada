with LML;
with LML.Input.Pragmas;
with LML.Output.Factory;

--  Exercise the unit-kind classification reported as a byproduct of the
--  pragma scan (the `Unit : out Ada_Unit` overload of From_Pragmas). Only a
--  parameterless main procedure can be a runnable test, so the runner relies
--  on this to tell mains apart from packages, functions, generics and
--  subunits without forcing every non-test source to be annotated.

procedure Lml_Tests.Pragmas_Unit_Kind is

   use all type LML.Input.Pragmas.Ada_Unit;

   LF : constant Wide_Wide_Character := Wide_Wide_Character'Val (10);

   function Kind (Image : Text) return LML.Input.Pragmas.Ada_Unit is
      Builder : LML.Output.Builder'Class :=
        LML.Output.Factory.Get (LML.JSON);
      Unit    : LML.Input.Pragmas.Ada_Unit;
   begin
      LML.Input.Pragmas.From_Pragmas (Image, Builder, Unit);
      return Unit;
   end Kind;

begin
   --  A bare parameterless procedure is the only test-eligible kind.
   Assert (Kind ("procedure P is begin null; end P;")
             = Procedure_Without_Parameters,
           "plain procedure");

   --  `procedure P;` (a body-less spec or a renaming header) still has no
   --  parameters.
   Assert (Kind ("procedure P;") = Procedure_Without_Parameters,
           "procedure with no body/aspect");

   --  A child-unit defining name is dotted; the parameter check must skip
   --  past the whole name. This is exactly the shape of the seeded test main.
   Assert (Kind ("procedure Foo_Tests.Assertions_Enabled is "
                 & "begin null; end Foo_Tests.Assertions_Enabled;")
             = Procedure_Without_Parameters,
           "dotted child-unit procedure");

   --  A procedure that takes parameters cannot be a main.
   Assert (Kind ("procedure P (X : Integer) is begin null; end P;")
             = Procedure_With_Parameters,
           "procedure with parameters");

   --  Package, function and generic bodies are never tests.
   Assert (Kind ("package body Pkg is" & LF
                 & "begin null; end Pkg;") = Package_Unit,
           "package body");

   Assert (Kind ("function F return Integer is begin return 0; end F;")
             = Function_Unit,
           "function body");

   Assert (Kind ("generic" & LF
                 & "package Gen is end Gen;") = Generic_Unit,
           "generic unit");

   --  A subunit leads with `separate`, which must win over the `procedure`
   --  that follows it on the same line.
   Assert (Kind ("separate (Parent) procedure Child is "
                 & "begin null; end Child;") = Separate_Unit,
           "separate subunit");

   --  No unit keyword at all (empty input, or pragmas only).
   Assert (Kind ("") = Unknown, "empty input");
   Assert (Kind ("pragma Alire_Test;") = Unknown, "pragmas only");

   --  Classification survives a realistic prelude: context clauses, comments,
   --  string literals mentioning keywords, and an opt-in pragma all precede
   --  the actual unit declaration.
   Assert (Kind ("with Ada.Text_IO;"                        & LF
                 & "--  procedure mentioned in a comment"   & LF
                 & "pragma Alire_Test;"                     & LF
                 & "procedure Main is"                      & LF
                 & "   S : String := ""package body X"";"   & LF
                 & "begin null; end Main;")
             = Procedure_Without_Parameters,
           "procedure after a full prelude");

   --  Keyword recognition is case-insensitive, like Ada.
   Assert (Kind ("PROCEDURE P IS BEGIN null; END P;")
             = Procedure_Without_Parameters,
           "upper-case procedure");
end Lml_Tests.Pragmas_Unit_Kind;
