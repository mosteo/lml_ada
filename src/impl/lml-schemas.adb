package body LML.Schemas is

   use all type Yeison.Any;
   use all type Yeison.Kinds;

   package Make renames Yeison.Make;

   subtype Big_Int  is Yeison.Big_Int;
   subtype Big_Real is Yeison.Big_Real;
   subtype Uint     is Yeison.Universal_Integer;

   --------------------------
   --  Result constructors --
   --------------------------

   Pass : constant Result := (Valid => True);

   function Fail (Path, Reason : Text) return Result is
     ((Valid   => False,
       Message  => WWU.To_Unbounded_Wide_Wide_String
         ((if Path = "" then "(root)" else Path) & ": " & Reason)));

   ---------------
   --  Helpers  --
   ---------------

   function Field (Map : Yeison.Any; Key : Text) return Yeison.Any is
     (Map.Get (Make.Str (Key)));
   --  The value of a present map entry (the caller guards with Has_Key).

   function Type_Name (K : Yeison.Kinds) return Text is
     (case K is
         when Nil_Kind  => "null",
         when Bool_Kind => "boolean",
         when Int_Kind  => "integer",
         when Real_Kind => "number",
         when Str_Kind  => "string",
         when Map_Kind  => "object",
         when Vec_Kind  => "array");

   function As_Float (X : Yeison.Any) return Big_Real is
     (case X.Kind is
         when Int_Kind  => Big_Real (X.As_Int),
         when Real_Kind => X.As_Real_Float,
         when others    =>
            raise Constraint_Error with "not a number");

   function Real_Is_Integral (X : Yeison.Any) return Boolean is
   begin
      return Big_Real'Truncation (X.As_Real_Float) = X.As_Real_Float;
   exception
      when others => return False;  --  non-finite reals are not integral
   end Real_Is_Integral;

   function Type_Matches (Data : Yeison.Any; Name : Text) return Boolean is
   begin
      if    Name = "null"    then return Data.Kind = Nil_Kind;
      elsif Name = "boolean" then return Data.Kind = Bool_Kind;
      elsif Name = "object"  then return Data.Kind = Map_Kind;
      elsif Name = "array"   then return Data.Kind = Vec_Kind;
      elsif Name = "string"  then return Data.Kind = Str_Kind;
      elsif Name = "number"  then
         return Data.Kind in Int_Kind | Real_Kind;
      elsif Name = "integer" then
         return Data.Kind = Int_Kind
           or else (Data.Kind = Real_Kind and then Real_Is_Integral (Data));
      else
         raise LML.Unsupported_Error
           with "unknown type name: " & Encode (Name);
      end if;
   end Type_Matches;

   function Idx (I : Uint) return Text is
      S : constant String := I'Image;
   begin
      --  'Image prefixes a blank for non-negative values; drop it.
      return Decode (if S (S'First) = ' '
                     then S (S'First + 1 .. S'Last) else S);
   end Idx;

   --  Forward declaration: the keyword checks below recurse through Check.

   function Check (Data, Schema : Yeison.Any; Path : Text) return Result;

   ------------------
   --  Check_Type  --
   ------------------

   function Check_Type (Data, Schema : Yeison.Any; Path : Text) return Result
   is
   begin
      if not Schema.Has_Key ("type") then
         return Pass;
      end if;

      declare
         T : constant Yeison.Any := Field (Schema, "type");
      begin
         if T.Kind = Str_Kind then
            if Type_Matches (Data, T.As_Text) then
               return Pass;
            end if;
            return Fail (Path, "expected " & T.As_Text & ", found "
                         & Type_Name (Data.Kind));
         elsif T.Kind = Vec_Kind then
            for Name of T loop
               if Type_Matches (Data, Name.As_Text) then
                  return Pass;
               end if;
            end loop;
            return Fail (Path, "type " & Type_Name (Data.Kind)
                         & " is not in the allowed set");
         else
            raise LML.Unsupported_Error
              with "'type' must be a string or an array of strings";
         end if;
      end;
   end Check_Type;

   ------------------------
   --  Check_Enum_Const  --
   ------------------------

   function Check_Enum_Const (Data, Schema : Yeison.Any; Path : Text)
                              return Result is
   begin
      if Schema.Has_Key ("const")
        and then not (Data = Field (Schema, "const"))
      then
         return Fail (Path, "value does not equal const");
      end if;

      if Schema.Has_Key ("enum") then
         declare
            E     : constant Yeison.Any := Field (Schema, "enum");
            Found : Boolean := False;
         begin
            for V of E loop
               if Data = V then
                  Found := True;
               end if;
            end loop;
            if not Found then
               return Fail (Path, "value is not one of the enum members");
            end if;
         end;
      end if;

      return Pass;
   end Check_Enum_Const;

   --------------------
   --  Check_Object  --
   --------------------

   function Check_Object (Data, Schema : Yeison.Any; Path : Text)
                          return Result is
   begin
      if Data.Kind /= Map_Kind then
         return Pass;  --  object keywords ignore non-objects
      end if;

      --  required
      if Schema.Has_Key ("required") then
         declare
            Reqs : constant Yeison.Any := Field (Schema, "required");
         begin
            for Req of Reqs loop
               if not Data.Has_Key (Req) then
                  return Fail (Path, "missing required property "
                               & Req.As_Text);
               end if;
            end loop;
         end;
      end if;

      --  properties: recurse into each present property
      if Schema.Has_Key ("properties") then
         declare
            Props : constant Yeison.Any := Field (Schema, "properties");
            Names : constant Yeison.Any := Props.Keys;
         begin
            for Key of Names loop
               if Data.Has_Key (Key) then
                  declare
                     R : constant Result :=
                       Check (Data.Get (Key), Props.Get (Key),
                              Path & "/" & Key.As_Text);
                  begin
                     if not R.Valid then
                        return R;
                     end if;
                  end;
               end if;
            end loop;
         end;
      end if;

      --  additionalProperties: boolean or subschema, applied to the
      --  properties not named in `properties`
      if Schema.Has_Key ("additionalProperties") then
         declare
            AP    : constant Yeison.Any :=
              Field (Schema, "additionalProperties");
            Props : constant Yeison.Any :=
              (if Schema.Has_Key ("properties")
               then Field (Schema, "properties") else Make.Map);
            Names : constant Yeison.Any := Data.Keys;
         begin
            for Key of Names loop
               if not Props.Has_Key (Key) then
                  if AP.Kind = Bool_Kind then
                     if not AP.As_Bool then
                        return Fail (Path & "/" & Key.As_Text,
                                     "additional property not allowed");
                     end if;
                  else
                     declare
                        R : constant Result :=
                          Check (Data.Get (Key), AP,
                                 Path & "/" & Key.As_Text);
                     begin
                        if not R.Valid then
                           return R;
                        end if;
                     end;
                  end if;
               end if;
            end loop;
         end;
      end if;

      if Schema.Has_Key ("minProperties")
        and then Data.Length < Field (Schema, "minProperties").As_Int
      then
         return Fail (Path, "object has fewer than minProperties members");
      end if;

      if Schema.Has_Key ("maxProperties")
        and then Data.Length > Field (Schema, "maxProperties").As_Int
      then
         return Fail (Path, "object has more than maxProperties members");
      end if;

      return Pass;
   end Check_Object;

   -------------------
   --  Check_Array  --
   -------------------

   function Check_Array (Data, Schema : Yeison.Any; Path : Text)
                         return Result
   is
      N_Prefix : Uint := 0;
   begin
      if Data.Kind /= Vec_Kind then
         return Pass;
      end if;

      --  prefixItems: positional subschemas
      if Schema.Has_Key ("prefixItems") then
         declare
            Pref : constant Yeison.Any := Field (Schema, "prefixItems");
            I    : Uint := Pref.First_Index;
         begin
            N_Prefix := Pref.Length;
            while I <= Pref.Length and then I <= Data.Length loop
               declare
                  R : constant Result :=
                    Check (Data.Get (Make.Int (I)),
                           Pref.Get (Make.Int (I)),
                           Path & "/" & Idx (I));
               begin
                  if not R.Valid then
                     return R;
                  end if;
               end;
               I := I + 1;
            end loop;
         end;
      end if;

      --  items: applies to elements after the prefixItems prefix
      if Schema.Has_Key ("items") then
         declare
            It : constant Yeison.Any := Field (Schema, "items");
            I  : Uint := Data.First_Index + N_Prefix;
         begin
            while I <= Data.Length loop
               if It.Kind = Bool_Kind then
                  if not It.As_Bool then
                     return Fail (Path & "/" & Idx (I),
                                  "item not allowed by items: false");
                  end if;
               else
                  declare
                     R : constant Result :=
                       Check (Data.Get (Make.Int (I)), It,
                              Path & "/" & Idx (I));
                  begin
                     if not R.Valid then
                        return R;
                     end if;
                  end;
               end if;
               I := I + 1;
            end loop;
         end;
      end if;

      if Schema.Has_Key ("minItems")
        and then Data.Length < Field (Schema, "minItems").As_Int
      then
         return Fail (Path, "array is shorter than minItems");
      end if;

      if Schema.Has_Key ("maxItems")
        and then Data.Length > Field (Schema, "maxItems").As_Int
      then
         return Fail (Path, "array is longer than maxItems");
      end if;

      --  uniqueItems
      if Schema.Has_Key ("uniqueItems")
        and then Field (Schema, "uniqueItems").Kind = Bool_Kind
        and then Field (Schema, "uniqueItems").As_Bool
      then
         declare
            I : Uint := Data.First_Index;
            J : Uint;
         begin
            while I <= Data.Length loop
               J := I + 1;
               while J <= Data.Length loop
                  if Data.Get (Make.Int (I)) = Data.Get (Make.Int (J)) then
                     return Fail (Path, "array items are not unique");
                  end if;
                  J := J + 1;
               end loop;
               I := I + 1;
            end loop;
         end;
      end if;

      --  contains / minContains / maxContains
      if Schema.Has_Key ("contains") then
         declare
            Sub     : constant Yeison.Any := Field (Schema, "contains");
            Count   : Uint := 0;
            Min     : constant Big_Int :=
              (if Schema.Has_Key ("minContains")
               then Field (Schema, "minContains").As_Int else 1);
            Has_Max : constant Boolean := Schema.Has_Key ("maxContains");
            Max     : constant Big_Int :=
              (if Has_Max then Field (Schema, "maxContains").As_Int else 0);
         begin
            for E of Data loop
               if Check (E, Sub, Path).Valid then
                  Count := Count + 1;
               end if;
            end loop;
            if Big_Int (Count) < Min then
               return Fail (Path, "fewer than minContains matching items");
            end if;
            if Has_Max and then Big_Int (Count) > Max then
               return Fail (Path, "more than maxContains matching items");
            end if;
         end;
      end if;

      return Pass;
   end Check_Array;

   --------------------
   --  Check_String  --
   --------------------

   function Check_String (Data, Schema : Yeison.Any; Path : Text)
                          return Result is
   begin
      if Data.Kind /= Str_Kind then
         return Pass;
      end if;

      declare
         Len : constant Big_Int := Data.As_Text'Length;
      begin
         if Schema.Has_Key ("minLength")
           and then Len < Field (Schema, "minLength").As_Int
         then
            return Fail (Path, "string is shorter than minLength");
         end if;
         if Schema.Has_Key ("maxLength")
           and then Len > Field (Schema, "maxLength").As_Int
         then
            return Fail (Path, "string is longer than maxLength");
         end if;
      end;

      return Pass;
   end Check_String;

   --------------------
   --  Check_Number  --
   --------------------

   function Check_Number (Data, Schema : Yeison.Any; Path : Text)
                          return Result is
   begin
      if Data.Kind not in Int_Kind | Real_Kind then
         return Pass;
      end if;

      declare
         V : constant Big_Real := As_Float (Data);
      begin
         if Schema.Has_Key ("minimum")
           and then V < As_Float (Field (Schema, "minimum"))
         then
            return Fail (Path, "value is below minimum");
         end if;
         if Schema.Has_Key ("maximum")
           and then V > As_Float (Field (Schema, "maximum"))
         then
            return Fail (Path, "value is above maximum");
         end if;
         if Schema.Has_Key ("exclusiveMinimum")
           and then V <= As_Float (Field (Schema, "exclusiveMinimum"))
         then
            return Fail (Path, "value is not above exclusiveMinimum");
         end if;
         if Schema.Has_Key ("exclusiveMaximum")
           and then V >= As_Float (Field (Schema, "exclusiveMaximum"))
         then
            return Fail (Path, "value is not below exclusiveMaximum");
         end if;
         if Schema.Has_Key ("multipleOf") then
            declare
               M : constant Big_Real :=
                 As_Float (Field (Schema, "multipleOf"));
               Q : constant Big_Real := V / M;
            begin
               if abs (Q - Big_Real'Rounding (Q)) > 1.0E-9 then
                  return Fail (Path, "value is not a multiple of multipleOf");
               end if;
            end;
         end if;
      end;

      return Pass;
   end Check_Number;

   ------------------------
   --  Check_Combinators --
   ------------------------

   function Check_Combinators (Data, Schema : Yeison.Any; Path : Text)
                               return Result is
   begin
      if Schema.Has_Key ("allOf") then
         declare
            Subs : constant Yeison.Any := Field (Schema, "allOf");
         begin
            for Sub of Subs loop
               declare
                  R : constant Result := Check (Data, Sub, Path);
               begin
                  if not R.Valid then
                     return R;
                  end if;
               end;
            end loop;
         end;
      end if;

      if Schema.Has_Key ("anyOf") then
         declare
            Subs  : constant Yeison.Any := Field (Schema, "anyOf");
            Found : Boolean := False;
         begin
            for Sub of Subs loop
               if Check (Data, Sub, Path).Valid then
                  Found := True;
               end if;
            end loop;
            if not Found then
               return Fail (Path, "value matches no anyOf subschema");
            end if;
         end;
      end if;

      if Schema.Has_Key ("oneOf") then
         declare
            Subs  : constant Yeison.Any := Field (Schema, "oneOf");
            Count : Natural := 0;
         begin
            for Sub of Subs loop
               if Check (Data, Sub, Path).Valid then
                  Count := Count + 1;
               end if;
            end loop;
            if Count /= 1 then
               return Fail (Path,
                            "value must match exactly one oneOf subschema");
            end if;
         end;
      end if;

      if Schema.Has_Key ("not")
        and then Check (Data, Field (Schema, "not"), Path).Valid
      then
         return Fail (Path, "value must not match the 'not' subschema");
      end if;

      return Pass;
   end Check_Combinators;

   ------------------------
   --  Check_Conditional --
   ------------------------

   function Check_Conditional (Data, Schema : Yeison.Any; Path : Text)
                               return Result is
   begin
      if not Schema.Has_Key ("if") then
         return Pass;
      end if;

      if Check (Data, Field (Schema, "if"), Path).Valid then
         if Schema.Has_Key ("then") then
            return Check (Data, Field (Schema, "then"), Path);
         end if;
      else
         if Schema.Has_Key ("else") then
            return Check (Data, Field (Schema, "else"), Path);
         end if;
      end if;

      return Pass;
   end Check_Conditional;

   -------------
   --  Check  --
   -------------

   function Check (Data, Schema : Yeison.Any; Path : Text) return Result is
      R : Result;
   begin
      --  A schema is either a boolean or a map of keywords.
      if Schema.Kind = Bool_Kind then
         return (if Schema.As_Bool then Pass
                 else Fail (Path, "false schema rejects every value"));
      end if;

      if Schema.Kind /= Map_Kind then
         raise LML.Unsupported_Error
           with "schema must be a boolean or a map, found "
                & Encode (Type_Name (Schema.Kind));
      end if;

      if Schema.Has_Key ("$ref") then
         raise LML.Unsupported_Error
           with "$ref / referencing is not supported";
      end if;

      R := Check_Type (Data, Schema, Path);
      if not R.Valid then return R; end if;
      R := Check_Enum_Const (Data, Schema, Path);
      if not R.Valid then return R; end if;
      R := Check_Object (Data, Schema, Path);
      if not R.Valid then return R; end if;
      R := Check_Array (Data, Schema, Path);
      if not R.Valid then return R; end if;
      R := Check_String (Data, Schema, Path);
      if not R.Valid then return R; end if;
      R := Check_Number (Data, Schema, Path);
      if not R.Valid then return R; end if;
      R := Check_Combinators (Data, Schema, Path);
      if not R.Valid then return R; end if;
      R := Check_Conditional (Data, Schema, Path);
      return R;
   end Check;

   ----------------
   --  Validate  --
   ----------------

   function Validate (Data, Schema : Yeison.Any) return Result is
     (Check (Data, Schema, ""));

end LML.Schemas;
