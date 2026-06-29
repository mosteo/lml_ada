with LML.Options;
with LML.Output;

with Yeison_12;

package LML.Input.Pragmas with Preelaborate is

   --  The idea with this package is that we can convert from custom Ada
   --  pragmas to a JSON-equivalent format. This is mainly done with Alire
   --  tests in mind, that can use those pragmas:
   --
   --  pragma Alire_Test;
   --  pragma Alire_Test (Name,        "A test");
   --  pragma Alire_Test (Should_Fail, True);
   --  pragma Alire_Test (Timeout,     11.1); -- It's a duration
   --  pragma Alire_Test (Name =>      "A test"); -- named form also accepted
   --
   --  For now, there aren't more complex data structures we expect to support.
   --  The result is a map with the pragma name as key, and within it another
   --  map with the pragma's first argument as key and the second as value
   --  (or Nil when no value is given), autodetected as String, Boolean,
   --  Int, or Real. Both positional (Key, Value) and named (Key => Value)
   --  forms are accepted; a bare key with no value yields Nil. A wholly
   --  empty pragma with no arguments at all (pragma Alire_Test;) is also
   --  accepted and yields an empty map (an empty object) for that name.
   --
   --  The procedures below will do a best effort to parse, and will silently
   --  discard or ignore anything not fitting expectations. This is not a
   --  general Ada parser and thus it may miss complex expressions like, but
   --  not limited to:
   --
   --  pragma Alire_Test (Timeout,  1.0 * 60.0);
   --  pragma Alire_Test (Whatever, "asdf" & "qwer");
   --
   --  In the future, the objective might be to be able to support arbitrary
   --  nesting like:
   --
   --  pragma Alire_Test (Config, (Timeout, 11.1), (Should_Fail, True));

   package Yeison renames Yeison_12;

   pragma Warnings (Off, "unrecognized pragma");

   --  Supported cases
   pragma Alire_Test (Name,       "A test");
   pragma Alire_Test (Should_Fail, True);
   pragma Alire_Test (Should_Fail); -- No value yields Nil (note:
   --  currently the bundled Builders cannot emit Nil and will raise
   --  Program_Error during output until Nil rendering is added).
   pragma Alire_Test (Timeout,     11.1);
   pragma Alire_Test (Name => "A test"); -- Named form accepted
   pragma Alire_Test; -- Wholly empty: yields an empty object {}

   --  Complex unsupported cases (yet?)
   pragma Alire_Test (Timeout,  1.0 * 60.0);
   pragma Alire_Test (Whatever, "asdf" & "qwer");
   pragma Alire_Test (Config, (Timeout,     11.1),
                              (Should_Fail, True));
   pragma Alire_Test (Config => (Timeout     => 11.1,
                                 Should_Fail => True));

   pragma Warnings (On);

   Duplicate_Pragma : exception renames LML.Duplicate_Pragma;
   --  Since this spec is more or less private, reuse the public one rather
   --  than defining it here.

   type Ada_Unit is
     (Unknown,                       --  No unit keyword found (empty/odd file)
      Package_Unit,
      Function_Unit,
      Generic_Unit,
      Separate_Unit,
      Procedure_Without_Parameters,  --  The only thing that can be a test main
      Procedure_With_Parameters);
   --  The kind of compilation unit that ends the pragma-bearing prelude,
   --  classified from the first unit keyword the scanner reaches. Reported as
   --  a byproduct of the single pragma scan so callers (e.g. the Alire test
   --  runner) can tell whether a body is a runnable main procedure.

   procedure From_Pragmas (Image   : Text;
                           Builder : in out Output.Builder'Class;
                           Options : LML.Options.Any'Class :=
                             LML.Options.No_Options);
   --  Image can be a whole Ada file, but the parsing will end at the first
   --  unit keyword ("package"/"procedure"/"function"/"generic"/"separate").
   --  Pragmas inside Ada comments are ignored. Raises Duplicate_Pragma if the
   --  same (pragma_name, key) pair appears more than once. When Options is
   --  LML.Options.Pragmas.Input_Options, pragma names listed in Options.Strict
   --  must parse successfully or Invalid_Pragma_Syntax is raised.

   procedure From_Pragmas (Image   : Text;
                           Builder : in out Output.Builder'Class;
                           Unit    : out Ada_Unit;
                           Options : LML.Options.Any'Class :=
                             LML.Options.No_Options);
   --  As above, but also report the kind of unit that terminated the prelude
   --  scan in Unit (Unknown if none was reached).

end LML.Input.Pragmas;
