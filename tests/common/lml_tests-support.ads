with LML;

--  Shared helpers for the stringent (oracle-based) tests. The guiding idea is
--  to compare *structure* rather than exact text: a value is rendered to a
--  format and, where LML can parse that format back, re-parsed and compared to
--  an independently-built Yeison value. This is immune to whitespace and key
--  ordering tweaks while still catching wrong values, wrong types or dropped
--  fields.

package Lml_Tests.Support is

   package Yeison renames LML.Yeison;

   --------------------------
   --  Value constructors  --
   --------------------------

   --  Built with the functional Make API rather than Ada-2022 literal and
   --  aggregate aspects, so the tests compile under the same settings as the
   --  rest of the suite.

   function Y_Str  (Val : Text)    return Yeison.Any
   is (Yeison.Make.Str (Val));

   function Y_Int  (Val : Integer) return Yeison.Any
   is (Yeison.Make.Int (Yeison.Big_Int (Val)));

   function Y_Real (Val : Long_Long_Float) return Yeison.Any
   is (Yeison.Make.Real (Yeison.Reals.New_Real (Val)));

   function Y_Bool (Val : Boolean) return Yeison.Any
   is (Yeison.Make.Bool (Val));

   function Y_Nil return Yeison.Any is (Yeison.Make.Nil);
   function Y_Map return Yeison.Any is (Yeison.Make.Map);
   function Y_Vec return Yeison.Any is (Yeison.Make.Vec);

   procedure Put (Map : in out Yeison.Any; Key : Text; Value : Yeison.Any);
   --  String-keyed map insertion (wraps Key as a Yeison string).

   ------------------
   --  Navigation  --
   ------------------

   function At_Key (Map : Yeison.Any; Key : Text) return Yeison.Any
   is (Yeison.Get (Map, Y_Str (Key)));

   function At_Index (Vec : Yeison.Any; Pos : Integer) return Yeison.Any
   is (Yeison.Get (Vec, Y_Int (Pos)));

   -----------------
   --  Assertions --
   -----------------

   procedure Assert_Equal (Found, Expected : Yeison.Any; Msg : String);
   --  Structural (whitespace- and order-independent) equality, via each value's
   --  canonical JSON image (sorted keys, compact).

   procedure Check_Output (Found_Text   : Text;
                           Format       : LML.Formats;
                           Expected     : Yeison.Any;
                           Title        : String;
                           May_Be_Empty : Boolean := False);
   --  Re-parse Found_Text with Format and compare to Expected. For output-only
   --  formats (those LML cannot parse back, e.g. YAML) the structural check is
   --  skipped and a non-empty smoke check is done instead, unless
   --  May_Be_Empty is set.

   procedure Check_Roundtrip (Value  : Yeison.Any;
                              Format : LML.Formats;
                              Title  : String);
   --  Render Value to Format and assert it parses back equal to Value.

end Lml_Tests.Support;
