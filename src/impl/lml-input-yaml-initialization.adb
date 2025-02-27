with Yaml.Parser;

package body LML.Input.YAML.Initialization is

   package Y renames Standard.Yaml;

   ---------------
   -- From_YAML --
   ---------------

   procedure From_YAML (Image   : Text;
                        Builder : in out Output.Builder'Class)
   is
      use Standard.Yaml;

      Ref      : constant Parser.Reference := Parser.New_Parser;
      Instance : Parser.Instance  renames Ref.Value;
   begin
      Instance.Set_Input (LML.Encode (Image));

      loop
         declare
            Ev : constant Event := Instance.Next;
         begin
            case Ev.Kind is
               when Stream_Start =>
                  null;  -- Nothing to do for stream start

               when Document_Start | Document_End =>
                  null;  -- Nothing to do for document start/end

               when Mapping_Start =>
                  Builder.Begin_Map;

               when Mapping_End =>
                  Builder.End_Map;

               when Sequence_Start =>
                  Builder.Begin_Vec;

               when Sequence_End =>
                  Builder.End_Vec;

               when Y.Scalar =>
                  Builder.Append (LML.Decode (Ev.Content));

               when Alias =>
                  -- Handle alias by using the anchor target
                  Builder.Append (LML.Decode (Ev.Target));

               when Annotation_Start | Annotation_End =>
                  null;  -- Ignore annotations for now

               when Stream_End =>
                  exit;
            end case;
         end;
      end loop;
   end From_YAML;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Input.YAML.YAML_Builder := From_YAML'Access;
   end Initialize;

end LML.Input.YAML.Initialization;
