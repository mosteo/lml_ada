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

   function Extract_Pragmas (Image : Text) return Text;

   procedure From_Pragmas (Image   : Text;
                           --  Strict  : asdf
                           Builder : in out Output.Builder'Class);
   --  Strict is a list of pragmas that must be parsed successfully or
   --  otherwise be reported as non-compliant with our limited grammar.

end LML.Input.Pragmas;
