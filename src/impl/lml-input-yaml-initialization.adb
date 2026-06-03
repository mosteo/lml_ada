with Ada.Containers.Vectors;

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

      --  For every open collection we track whether it is a mapping and, if so,
      --  whether the next scalar is a key (mappings emit keys and values as a
      --  flat alternating event stream).
      type Frame is record
         Is_Map        : Boolean;
         Expecting_Key : Boolean;
      end record;

      package Frame_Stacks is new Ada.Containers.Vectors (Positive, Frame);
      Stack : Frame_Stacks.Vector;

      -----------------
      -- After_Value --
      -----------------

      procedure After_Value is
         --  A value has just been completed; if it lived inside a mapping, the
         --  next scalar there is again a key.
      begin
         if not Stack.Is_Empty and then Stack.Last_Element.Is_Map then
            declare
               Top : Frame := Stack.Last_Element;
            begin
               Top.Expecting_Key := True;
               Stack.Replace_Element (Stack.Last_Index, Top);
            end;
         end if;
      end After_Value;

      -----------------
      -- Begin_Value --
      -----------------

      procedure Begin_Value is
         --  Called when a collection starts. A collection cannot serve as a
         --  mapping key (Builder.Insert needs Text), so reject that case.
      begin
         if not Stack.Is_Empty
           and then Stack.Last_Element.Is_Map
           and then Stack.Last_Element.Expecting_Key
         then
            raise Unsupported_Error with
              "YAML complex (collection) mapping keys are not supported";
         end if;
      end Begin_Value;

      -------------
      -- Resolve --
      -------------

      procedure Resolve (Ev : Event) is
         --  Emit a scalar event as either a mapping key or a value, resolving
         --  plain scalars per the YAML core schema.
         S : constant String := Ev.Content.Value;
      begin
         --  Mapping key: always taken verbatim as text.
         if not Stack.Is_Empty
           and then Stack.Last_Element.Is_Map
           and then Stack.Last_Element.Expecting_Key
         then
            Builder.Insert (LML.Decode (S));

            declare
               Top : Frame := Stack.Last_Element;
            begin
               Top.Expecting_Key := False;
               Stack.Replace_Element (Stack.Last_Index, Top);
            end;
            return;
         end if;

         --  Value position. Resolve plain scalars to typed values; quoted,
         --  literal and folded scalars are always text.
         if Ev.Scalar_Style = Plain then
            if S = "" or else S = "~"
              or else S = "null" or else S = "Null" or else S = "NULL"
            then
               Builder.Append_Nil;
               After_Value;
               return;
            elsif S = "true" or else S = "True" or else S = "TRUE" then
               Builder.Append (Scalars.New_Bool (True));
               After_Value;
               return;
            elsif S = "false" or else S = "False" or else S = "FALSE" then
               Builder.Append (Scalars.New_Bool (False));
               After_Value;
               return;
            end if;

            --  Integer?
            begin
               Builder.Append (Scalars.New_Int (Yeison.Big_Int'Value (S)));
               After_Value;
               return;
            exception
               when Constraint_Error => null;
            end;

            --  Real?
            begin
               Builder.Append
                 (Scalars.New_Real
                    (Yeison.Reals.New_Real (Yeison.Big_Real'Value (S))));
               After_Value;
               return;
            exception
               when Constraint_Error => null;
            end;
         end if;

         --  Fall back to text.
         Builder.Append (Scalars.New_Text (LML.Decode (S)));
         After_Value;
      end Resolve;

   begin
      Instance.Set_Input (LML.Encode (Image));

      loop
         declare
            Ev : constant Event := Instance.Next;
         begin
            case Ev.Kind is
               when Stream_Start | Stream_End
                  | Document_Start | Document_End
                  | Annotation_Start | Annotation_End =>
                  null;

               when Mapping_Start =>
                  Begin_Value;
                  Builder.Begin_Map;
                  Stack.Append ((Is_Map => True, Expecting_Key => True));

               when Mapping_End =>
                  Builder.End_Map;
                  Stack.Delete_Last;
                  After_Value;

               when Sequence_Start =>
                  Begin_Value;
                  Builder.Begin_Vec;
                  Stack.Append ((Is_Map => False, Expecting_Key => False));

               when Sequence_End =>
                  Builder.End_Vec;
                  Stack.Delete_Last;
                  After_Value;

               when Y.Scalar =>
                  Resolve (Ev);

               when Alias =>
                  raise Unsupported_Error with
                    "YAML anchors/aliases are not supported";
            end case;

            exit when Ev.Kind = Stream_End;
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
