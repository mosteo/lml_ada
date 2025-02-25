with Ada.Strings.Unbounded;

package body LML.Input.TOML is

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

      ---------------
      -- From_TOML --
      ---------------

      procedure From_TOML (This : TOML_Value) is
         use Ada.Strings.Unbounded;
         use Standard.TOML;
      begin
         case This.Kind is
            when TOML_Boolean =>
               Builder.Append (Scalars.New_Bool (This.As_Boolean));

            when TOML_Integer =>
               Builder.Append
                 (Scalars.New_Int (Yeison.Big_Int (This.As_Integer)));

            when TOML_Float =>
               case This.As_Float.Kind is
                  when Regular =>
                     Builder.Append
                       (Scalars.New_Real
                          (Yeison.Reals.New_Real
                               (Yeison.Big_Real
                                    (This.As_Float.Value))));
                  when Infinity =>
                     Builder.Append
                       (Scalars.New_Real
                          (Yeison.Reals.New_Infinite
                               (This.As_Float.Positive)));
                  when NaN =>
                     Builder.Append
                       (Scalars.New_Real
                          (Yeison.Reals.New_NaN));
               end case;

            when TOML_String =>
               Builder.Append (Scalars.New_Text (Decode (This.As_String)));

            when TOML_Table =>
               Builder.Begin_Map;

               for Key of This.Keys loop
                  Builder.Insert (Decode (To_String (Key)));
                  From_TOML (This.Get (Key));
               end loop;

               Builder.End_Map;

            when TOML_Array =>
               Builder.Begin_Vec;

               for I in 1 .. This.Length loop
                  From_TOML (This.Item (I));
               end loop;

               Builder.End_Vec;

            when others =>
               raise Program_Error with "unsupported type: " & This.Kind'Image;
         end case;
      end From_TOML;

   begin
      if not This.Is_Present then
         raise Constraint_Error with "Input TOML value is null";
      end if;

      From_TOML (This);
   end From_TOML;

   ---------------
   -- From_TOML --
   ---------------

   procedure From_TOML (Image   : Text;
                        Builder : in out Output.Builder'Class)
   is
   begin
      From_TOML (From_String (Image), Builder);
   end From_TOML;

end LML.Input.TOML;
