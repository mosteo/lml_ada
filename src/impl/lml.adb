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

      ---------------
      -- From_TOML --
      ---------------

      function From_TOML return Yeison.Any is
         Builder : Output.Yeison.Builder;
      begin
         Input.TOML.From_TOML (Input.TOML.From_String (Image), Builder);
         return Builder.To_Yeison;
      end From_TOML;

   begin
      case Format is
         when TOML =>
            return From_TOML;
         when others =>
            raise Program_Error with "unimplemented";
      end case;
   end From_Text;

   -------------
   -- To_Text --
   -------------

   function To_Text (This   : Yeison.Any;
                     Format : Formats)
                     return Text
   is (Output.To_Text (This, Format).To_Text);

end LML;
