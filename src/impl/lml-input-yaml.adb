with LML.Output.Yeison;

package body LML.Input.YAML is

   -----------------
   -- From_String --
   -----------------

   function From_String (Image : Text) return Yeison.Any is
      Builder : Output.Yeison.Builder;
   begin
      From_YAML (Image, Builder);
      return Builder.To_Yeison;
   end From_String;

   ---------------
   -- From_YAML --
   ---------------

   procedure From_YAML (Image   : Text;
                        Builder : in out Output.Builder'Class)
   is
   begin
      if YAML_Builder = null then
         raise Program_Error with
           "LML.Input.YAML.Initialization.Initialize must have been called";
      else
         YAML_Builder (Image, Builder);
      end if;
   end From_YAML;

end LML.Input.YAML;
