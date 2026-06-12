pragma Warnings (Off);
with GNAT.IO; use GNAT.IO;
pragma Warnings (On);

with LML.Output.Factory;

package body LML.Output is

   ------------
   -- Append --
   ------------

   procedure Append (This : in out Builder'Class; Val : Scalar) is
   begin
      This.Append_Impl (Val);
   end Append;

   ----------------
   -- Append_Nil --
   ----------------

   procedure Append_Nil (This : in out Builder'Class) is
   begin
      This.Append_Nil_Impl;
   end Append_Nil;

   ------------
   -- Insert --
   ------------

   procedure Insert (This : in out Builder'Class; K : Text) is
   begin
      This.Keys.Append (K);
      This.Insert_Impl (K);
   end Insert;

   ---------------
   -- Begin_Map --
   ---------------

   procedure Begin_Map (This : in out Builder'Class) is
   begin
      This.Begin_Map_Impl;
   end Begin_Map;

   -------------
   -- End_Map --
   -------------

   procedure End_Map (This : in out Builder'Class) is
   begin
      This.End_Map_Impl;
   end End_Map;

   ---------------
   -- Begin_Vec --
   ---------------

   procedure Begin_Vec (This : in out Builder'Class) is
   begin
      This.Begin_Vec_Impl;
   end Begin_Vec;

   -------------
   -- End_Vec --
   -------------

   procedure End_Vec (This : in out Builder'Class) is
   begin
      This.End_Vec_Impl;
   end End_Vec;

   ---------
   -- Pop --
   ---------

   function Pop (This : in out Builder'Class) return Text is
   begin
      return Key : constant Text := This.Keys.Last_Element do
         This.Keys.Delete_Last;
      end return;
   end Pop;

   -----------
   -- Build --
   -----------

   procedure Build (This    : Yeison.Any;
                    Builder : in out Output.Builder'Class)
   is
      use all type Yeison.Kinds;
   begin
      case This.Kind is
         when Nil_Kind =>
            Builder.Append_Nil;

         when Yeison.Scalar_Kinds =>
            Builder.Append (This.As_Scalar);

         when Map_Kind =>
            Builder.Begin_Map;

            --  Iterate by index on purpose: with assertions on,
            --  GNAT <= 11 mis-finalizes the controlled temporaries
            --  of `for ... of` iteration over Any, crashing at scope
            --  exit (same bug family as the Strict_Names workaround
            --  in lml-input-pragmas.adb).
            declare
               Keys : constant Yeison.Any := This.Keys;
            begin
               for I in 1 .. Keys.Length loop
                  declare
                     Key : constant Yeison.Any :=
                       Keys (Yeison.Make.Int (Yeison.Big_Int (I)));
                  begin
                     if Key.Kind /= Str_Kind then
                        raise Program_Error
                          with "LML currently only supports string keys";
                     end if;

                     Builder.Insert (Key.As_Text);
                     Build (This (Encode (Key.As_Text)), Builder);
                  end;
               end loop;
            end;

            Builder.End_Map;

         when Vec_Kind =>
            Builder.Begin_Vec;

            for I in 1 .. This.Length loop
               Build (This (Yeison.Make.Int (I)), Builder);
            end loop;

            Builder.End_Vec;
      end case;
   end Build;

   -------------
   -- To_Text --
   -------------

   function To_Builder (This   : Yeison.Any;
                        Format : Formats)
                        return Builder'Class
   is
   begin
      return Builder : Output.Builder'Class := Output.Factory.Get (Format) do
         Build (This, Builder);
      end return;
   end To_Builder;

end LML.Output;
