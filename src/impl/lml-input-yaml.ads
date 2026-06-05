with LML.Output;

package LML.Input.YAML with Preelaborate is

   function From_String (Image : Text) return Yeison.Any;
   --  Direct conversion to Yeison

   procedure From_YAML (Image   : Text;
                        Builder : in out Output.Builder'Class);
   --  Process into any other target format, no intermediate typed
   --  representation.

private

   type Builder is access
     procedure (Image   : Text;
                Builder : in out Output.Builder'Class);

   YAML_Builder : Builder;
   --  We need this hook because AdaYaml is not Preelaborate, alas.

end LML.Input.YAML;
