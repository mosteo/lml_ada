with LML.Output;

package LML.Input.Pragmas with Preelaborate is

   --  The idea with this package is that we can convert from custom Ada
   --  pragmas to a JSON-equivalent format. This is mainly done with Alire
   --  tests in mind, that can use those pragmas:
   --
   --  pragma Alire_Test (Name,       "A test");
   --  pragma Alire_Test (Shoud_Fail, True);
   --  pragma Alire_Test (Timeout,    11.1); -- It's a duration
   --
   --  For now, there aren't more complex data structures we expect to support.
   --  The result is a map with the pragma name a key, and within it another
   --  map with the first argument of the pragma as key and the second as
   --  value, autodetected as String, Boolean, or Int/Real.
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

   pragma Warnings (Off, "unrecognized pragma");

   --  Supported cases
   pragma Alire_Test (Name,       "A test");
   pragma Alire_Test (Should_Fail, True);
   pragma Alire_Test (Timeout,     11.1);

   --  Complex unsupported cases (yet?)
   pragma Alire_Test (Name => "A test");
   pragma Alire_Test (Timeout,  1.0 * 60.0);
   pragma Alire_Test (Whatever, "asdf" & "qwer");
   pragma Alire_Test (Config, (Timeout,     11.1),
                              (Should_Fail, True));
   pragma Alire_Test (Config => (Timeout     => 11.1,
                                 Should_Fail => True));

   procedure From_Pragmas (Image   : Text;
                           Builder : in out Output.Builder'Class);
   --  Image can be a whole Ada file, but the parsing will end at the first
   --  "procedure"/"function"/"generic" occurrence. Pragmas inside Ada comments
   --  are ignored. Raises Constraint_Error if the same (pragma_name, key) pair
   --  appears more than once.
   --
   --  TODO: a Strict parameter is planned, to flag pragma names that must be
   --  parsed successfully (or otherwise be reported as non-compliant with our
   --  limited grammar). Deferred until the error-reporting channel for it is
   --  designed.

end LML.Input.Pragmas;
