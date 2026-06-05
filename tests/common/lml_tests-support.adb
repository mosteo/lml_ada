with LML.Input.YAML.Initialization;

package body Lml_Tests.Support is

   ---------
   -- Put --
   ---------

   procedure Put (Map : in out Yeison.Any; Key : Text; Value : Yeison.Any) is
   begin
      Map.Insert (Y_Str (Key), Value);
   end Put;

   -----------
   -- Canon --
   -----------

   function Canon (V : Yeison.Any) return Text is
     (V.Image (Format  => Yeison.JSON,
               Options => (Compact => True, Ordered_Keys => True)));
   --  Deterministic rendering: keys sorted and no incidental whitespace, so two
   --  values compare equal iff they carry the same data, regardless of the
   --  insertion order Yeison's own "=" is otherwise sensitive to.

   ------------------
   -- Assert_Equal --
   ------------------

   procedure Assert_Equal (Found, Expected : Yeison.Any; Msg : String) is
   begin
      Assert (Canon (Found) = Canon (Expected),
              Msg & " | found: " & Str (Canon (Found))
              & " | expected: " & Str (Canon (Expected)));
   end Assert_Equal;

   ------------------
   -- Check_Output --
   ------------------

   procedure Check_Output (Found_Text   : Text;
                           Format       : LML.Formats;
                           Expected     : Yeison.Any;
                           Title        : String;
                           May_Be_Empty : Boolean := False) is
   begin
      if Format in LML.JSON | LML.TOML | LML.YAML then
         --  YAML input is reached through a hook the client must arm once;
         --  Initialize only assigns the access value, so it is idempotent.
         if Format in LML.YAML then
            LML.Input.YAML.Initialization.Initialize;
         end if;
         Assert_Equal (LML.From_Text (Found_Text, Format), Expected,
                       Title & " [" & Format'Image & "]");
      elsif not May_Be_Empty then
         Assert (Found_Text'Length > 0,
                 "empty output for " & Title & " [" & Format'Image & "]");
      end if;
   end Check_Output;

   ---------------------
   -- Check_Roundtrip --
   ---------------------

   procedure Check_Roundtrip (Value  : Yeison.Any;
                              Format : LML.Formats;
                              Title  : String) is
   begin
      Check_Output (LML.To_Text (Value, Format), Format, Value, Title);
   end Check_Roundtrip;

end Lml_Tests.Support;
