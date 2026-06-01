with LML.Output.Factory;

with Yeison_12;

--  Verify the LML.Supports_Nil contract: formats that do not support null
--  values (TOML) must raise Unsupported_Error when a nil reaches them inside a
--  map or a vector; the rest must succeed. This section has a real pass/fail
--  oracle, so it asserts strictly rather than just smoke-testing.

procedure Lml_Tests.Nil_Support is

   package Yeison renames Yeison_12;

   function "+" (Str : Yeison.Text) return Yeison.Scalar
     renames Yeison.Scalars.New_Text;

   procedure Nil_As_Map_Value (Builder : in out LML.Output.Builder'Class) is
   begin
      Builder.Begin_Map;
      Builder.Insert ("flag");
      Builder.Append_Nil;
      Builder.End_Map;
      declare
         Ignore : constant Text := Builder.To_Text;
      begin
         null;
      end;
   end Nil_As_Map_Value;

   procedure Nil_In_Vector (Builder : in out LML.Output.Builder'Class) is
   begin
      Builder.Begin_Map;
      Builder.Insert ("vec");
      Builder.Begin_Vec;
      Builder.Append (+"before");
      Builder.Append_Nil;
      Builder.Append (+"after");
      Builder.End_Vec;
      Builder.End_Map;
      declare
         Ignore : constant Text := Builder.To_Text;
      begin
         null;
      end;
   end Nil_In_Vector;

begin
   for Format in LML.Supported_Outputs loop
      --  Nil as a map value
      begin
         declare
            Builder : LML.Output.Builder'Class :=
                        LML.Output.Factory.Get (Format);
         begin
            Nil_As_Map_Value (Builder);
         end;
         Assert (LML.Supports_Nil (Format),
                 "expected Unsupported_Error (nil map value) for "
                 & Format'Image);
      exception
         when LML.Unsupported_Error =>
            Assert (not LML.Supports_Nil (Format),
                    "unexpected Unsupported_Error (nil map value) for "
                    & Format'Image);
      end;

      --  Nil inside a vector
      begin
         declare
            Builder : LML.Output.Builder'Class :=
                        LML.Output.Factory.Get (Format);
         begin
            Nil_In_Vector (Builder);
         end;
         Assert (LML.Supports_Nil (Format),
                 "expected Unsupported_Error (nil in vector) for "
                 & Format'Image);
      exception
         when LML.Unsupported_Error =>
            Assert (not LML.Supports_Nil (Format),
                    "unexpected Unsupported_Error (nil in vector) for "
                    & Format'Image);
      end;
   end loop;
end Lml_Tests.Nil_Support;
