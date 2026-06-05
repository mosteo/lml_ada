package body LML.Input.Emit is

   -----------------
   -- Append_Bool --
   -----------------

   procedure Append_Bool (Builder : in out Output.Builder'Class;
                          Value   : Boolean) is
   begin
      Builder.Append (Scalars.New_Bool (Value));
   end Append_Bool;

   ----------------
   -- Append_Int --
   ----------------

   procedure Append_Int (Builder : in out Output.Builder'Class;
                         Value   : Yeison.Big_Int) is
   begin
      Builder.Append (Scalars.New_Int (Value));
   end Append_Int;

   -----------------
   -- Append_Real --
   -----------------

   procedure Append_Real (Builder : in out Output.Builder'Class;
                          Value   : Yeison.Big_Real) is
   begin
      Builder.Append (Scalars.New_Real (Yeison.Reals.New_Real (Value)));
   end Append_Real;

   ----------------
   -- Append_Inf --
   ----------------

   procedure Append_Inf (Builder  : in out Output.Builder'Class;
                         Positive : Boolean) is
   begin
      Builder.Append (Scalars.New_Real (Yeison.Reals.New_Infinite (Positive)));
   end Append_Inf;

   ----------------
   -- Append_NaN --
   ----------------

   procedure Append_NaN (Builder : in out Output.Builder'Class) is
   begin
      Builder.Append (Scalars.New_Real (Yeison.Reals.New_NaN));
   end Append_NaN;

   ----------------------
   -- Append_Text_UTF8 --
   ----------------------

   procedure Append_Text_UTF8 (Builder : in out Output.Builder'Class;
                               S       : Text_UTF8) is
   begin
      Builder.Append (Scalars.New_Text (Decode (S)));
   end Append_Text_UTF8;

end LML.Input.Emit;
