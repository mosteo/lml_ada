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
            when TOML_String =>
               Builder.Append (Decode (This.As_String));

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
         raise Constraint_Error with "Input TOML value is empty";
      end if;

      From_TOML (This);
   end From_TOML;

end LML.Input.TOML;
