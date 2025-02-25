with LML.Input.JSON;
with LML.Input.TOML;
with LML.Output.Yeison;

package body LML is

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
            Input.JSON.From_JSON (Input.JSON.From_String (Image), Builder);
         when TOML =>
            Input.TOML.From_TOML (Input.TOML.From_String (Image), Builder);
         when others =>
            raise Program_Error with "unimplemented";
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
