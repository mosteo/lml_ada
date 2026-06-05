with LML.Schemas;

with Lml_Tests.Support;

--  `const` (exact, type-sensitive equality) and `enum` (membership).

procedure Lml_Tests.Schema_Enum_Const is

   use Lml_Tests.Support;

   S_Const : Yeison.Any := Y_Map;
   S_Enum  : Yeison.Any := Y_Map;
   Enum    : Yeison.Any := Y_Vec;

begin
   Put (S_Const, "const", Y_Int (42));
   Assert (LML.Schemas.Is_Valid (Y_Int (42), S_Const), "const match");
   Assert (not LML.Schemas.Is_Valid (Y_Int (7), S_Const), "const mismatch");
   Assert (not LML.Schemas.Is_Valid (Y_Str ("42"), S_Const),
           "const is type-sensitive");

   Enum.Append (Y_Str ("red"));
   Enum.Append (Y_Str ("green"));
   Enum.Append (Y_Int (1));
   Put (S_Enum, "enum", Enum);
   Assert (LML.Schemas.Is_Valid (Y_Str ("green"), S_Enum), "enum member");
   Assert (LML.Schemas.Is_Valid (Y_Int (1), S_Enum), "enum int member");
   Assert (not LML.Schemas.Is_Valid (Y_Str ("blue"), S_Enum),
           "enum non-member");
end Lml_Tests.Schema_Enum_Const;
