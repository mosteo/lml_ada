with LML.Input.JSON;
with LML.Input.Pragmas;
with LML.Input.TOML;
with LML.Input.YAML;
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
      Builder : Output.Builder'Class := Output.Factory.Get (Into);
   begin
      case From is
         when JSON    => Input.JSON.From_JSON (Image, Builder);
         when Pragmas => Input.Pragmas.From_Pragmas (Image, Builder);
         when TOML    => Input.TOML.From_TOML (Image, Builder);
         when YAML    => Input.YAML.From_YAML (Image, Builder);
      end case;
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
            Output.Build (Input.YAML.From_String (Image), Builder);
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
