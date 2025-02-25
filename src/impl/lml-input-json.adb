with JSON.Parsers;

with GNAT.IO; use GNAT.IO;

package body LML.Input.JSON is

   package Parsers is new J.Parsers (Types,
                                     Default_Maximum_Depth => 16,
                                     Check_Duplicate_Keys  => True);

   -----------------
   -- From_String --
   -----------------

   function From_String (Image : Text) return JSON_Value
   is
      Parser : Parsers.Parser := Parsers.Create (Encode (Image));
   begin
      return J : constant JSON_Value := Parser.Parse do
         Put_Line ("QWER: " & J.Image);
      end return;
   end From_String;

   ---------------
   -- From_TOML --
   ---------------

   procedure From_JSON (This    : JSON_Value;
                        Builder : in out Output.Builder'Class)
   is

      use all type Types.Value_Kind;

      procedure From_JSON (This : JSON_Value) is
         --  use Ada.Strings.Unbounded;
      begin
         case This.Kind is
            when Boolean_Kind =>
               Builder.Append (Scalars.New_Bool (This.Value));

            when Integer_Kind =>
               Builder.Append
                 (Scalars.New_Int (This.Value));

            when Float_Kind =>
               Builder.Append
                 (Scalars.New_Real (Yeison.Reals.New_Real (This.Value)));

            when String_Kind =>
               Builder.Append (Scalars.New_Text (Decode (This.Value)));

            when Object_Kind =>
               Builder.Begin_Map;

               for Key of This loop
                  Builder.Insert (Decode (Key.Value));
                  From_JSON (This.Get (Key.Value));
               end loop;

               Builder.End_Map;

            when Array_Kind =>
               Builder.Begin_Vec;

               for Obj of This loop
                  From_JSON (Obj);
               end loop;

               Builder.End_Vec;

            when others =>
               raise Program_Error with "unsupported type: " & This.Kind'Image;
         end case;
      end From_JSON;

   begin
      if This.Kind = Null_Kind then
         raise Constraint_Error with "Input JSON value is null";
         --  This should be supported but it isn't yet by LML
      end if;

      Put_Line ("ASDF: " & This.Kind'Image);

      From_JSON (This);

   end From_JSON;

end LML.Input.JSON;
