with JSON.Parsers;

with LML.Input.Emit;
with LML.Input.Walk;
with LML.Output.Yeison;

package body LML.Input.JSON is

   package Parsers is new
     Standard.JSON.Parsers (Types,
                            Default_Maximum_Depth => 16,
                            Check_Duplicate_Keys  => True);

   --------------
   -- Classify --
   --------------

   function Classify (This : Types.JSON_Value) return Walk.Walk_Category is
      use all type Types.Value_Kind;
   begin
      case This.Kind is
         when Object_Kind => return Walk.Map;
         when Array_Kind  => return Walk.Vec;
         when others      => return Walk.Scalar;
      end case;
   end Classify;

   -----------------
   -- Emit_Scalar --
   -----------------

   procedure Emit_Scalar (This    : Types.JSON_Value;
                          Builder : in out Output.Builder'Class)
   is
      use all type Types.Value_Kind;
   begin
      case This.Kind is
         when Null_Kind    => Builder.Append_Nil;
         when Boolean_Kind => Emit.Append_Bool (Builder, This.Value);
         when Integer_Kind => Emit.Append_Int (Builder, This.Value);
         when Float_Kind   => Emit.Append_Real (Builder, This.Value);
         when String_Kind  => Emit.Append_Text_UTF8 (Builder, This.Value);
         when Object_Kind | Array_Kind =>
            raise Program_Error with "not a scalar";
      end case;
   end Emit_Scalar;

   -------------------
   -- Iterate_Pairs --
   -------------------

   procedure Iterate_Pairs
     (This    : Types.JSON_Value;
      Process : not null access
                  procedure (Key : Text; Value : Types.JSON_Value))
   is
   begin
      for Key of This loop
         Process (Decode (Key.Value), This.Get (Key.Value));
      end loop;
   end Iterate_Pairs;

   -------------------
   -- Iterate_Items --
   -------------------

   procedure Iterate_Items
     (This    : Types.JSON_Value;
      Process : not null access procedure (Value : Types.JSON_Value))
   is
   begin
      for Obj of This loop
         Process (Obj);
      end loop;
   end Iterate_Items;

   procedure Walk_JSON is new Walk.Walk
     (Node          => Types.JSON_Value,
      Classify      => Classify,
      Emit_Scalar   => Emit_Scalar,
      Iterate_Pairs => Iterate_Pairs,
      Iterate_Items => Iterate_Items);

   -----------------
   -- From_String --
   -----------------

   function From_String (Image : Text) return Yeison.Any
   is
      Parser  : Parsers.Parser := Parsers.Create (Encode (Image));
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
   begin
      Walk_JSON (This, Builder);
   end From_JSON;

   ---------------
   -- From_JSON --
   ---------------

   procedure From_JSON (Image   : Text;
                        Builder : in out Output.Builder'Class;
                        Options : LML.Options.Any'Class :=
                          LML.Options.No_Options)
   is
      pragma Unreferenced (Options);
      Parser  : Parsers.Parser := Parsers.Create (Encode (Image));
   begin
      From_JSON (Parser.Parse, Builder);
   end From_JSON;

end LML.Input.JSON;
