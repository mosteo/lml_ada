with LML.Output;

with TOML;

package LML.Input.TOML with Preelaborate is

   subtype TOML_Value is Standard.TOML.TOML_Value;

   function From_String (Image : Text) return TOML_Value;

   procedure From_TOML (This    : TOML_Value;
                        Builder : in out Output.Builder'Class);

   procedure From_TOML (Image   : Text;
                        Builder : in out Output.Builder'Class);

end LML.Input.TOML;
