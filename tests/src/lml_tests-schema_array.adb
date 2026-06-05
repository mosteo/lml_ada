with LML.Schemas;

with Lml_Tests.Support;

--  Array keywords: items, min/maxItems, uniqueItems, prefixItems and
--  contains/minContains.

procedure Lml_Tests.Schema_Array is

   use Lml_Tests.Support;

begin
   --  items + min/max + uniqueItems
   declare
      S     : Yeison.Any := Y_Map;
      Items : Yeison.Any := Y_Map;
      D     : Yeison.Any := Y_Vec;
   begin
      Put (Items, "type", Y_Str ("number"));
      Put (S, "items", Items);
      Put (S, "minItems", Y_Int (1));
      Put (S, "maxItems", Y_Int (3));
      Put (S, "uniqueItems", Y_Bool (True));

      D.Append (Y_Int (1));
      D.Append (Y_Int (2));
      Assert (LML.Schemas.Is_Valid (D, S), "valid number array");

      declare
         Bad : Yeison.Any := Y_Vec;
      begin
         Bad.Append (Y_Int (1));
         Bad.Append (Y_Str ("x"));
         Assert (not LML.Schemas.Is_Valid (Bad, S), "items type mismatch");
      end;

      declare
         Dup : Yeison.Any := Y_Vec;
      begin
         Dup.Append (Y_Int (1));
         Dup.Append (Y_Int (1));
         Assert (not LML.Schemas.Is_Valid (Dup, S), "duplicate items");
      end;

      declare
         Empty : constant Yeison.Any := Y_Vec;
      begin
         Assert (not LML.Schemas.Is_Valid (Empty, S), "below minItems");
      end;

      declare
         Big : Yeison.Any := Y_Vec;
      begin
         Big.Append (Y_Int (1));
         Big.Append (Y_Int (2));
         Big.Append (Y_Int (3));
         Big.Append (Y_Int (4));
         Assert (not LML.Schemas.Is_Valid (Big, S), "above maxItems");
      end;
   end;

   --  prefixItems: [ {type:string}, {type:number} ]
   declare
      S    : Yeison.Any := Y_Map;
      Pref : Yeison.Any := Y_Vec;
      S0   : Yeison.Any := Y_Map;
      S1   : Yeison.Any := Y_Map;
      D    : Yeison.Any := Y_Vec;
   begin
      Put (S0, "type", Y_Str ("string"));
      Put (S1, "type", Y_Str ("number"));
      Pref.Append (S0);
      Pref.Append (S1);
      Put (S, "prefixItems", Pref);

      D.Append (Y_Str ("a"));
      D.Append (Y_Int (2));
      Assert (LML.Schemas.Is_Valid (D, S), "prefixItems valid");

      declare
         Bad : Yeison.Any := Y_Vec;
      begin
         Bad.Append (Y_Int (1));
         Bad.Append (Y_Int (2));
         Assert (not LML.Schemas.Is_Valid (Bad, S),
                 "prefixItems first element wrong type");
      end;
   end;

   --  contains + minContains
   declare
      S : Yeison.Any := Y_Map;
      C : Yeison.Any := Y_Map;
      D : Yeison.Any := Y_Vec;
   begin
      Put (C, "type", Y_Str ("number"));
      Put (S, "contains", C);
      Put (S, "minContains", Y_Int (2));

      D.Append (Y_Str ("a"));
      D.Append (Y_Int (1));
      D.Append (Y_Int (2));
      Assert (LML.Schemas.Is_Valid (D, S), "contains >= 2 numbers");

      declare
         Few : Yeison.Any := Y_Vec;
      begin
         Few.Append (Y_Str ("a"));
         Few.Append (Y_Int (1));
         Assert (not LML.Schemas.Is_Valid (Few, S), "contains < 2 numbers");
      end;
   end;
end Lml_Tests.Schema_Array;
