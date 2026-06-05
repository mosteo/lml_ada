with LML.Schemas;

with Lml_Tests.Support;

--  if/then/else: the `if` subschema is evaluated silently and selects which
--  of `then`/`else` must hold. Mirrors the sample schema's conditional shape.
--
--    if   { properties: { kind: { const: "int" } }, required: [kind] }
--    then { required: [ival] }
--    else { required: [sval] }

procedure Lml_Tests.Schema_Conditional is

   use Lml_Tests.Support;

   Schema   : Yeison.Any := Y_Map;
   If_S     : Yeison.Any := Y_Map;
   If_Props : Yeison.Any := Y_Map;
   Kind_S   : Yeison.Any := Y_Map;
   If_Req   : Yeison.Any := Y_Vec;
   Then_S   : Yeison.Any := Y_Map;
   Else_S   : Yeison.Any := Y_Map;
   Then_Req : Yeison.Any := Y_Vec;
   Else_Req : Yeison.Any := Y_Vec;

begin
   Put (Kind_S, "const", Y_Str ("int"));
   Put (If_Props, "kind", Kind_S);
   Put (If_S, "properties", If_Props);
   If_Req.Append (Y_Str ("kind"));
   Put (If_S, "required", If_Req);

   Then_Req.Append (Y_Str ("ival"));
   Put (Then_S, "required", Then_Req);
   Else_Req.Append (Y_Str ("sval"));
   Put (Else_S, "required", Else_Req);

   Put (Schema, "if", If_S);
   Put (Schema, "then", Then_S);
   Put (Schema, "else", Else_S);

   --  kind = int -> the `then` branch applies (ival required)
   declare
      D : Yeison.Any := Y_Map;
   begin
      Put (D, "kind", Y_Str ("int"));
      Put (D, "ival", Y_Int (3));
      Assert (LML.Schemas.Is_Valid (D, Schema), "then branch satisfied");
   end;

   declare
      D : Yeison.Any := Y_Map;
   begin
      Put (D, "kind", Y_Str ("int"));
      Assert (not LML.Schemas.Is_Valid (D, Schema),
              "then branch missing ival");
   end;

   --  kind /= int -> the `else` branch applies (sval required)
   declare
      D : Yeison.Any := Y_Map;
   begin
      Put (D, "kind", Y_Str ("str"));
      Assert (not LML.Schemas.Is_Valid (D, Schema), "else branch needs sval");
      Put (D, "sval", Y_Str ("x"));
      Assert (LML.Schemas.Is_Valid (D, Schema), "else branch satisfied");
   end;
end Lml_Tests.Schema_Conditional;
