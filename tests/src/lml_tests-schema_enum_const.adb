with Lml_Tests.Support;

--  `const` (exact, type-sensitive equality) and `enum` (membership),
--  checking the diagnostics on the negative cases.

procedure Lml_Tests.Schema_Enum_Const is

   use Lml_Tests.Support;

   S_Const : Yeison.Any := Y_Map;
   S_Enum  : Yeison.Any := Y_Map;
   Enum    : Yeison.Any := Y_Vec;

begin
   Put (S_Const, "const", Y_Int (42));
   Assert_Valid (Y_Int (42), S_Const, "const match");
   Assert_Invalid (Y_Int (7), S_Const,
                   "value does not equal const", "const mismatch");
   Assert_Invalid (Y_Str ("42"), S_Const,
                   "value does not equal const", "const is type-sensitive");

   Enum.Append (Y_Str ("red"));
   Enum.Append (Y_Str ("green"));
   Enum.Append (Y_Int (1));
   Put (S_Enum, "enum", Enum);
   Assert_Valid (Y_Str ("green"), S_Enum, "enum member");
   Assert_Valid (Y_Int (1), S_Enum, "enum int member");
   Assert_Invalid (Y_Str ("blue"), S_Enum,
                   "value is not one of the enum members", "enum non-member");
end Lml_Tests.Schema_Enum_Const;
