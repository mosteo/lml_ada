with LML.Output.JSON;
with LML.Output.TOML;
with LML.Output.YAML;

package body LML.Output.Factory is

   function Get (Format : Formats) return Builder'Class
   is (case Format is
          when LML.JSON => Output.JSON.Make,
          when LML.TOML => Output.TOML.Make,
          when LML.YAML => Output.YAML.Make);

end LML.Output.Factory;
