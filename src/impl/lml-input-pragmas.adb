with Ada.Wide_Wide_Characters.Handling;

package body LML.Input.Pragmas is

   --  Best-effort, single-pass scanner. We walk Image with one cursor,
   --  recognise the very small subset of pragma forms documented in the
   --  spec, and silently skip anything else (comments, code, string
   --  literals containing the substring "pragma", malformed pragmas).
   --
   --  Two-stage shape: hits are accumulated into a Yeison.Any map and
   --  only handed to the Builder via LML.Output.Build at the end. The
   --  Builder API is forward-only, so we cannot reopen a closed outer
   --  map when a later pragma extends one we have already seen; Yeison
   --  handles that grouping for us.
   --
   --  TODO: a Strict parameter is planned (see spec) but the
   --  failure-reporting channel for it is not yet designed.

   package Wide renames Ada.Wide_Wide_Characters.Handling;

   subtype Idx is Positive;

   HT : constant Wide_Wide_Character := Wide_Wide_Character'Val (9);
   LF : constant Wide_Wide_Character := Wide_Wide_Character'Val (10);
   CR : constant Wide_Wide_Character := Wide_Wide_Character'Val (13);

   ----------------
   -- Char tests --
   ----------------

   --  Identifiers (and the keywords we care about) are deliberately
   --  ASCII-only: every Ada pragma name we want to handle is ASCII, and
   --  full Wide_Wide identifier classification adds complexity for no
   --  practical gain here.

   function Is_Id_Start (C : Wide_Wide_Character) return Boolean is
     (C in 'A' .. 'Z' | 'a' .. 'z');

   function Is_Id_Cont (C : Wide_Wide_Character) return Boolean is
     (C in 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_');

   --  Greedy class for a numeric literal value. We do not re-implement
   --  the Ada numeric grammar; we gobble anything that *might* belong
   --  to a literal and let 'Wide_Wide_Value vet it. As a side-benefit
   --  this naturally accepts signed forms (-1, +1.5) without modelling
   --  unary operators.

   function Is_Num_Char (C : Wide_Wide_Character) return Boolean is
     (C in '0' .. '9' | '_' | '.' | '+' | '-' | 'e' | 'E');

   function Equal_CI (A, B : Text) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in 0 .. A'Length - 1 loop
         if Wide.To_Lower (A (A'First + I))
              /= Wide.To_Lower (B (B'First + I))
         then
            return False;
         end if;
      end loop;
      return True;
   end Equal_CI;

   ------------------
   -- Skip helpers --
   ------------------

   procedure Skip_Whitespace (Image : Text; Pos : in out Idx) is
   begin
      while Pos <= Image'Last
        and then (Image (Pos) = ' '
                    or else Image (Pos) = HT
                    or else Image (Pos) = LF
                    or else Image (Pos) = CR)
      loop
         Pos := Pos + 1;
      end loop;
   end Skip_Whitespace;

   function At_Comment (Image : Text; Pos : Idx) return Boolean is
     (Pos < Image'Last
        and then Image (Pos) = '-'
        and then Image (Pos + 1) = '-');

   procedure Skip_Line_Comment (Image : Text; Pos : in out Idx) is
      --  Caller has verified we sit on "--". Stop at LF (not past it);
      --  Skip_Whitespace will consume the newline next.
   begin
      while Pos <= Image'Last and then Image (Pos) /= LF loop
         Pos := Pos + 1;
      end loop;
   end Skip_Line_Comment;

   procedure Skip_Trivia (Image : Text; Pos : in out Idx) is
      Stuck_At : Idx;
   begin
      loop
         Stuck_At := Pos;
         Skip_Whitespace (Image, Pos);
         if At_Comment (Image, Pos) then
            Skip_Line_Comment (Image, Pos);
         end if;
         exit when Pos = Stuck_At;
      end loop;
   end Skip_Trivia;

   procedure Skip_String_Literal (Image : Text; Pos : in out Idx) is
      --  Caller has verified Image (Pos) = '"'. Ada source uses "" as
      --  the escaped double-quote inside string literals.
   begin
      Pos := Pos + 1;
      while Pos <= Image'Last loop
         if Image (Pos) = '"' then
            if Pos < Image'Last and then Image (Pos + 1) = '"' then
               Pos := Pos + 2;
            else
               Pos := Pos + 1;
               return;
            end if;
         else
            Pos := Pos + 1;
         end if;
      end loop;
   end Skip_String_Literal;

   procedure Skip_Char_Literal_If_Any (Image : Text; Pos : in out Idx) is
      --  Heuristic: if we are at ''' and the third char is also ''',
      --  it is a one-character literal. This is enough to keep contents
      --  like '"' or '-' from confusing the scanner without trying to
      --  distinguish attribute uses (X'Image) from char literals.
   begin
      if Pos + 2 <= Image'Last
        and then Image (Pos) = '''
        and then Image (Pos + 2) = '''
      then
         Pos := Pos + 3;
      else
         Pos := Pos + 1;
      end if;
   end Skip_Char_Literal_If_Any;

   ------------------
   -- Scan helpers --
   ------------------

   procedure Scan_Identifier (Image : Text;
                              Pos   : in out Idx;
                              First : out Idx;
                              Last  : out Idx)
   is
      --  Returns Last < First (empty range) when there is no identifier
      --  at Pos. Otherwise Pos is advanced just past the identifier.
   begin
      First := Pos;
      Last  := Pos - 1;
      if Pos > Image'Last or else not Is_Id_Start (Image (Pos)) then
         return;
      end if;
      while Pos <= Image'Last and then Is_Id_Cont (Image (Pos)) loop
         Pos := Pos + 1;
      end loop;
      Last := Pos - 1;
   end Scan_Identifier;

   procedure Scan_String_Value (Image : Text;
                                Pos   : in out Idx;
                                Value : out Yeison.Any;
                                OK    : out Boolean)
   is
      --  Two-pass: first locate the closing quote (and notice whether
      --  there are any "" escapes). Then either slice the literal
      --  directly (common case, no escapes) or decode into a buffer
      --  whose worst-case size is the literal's own length.
      Start      : constant Idx := Pos;
      Cursor     : Idx;
      Has_Escape : Boolean := False;
      End_Quote  : Idx := 0;
   begin
      OK := False;
      if Pos > Image'Last or else Image (Pos) /= '"' then
         return;
      end if;

      Cursor := Pos + 1;
      while Cursor <= Image'Last loop
         if Image (Cursor) = '"' then
            if Cursor < Image'Last and then Image (Cursor + 1) = '"' then
               Has_Escape := True;
               Cursor := Cursor + 2;
            else
               End_Quote := Cursor;
               exit;
            end if;
         else
            Cursor := Cursor + 1;
         end if;
      end loop;

      if End_Quote = 0 then
         return;  -- unterminated; leave Pos for caller's bail/recovery
      end if;

      if not Has_Escape then
         Value := Yeison.Make.Str (Image (Start + 1 .. End_Quote - 1));
      else
         declare
            Buf  : Text (1 .. End_Quote - Start - 1);  -- upper bound
            Last : Natural := 0;
            I    : Idx := Start + 1;
         begin
            while I < End_Quote loop
               Last := Last + 1;
               Buf (Last) := Image (I);
               if Image (I) = '"' then
                  I := I + 2;  -- collapse "" → "
               else
                  I := I + 1;
               end if;
            end loop;
            Value := Yeison.Make.Str (Buf (1 .. Last));
         end;
      end if;

      Pos := End_Quote + 1;
      OK := True;
   end Scan_String_Value;

   procedure Scan_Bool_Value (Image : Text;
                              Pos   : in out Idx;
                              Value : out Yeison.Any;
                              OK    : out Boolean)
   is
      --  Recognise True / False as Ada identifiers (case-insensitive,
      --  per Ada rules). On a non-boolean identifier, rewind so the
      --  caller can try another value kind.
      Save        : constant Idx := Pos;
      First, Last : Idx;
   begin
      OK := False;
      Scan_Identifier (Image, Pos, First, Last);
      if Last < First then
         return;
      end if;
      if Equal_CI (Image (First .. Last), "True") then
         Value := Yeison.Make.Bool (True);
         OK := True;
      elsif Equal_CI (Image (First .. Last), "False") then
         Value := Yeison.Make.Bool (False);
         OK := True;
      else
         Pos := Save;
      end if;
   end Scan_Bool_Value;

   procedure Scan_Number_Value (Image : Text;
                                Pos   : in out Idx;
                                Value : out Yeison.Any;
                                OK    : out Boolean)
   is
      --  Greedy gobble then defer to 'Wide_Wide_Value (see comment on
      --  Is_Num_Char above for the rationale). On any conversion failure
      --  we restore Pos so the caller's bail/recovery is well-defined.
      Start : constant Idx := Pos;
   begin
      OK := False;
      while Pos <= Image'Last and then Is_Num_Char (Image (Pos)) loop
         Pos := Pos + 1;
      end loop;
      if Pos = Start then
         return;
      end if;

      declare
         Slice   : constant Text := Image (Start .. Pos - 1);
         Is_Real : constant Boolean :=
           (for some C of Slice =>
              C = '.' or else C = 'e' or else C = 'E');
      begin
         if Is_Real then
            Value := Yeison.Make.Real
              (Long_Long_Float'Wide_Wide_Value (Slice));
            OK := True;
         else
            begin
               Value := Yeison.Make.Int
                 (Long_Long_Integer'Wide_Wide_Value (Slice));
               OK := True;
            exception
               when Constraint_Error =>
                  --  An integer-looking literal that overflows
                  --  Long_Long_Integer still has a chance as a float.
                  Value := Yeison.Make.Real
                    (Long_Long_Float'Wide_Wide_Value (Slice));
                  OK := True;
            end;
         end if;
      exception
         when Constraint_Error =>
            Pos := Start;
      end;
   end Scan_Number_Value;

   procedure Skip_To_Semicolon (Image : Text; Pos : in out Idx) is
      --  Recovery after a failed pragma parse. We must honour strings
      --  and comments so a ';' embedded in either does not derail us.
   begin
      while Pos <= Image'Last loop
         if Image (Pos) = ';' then
            Pos := Pos + 1;
            return;
         elsif Image (Pos) = '"' then
            Skip_String_Literal (Image, Pos);
         elsif Image (Pos) = ''' then
            Skip_Char_Literal_If_Any (Image, Pos);
         elsif At_Comment (Image, Pos) then
            Skip_Line_Comment (Image, Pos);
         else
            Pos := Pos + 1;
         end if;
      end loop;
   end Skip_To_Semicolon;

   ------------------
   -- From_Pragmas --
   ------------------

   procedure From_Pragmas (Image   : Text;
                           Builder : in out Output.Builder'Class)
   is
      use all type Yeison.Kinds;

      Acc : Yeison.Any := Yeison.Empty_Map;
      Pos : Idx := Image'First;

      --------------
      -- Has_Key --
      --------------

      function Has_Key (M : Yeison.Any; K : Text) return Boolean is
         --  Linear scan of map keys. Fine for the handful of entries we
         --  realistically deal with here; if this ever needs to scale
         --  the right fix is to maintain a side dedup set.
      begin
         if M.Kind /= Map_Kind then
            return False;
         end if;
         for K_Any of M.Keys loop
            if K_Any.Kind = Str_Kind and then K_Any.As_Text = K then
               return True;
            end if;
         end loop;
         return False;
      end Has_Key;

      --------------------
      -- Record_Pragma --
      --------------------

      procedure Record_Pragma (Name, Key : Text; Value : Yeison.Any) is
         --  Look up (or create) the inner map for Name, then insert the
         --  Key. We take a local copy of the inner map and write it
         --  back via Variable_Indexing because Yeison's by-value access
         --  would otherwise discard our changes.
         Name_Any : constant Yeison.Any := Yeison.Make.Str (Name);
         Key_Any  : constant Yeison.Any := Yeison.Make.Str (Key);
         Inner    : Yeison.Any;
      begin
         if Has_Key (Acc, Name) then
            Inner := Acc (Name_Any);
         else
            Inner := Yeison.Empty_Map;
         end if;

         if Has_Key (Inner, Key) then
            raise Constraint_Error with
              "duplicate pragma key: " & Encode (Name)
              & "." & Encode (Key);
         end if;

         Inner.Insert (Key_Any, Value);
         Acc (Name_Any) := Inner;
      end Record_Pragma;

      ----------------------
      -- Try_Parse_Pragma --
      ----------------------

      procedure Try_Parse_Pragma is
         --  Pos is positioned just past the 'pragma' keyword. On any
         --  mismatch we hand off to Skip_To_Semicolon so the outer loop
         --  can keep finding subsequent pragmas.
         Name_F, Name_L : Idx;
         Key_F,  Key_L  : Idx;
         Value          : Yeison.Any;
         Got_Value      : Boolean;
      begin
         Skip_Trivia (Image, Pos);
         Scan_Identifier (Image, Pos, Name_F, Name_L);
         if Name_L < Name_F then
            Skip_To_Semicolon (Image, Pos);
            return;
         end if;

         Skip_Trivia (Image, Pos);
         if Pos > Image'Last or else Image (Pos) /= '(' then
            Skip_To_Semicolon (Image, Pos);
            return;
         end if;
         Pos := Pos + 1;

         Skip_Trivia (Image, Pos);
         Scan_Identifier (Image, Pos, Key_F, Key_L);
         if Key_L < Key_F then
            Skip_To_Semicolon (Image, Pos);
            return;
         end if;

         Skip_Trivia (Image, Pos);
         if Pos > Image'Last or else Image (Pos) /= ',' then
            --  Catches the named-form `Name => "..."` and any other
            --  shape we do not handle.
            Skip_To_Semicolon (Image, Pos);
            return;
         end if;
         Pos := Pos + 1;

         Skip_Trivia (Image, Pos);
         --  Discriminate the value kind by its first character. Each
         --  Scan_*_Value restores Pos on failure so we cannot end up
         --  half-consuming a value.
         if Pos > Image'Last then
            Skip_To_Semicolon (Image, Pos);
            return;
         elsif Image (Pos) = '"' then
            Scan_String_Value (Image, Pos, Value, Got_Value);
         elsif Is_Id_Start (Image (Pos)) then
            Scan_Bool_Value (Image, Pos, Value, Got_Value);
         else
            Scan_Number_Value (Image, Pos, Value, Got_Value);
         end if;

         if not Got_Value then
            Skip_To_Semicolon (Image, Pos);
            return;
         end if;

         Skip_Trivia (Image, Pos);
         if Pos > Image'Last or else Image (Pos) /= ')' then
            Skip_To_Semicolon (Image, Pos);
            return;
         end if;
         Pos := Pos + 1;

         Skip_Trivia (Image, Pos);
         if Pos > Image'Last or else Image (Pos) /= ';' then
            Skip_To_Semicolon (Image, Pos);
            return;
         end if;
         Pos := Pos + 1;

         Record_Pragma (Image (Name_F .. Name_L),
                        Image (Key_F  .. Key_L),
                        Value);
      end Try_Parse_Pragma;

      First, Last : Idx;
   begin
      loop
         Skip_Trivia (Image, Pos);
         exit when Pos > Image'Last;

         if Image (Pos) = '"' then
            Skip_String_Literal (Image, Pos);

         elsif Image (Pos) = ''' then
            Skip_Char_Literal_If_Any (Image, Pos);

         elsif Is_Id_Start (Image (Pos)) then
            Scan_Identifier (Image, Pos, First, Last);
            declare
               Word : Text renames Image (First .. Last);
            begin
               --  Reaching a unit declaration keyword means we are out
               --  of the pragma-bearing prelude of the file; stop.
               if Equal_CI (Word, "procedure")
                 or else Equal_CI (Word, "function")
                 or else Equal_CI (Word, "generic")
               then
                  exit;
               elsif Equal_CI (Word, "pragma") then
                  Try_Parse_Pragma;
               end if;
               --  Other identifiers (`with`, `package`, type names,
               --  ...) are consumed silently.
            end;

         else
            Pos := Pos + 1;
         end if;
      end loop;

      Output.Build (Acc, Builder);
   end From_Pragmas;

end LML.Input.Pragmas;
