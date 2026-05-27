with LML.Input.JSON;
with LML.Input.Pragmas;
with LML.Input.TOML;
with LML.Output.Factory;
with LML.Output.Yeison;

package body LML is

   -------------
   -- Convert --
   -------------

   function Convert (Image : Text;
                     From,
                     Into  : Formats)
                     return Text
   is
      type Builder_Proc is access
        procedure (Image   : Text;
                   Builder : in out Output.Builder'Class);
      Builders : constant array (Formats) of Builder_Proc :=
        (JSON    => Input.JSON.From_JSON'Access,
         Pragmas => Input.Pragmas.From_Pragmas'Access,
         TOML    => Input.TOML.From_TOML'Access,
         others  =>
           (raise Unsupported_Error
              with
                "Cannot convert from " & From'Image & " into " & Into'Image));

      Builder : Output.Builder'Class := Output.Factory.Get (Into);

   begin
      Builders (From) (Image, Builder);
      return Builder.To_Text;
   end Convert;

   ---------------
   -- From_Text --
   ---------------

   function From_Text (Image  : Text;
                       Format : Formats)
                       return Yeison.Any
   is
      Builder : Output.Yeison.Builder;
   begin
      case Format is
         when JSON =>
            Output.Build (Input.JSON.From_String (Image), Builder);
         when Pragmas =>
            Input.Pragmas.From_Pragmas (Image, Builder);
         when TOML =>
            Input.TOML.From_TOML (Input.TOML.From_String (Image), Builder);
         when YAML =>
            raise Unsupported_Error with "Cannot parse YAML";
      end case;

      return Builder.To_Yeison;
   end From_Text;

   -------------
   -- To_Text --
   -------------

   function To_Text (This   : Yeison.Any;
                     Format : Formats)
                     return Text
   is (Output.To_Builder (This, Format).To_Text);

end LML;
