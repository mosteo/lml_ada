with JSON.Parsers;

with LML.Output.Yeison;

package body LML.Input.JSON is

   package Parsers is new
     Standard.JSON.Parsers (Types,
                            Default_Maximum_Depth => 16,
                            Check_Duplicate_Keys  => True);

   -----------------
   -- From_String --
   -----------------

   function From_String (Image : Text) return Yeison.Any
   is
      Parser : Parsers.Parser := Parsers.Create (Encode (Image));
      Builder : Output.Yeison.Builder;
   begin
      return Result : Yeison.Any do
         From_JSON (Parser.Parse, Builder);
         Result := Builder.To_Yeison;
      end return;
   end From_String;

   ---------------
   -- From_JSON --
   ---------------

   procedure From_JSON (This    : Types.JSON_Value;
                        Builder : in out Output.Builder'Class)
   is
      use all type Types.Value_Kind;
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
               From_JSON (This.Get (Key.Value), Builder);
            end loop;

            Builder.End_Map;

         when Array_Kind =>
            Builder.Begin_Vec;

            for Obj of This loop
               From_JSON (Obj, Builder);
            end loop;

            Builder.End_Vec;

         when others =>
            raise Program_Error with "unsupported type: " & This.Kind'Image;
      end case;
   end From_JSON;

end LML.Input.JSON;
