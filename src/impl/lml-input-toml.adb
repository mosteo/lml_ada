with Ada.Strings.Unbounded;

with LML.Input.Emit;
with LML.Input.Walk;

package body LML.Input.TOML is

   --------------
   -- Classify --
   --------------

   function Classify (This : TOML_Value) return Walk.Walk_Category is
      use Standard.TOML;
   begin
      case This.Kind is
         when TOML_Table => return Walk.Map;
         when TOML_Array => return Walk.Vec;
         when others     => return Walk.Scalar;
      end case;
   end Classify;

   -----------------
   -- Emit_Scalar --
   -----------------

   procedure Emit_Scalar (This    : TOML_Value;
                          Builder : in out Output.Builder'Class)
   is
      use Standard.TOML;
   begin
      case This.Kind is
         when TOML_Boolean =>
            Emit.Append_Bool (Builder, This.As_Boolean);

         when TOML_Integer =>
            Emit.Append_Int (Builder, Yeison.Big_Int (This.As_Integer));

         when TOML_Float =>
            case This.As_Float.Kind is
               when Regular =>
                  Emit.Append_Real
                    (Builder, Yeison.Big_Real (This.As_Float.Value));
               when Infinity =>
                  Emit.Append_Inf (Builder, This.As_Float.Positive);
               when NaN =>
                  Emit.Append_NaN (Builder);
            end case;

         when TOML_String =>
            Emit.Append_Text_UTF8 (Builder, This.As_String);

         when others =>
            raise Program_Error with "unsupported type: " & This.Kind'Image;
      end case;
   end Emit_Scalar;

   -------------------
   -- Iterate_Pairs --
   -------------------

   procedure Iterate_Pairs
     (This    : TOML_Value;
      Process : not null access procedure (Key : Text; Value : TOML_Value))
   is
      use Ada.Strings.Unbounded;
   begin
      for Key of This.Keys loop
         Process (Decode (To_String (Key)), This.Get (Key));
      end loop;
   end Iterate_Pairs;

   -------------------
   -- Iterate_Items --
   -------------------

   procedure Iterate_Items
     (This    : TOML_Value;
      Process : not null access procedure (Value : TOML_Value))
   is
   begin
      for I in 1 .. This.Length loop
         Process (This.Item (I));
      end loop;
   end Iterate_Items;

   procedure Walk_TOML is new Walk.Walk
     (Node          => TOML_Value,
      Classify      => Classify,
      Emit_Scalar   => Emit_Scalar,
      Iterate_Pairs => Iterate_Pairs,
      Iterate_Items => Iterate_Items);

   -----------------
   -- From_String --
   -----------------

   function From_String (Image : Text) return TOML_Value is
      use Standard.TOML;
      Result : constant Read_Result := Load_String (Encode (Image));
   begin
      if Result.Success then
         return Result.Value;
      else
         raise Constraint_Error with Format_Error (Result);
      end if;
   end From_String;

   ---------------
   -- From_TOML --
   ---------------

   procedure From_TOML (This    : TOML_Value;
                        Builder : in out Output.Builder'Class)
   is
   begin
      if not This.Is_Present then
         raise Constraint_Error with "Input TOML value is null";
      end if;

      Walk_TOML (This, Builder);
   end From_TOML;

   ---------------
   -- From_TOML --
   ---------------

   procedure From_TOML (Image   : Text;
                        Builder : in out Output.Builder'Class;
                        Options : LML.Options.Any'Class :=
                          LML.Options.No_Options)
   is
      pragma Unreferenced (Options);
   begin
      From_TOML (From_String (Image), Builder);
   end From_TOML;

end LML.Input.TOML;
