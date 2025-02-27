with LML.Output;

package LML.Input.YAML with Preelaborate is

   function From_String (Image : Text) return Yeison.Any;
   --  The YAML library is just emitting events without a type per-se, so we
   --  convert it internally to Yeison.Any. If you want to avoid this extra
   --  copy, you can use From_YAML below directly and the resulting
   --  populated Builder to directly get your desired output.

   procedure From_YAML (Image   : Text;
                        Builder : in out Output.Builder'Class);

private

   type Builder is access
     procedure (Image   : Text;
                Builder : in out Output.Builder'Class);

   YAML_Builder : Builder;
   --  We need this hook because AdaYaml is not Preelaborate, alas.

end LML.Input.YAML;
