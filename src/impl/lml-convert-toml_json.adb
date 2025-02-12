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

end LML.Convert.TOML_JSON;
