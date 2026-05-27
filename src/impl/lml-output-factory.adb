with LML.Output.JSON;
with LML.Output.TOML;
with LML.Output.YAML;

package body LML.Output.Factory is

   function Get (Format : Formats) return Builder'Class
   is (case Format is
          when LML.JSON => Output.JSON.Make,
          when LML.TOML => Output.TOML.Make,
          when LML.YAML => Output.YAML.Make,
          when LML.Pragmas =>
            raise Unsupported_Error with "Pragmas output not supported yet");

end LML.Output.Factory;
