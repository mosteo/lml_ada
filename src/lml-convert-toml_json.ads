with TOML;

package LML.Convert.TOML_JSON with Preelaborate is

   subtype TOML_Value is Standard.TOML.TOML_Value;

   function Image (This : TOML_Value) return Text;
   --  JSON image of the input TOML value

end LML.Convert.TOML_JSON;
