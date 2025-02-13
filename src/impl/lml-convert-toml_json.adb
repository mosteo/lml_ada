with LML.Input.TOML;
with LML.Output.JSON;

package body LML.Convert.TOML_JSON is

   -----------
   -- Image --
   -----------

   function Image (This : TOML_Value) return Text is

      function Convert is new Obj_To_Text
        (TOML_Value,
         Input.TOML.From_TOML,
         Output.JSON.Builder);

   begin
      return Convert (This);
   end Image;

   -----------
   -- Build --
   -----------

   function Build (Image : Text) return Output.Builder'Class is
      Builder : Output.JSON.Builder;
   begin
      Input.TOML.From_TOML (Input.TOML.From_String (Image), Builder);

      return Builder;
   end Build;

end LML.Convert.TOML_JSON;
