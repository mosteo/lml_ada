with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Tags;
with Ada.Wide_Wide_Characters.Handling;

with LML.Options.Pragmas;

package body LML.Input.Pragmas is

   --  Best-effort, single-pass scanner. We walk Image with one cursor,
   --  recognise the very small subset of pragma forms documented in the
   --  spec, and silently skip anything else (comments, code, string
   --  literals containing the substring "pragma", malformed pragmas).
   --
   --  A wholly empty pragma `pragma X;` (no parentheses at all) is also
   --  recognised: it records the pragma name with an empty inner map, so
   --  it surfaces as an empty object `{}` rather than being dropped.
   --
   --  Hits are accumulated into nested Ada Indefinite_Ordered_Maps and
   --  handed to the Builder via LML.Output.Build at the end. The Builder
   --  API is forward-only, so we cannot reopen a closed outer map when a
   --  later pragma extends one we have already seen; staging the tree in
   --  Ada containers sidesteps that and gives O(log n) duplicate-key
   --  detection on the inner map for free.
   --
   --  TODO: a Strict parameter is planned (see spec) but the
   --  failure-reporting channel for it is not yet designed.

   package Wide renames Ada.Wide_Wide_Characters.Handling;

   subtype Index        is Positive;
   subtype Index_Or_Nil is Natural;
   --  Index_Or_Nil uses 0 as the "no such index" sentinel: an empty
   --  identifier range (Last < First) or an as-yet-unfound delimiter
   --  position.

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

   -----------------
   -- Is_Id_Start --
   -----------------

   function Is_Id_Start (C : Wide_Wide_Character) return Boolean is
     (C in 'A' .. 'Z' | 'a' .. 'z');

   ----------------
   -- Is_Id_Cont --
   ----------------

   function Is_Id_Cont (C : Wide_Wide_Character) return Boolean is
     (Is_Id_Start (C) or else C in '0' .. '9' | '_');

   --  Greedy class for a numeric literal value. We do not re-implement
   --  the Ada numeric grammar; we gobble anything that *might* belong
   --  to a literal and let 'Wide_Wide_Value vet it. As a side-benefit
   --  this naturally accepts signed forms (-1, +1.5) without modelling
   --  unary operators.

   -----------------
   -- Is_Num_Char --
   -----------------

   function Is_Num_Char (C : Wide_Wide_Character) return Boolean is
     (C in '0' .. '9' | '_' | '.' | '+' | '-' | 'e' | 'E');

   ---------------
   -- Same_Word --
   ---------------
   --  Case-insensitive comparison. Walks A's range and offsets into B
   --  in lockstep so the two slices need not share bounds.
   function Same_Word (A, B : Text) return Boolean is
      Offset : constant Integer := B'First - A'First;
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in A'Range loop
         if Wide.To_Lower (A (I))
              /= Wide.To_Lower (B (I + Offset))
         then
            return False;
         end if;
      end loop;
      return True;
   end Same_Word;

   ------------------
   -- Skip helpers --
   ------------------

   ---------------------
   -- Skip_Whitespace --
   ---------------------

   procedure Skip_Whitespace (Image : Text; Pos : in out Index) is
   begin
      while Pos <= Image'Last
        and then Image (Pos) in ' ' | HT | LF | CR
      loop
         Pos := Pos + 1;
      end loop;
   end Skip_Whitespace;

   -------------
   -- At_Char --
   -------------

   function At_Char (Image : Text;
                     Pos   : Index;
                     C     : Wide_Wide_Character) return Boolean
   is (Pos <= Image'Last and then Image (Pos) = C);

   ----------------
   -- At_Comment --
   ----------------

   function At_Comment (Image : Text; Pos : Index) return Boolean is
     (Pos < Image'Last
        and then Image (Pos) = '-'
        and then Image (Pos + 1) = '-');

   -----------------------
   -- Skip_Line_Comment --
   -----------------------

   procedure Skip_Line_Comment (Image : Text; Pos : in out Index) is
      --  Caller has verified we sit on "--". Stop at LF (not past it);
      --  Skip_Whitespace will consume the newline next.
   begin
      while Pos <= Image'Last and then Image (Pos) /= LF loop
         Pos := Pos + 1;
      end loop;
   end Skip_Line_Comment;

   -----------------
   -- Skip_Trivia --
   -----------------

   procedure Skip_Trivia (Image : Text; Pos : in out Index) is
      Stuck_At : Index;
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

   -------------------------
   -- Skip_String_Literal --
   -------------------------

   procedure Skip_String_Literal (Image : Text; Pos : in out Index) is
      --  Caller has verified Image (Pos) = '"'. Ada source uses "" as
      --  the escaped double-quote inside string literals.
      --  We stop at a line break even without a closing '"': Ada string
      --  literals cannot span lines, so a newline signals a malformed
      --  literal and we must not swallow pragmas on subsequent lines.
   begin
      Pos := Pos + 1;
      while Pos <= Image'Last
        and then Image (Pos) not in LF | CR
      loop
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

   -------------------------------------
   -- Skip_Apostrophe_Or_Char_Literal --
   -------------------------------------

   procedure Skip_Apostrophe_Or_Char_Literal
     (Image : Text; Pos : in out Index)
   is
      --  Heuristic: if we sit on ''' and the third char is also ''',
      --  it is a one-character literal. Otherwise just step past the
      --  apostrophe. Enough to keep contents like '"' or '-' from
      --  confusing the scanner without trying to distinguish attribute
      --  uses (X'Image) from char literals.
   begin
      if Pos + 2 <= Image'Last
        and then Image (Pos) = '''
        and then Image (Pos + 2) = '''
      then
         Pos := Pos + 3;
      else
         Pos := Pos + 1;
      end if;
   end Skip_Apostrophe_Or_Char_Literal;

   ------------------
   -- Scan helpers --
   ------------------

   ---------------------
   -- Scan_Identifier --
   ---------------------

   procedure Scan_Identifier (Image : Text;
                              Pos   : in out Index;
                              First : out Index;
                              Last  : out Index_Or_Nil)
   is
      --  Returns Last < First (an empty range) when there is no
      --  identifier at Pos. Last is Index_Or_Nil so that empty range
      --  can be expressed as Pos - 1 even when Pos = 1.
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

   -----------------------
   -- Scan_String_Value --
   -----------------------

   procedure Scan_String_Value (Image : Text;
                                Pos   : in out Index;
                                Value : out Yeison.Any;
                                OK    : out Boolean)
   is
      --  Two-pass: first locate the closing quote (and notice whether
      --  there are any "" escapes). Then either slice the literal
      --  directly (common case, no escapes) or decode into a buffer
      --  whose worst-case size is the literal's own length.
      Start      : constant Index := Pos;
      Cursor     : Index;
      Has_Escape : Boolean := False;
      End_Quote  : Index_Or_Nil := 0;  --  0 = closing quote not yet found
   begin
      OK := False;
      if not At_Char (Image, Pos, '"') then
         return;
      end if;

      Cursor := Pos + 1;
      while Cursor <= Image'Last
        and then Image (Cursor) not in LF | CR
      loop
         if Image (Cursor) = '"' then
            if Cursor < Image'Last
              and then Image (Cursor + 1) = '"'
            then
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
            Last : Index_Or_Nil := 0;
            I    : Index := Start + 1;
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

   ---------------------
   -- Scan_Bool_Value --
   ---------------------

   procedure Scan_Bool_Value (Image : Text;
                              Pos   : in out Index;
                              Value : out Yeison.Any;
                              OK    : out Boolean)
   is
      --  Recognise True / False as Ada identifiers (case-insensitive,
      --  per Ada rules). On a non-boolean identifier, rewind so the
      --  caller can try another value kind.
      Save  : constant Index := Pos;
      First : Index;
      Last  : Index_Or_Nil;
   begin
      OK := False;
      Scan_Identifier (Image, Pos, First, Last);
      if Last < First then
         return;
      end if;
      if Same_Word (Image (First .. Last), "True") then
         Value := Yeison.Make.Bool (True);
         OK := True;
      elsif Same_Word (Image (First .. Last), "False") then
         Value := Yeison.Make.Bool (False);
         OK := True;
      else
         Pos := Save;
      end if;
   end Scan_Bool_Value;

   -----------------------
   -- Scan_Number_Value --
   -----------------------

   procedure Scan_Number_Value (Image : Text;
                                Pos   : in out Index;
                                Value : out Yeison.Any;
                                OK    : out Boolean)
   is
      --  Greedy gobble then defer to 'Wide_Wide_Value (see comment on
      --  Is_Num_Char above for the rationale). On any conversion failure
      --  we restore Pos so the caller's bail/recovery is well-defined.
      Start : constant Index := Pos;
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
           (for some C of Slice => C in '.' | 'e' | 'E');
      begin
         if Is_Real then
            Value := Yeison.Make.Real
              (Yeison.Reals.New_Real
                 (Long_Long_Float'Wide_Wide_Value (Slice)));
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
                    (Yeison.Reals.New_Real
                       (Long_Long_Float'Wide_Wide_Value (Slice)));
                  OK := True;
            end;
         end if;
      exception
         when Constraint_Error =>
            Pos := Start;
      end;
   end Scan_Number_Value;

   -----------------------
   -- Skip_To_Semicolon --
   -----------------------

   procedure Skip_To_Semicolon (Image : Text; Pos : in out Index) is
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
            Skip_Apostrophe_Or_Char_Literal (Image, Pos);
         elsif At_Comment (Image, Pos) then
            Skip_Line_Comment (Image, Pos);
         else
            Pos := Pos + 1;
         end if;
      end loop;
   end Skip_To_Semicolon;

   --------------------------------
   -- Procedure_Is_Parameterless --
   --------------------------------

   function Procedure_Is_Parameterless (Image    : Text;
                                        After_Kw : Index) return Boolean
   is
      --  After_Kw points just past the "procedure" keyword. Skip the
      --  defining name (including dotted child-unit names) and report whether
      --  a parameter list opens. Only a parameterless procedure can be a
      --  runnable main. We do not advance the caller's cursor: the caller
      --  exits the scan right after classifying the unit.
      Pos   : Index := After_Kw;
      First : Index;
      Last  : Index_Or_Nil;
   begin
      loop
         Skip_Trivia (Image, Pos);
         Scan_Identifier (Image, Pos, First, Last);
         if Last < First then
            --  No name where one was expected; an unparseable header is not a
            --  parameterized procedure, so treat it as parameterless.
            return True;
         end if;
         Skip_Trivia (Image, Pos);
         exit when not At_Char (Image, Pos, '.');
         Pos := Pos + 1;  --  consume '.' and read the child-unit name
      end loop;
      --  A parameter list opens with '('; anything else (is / ; / with /
      --  renames) means the procedure takes no parameters.
      return not At_Char (Image, Pos, '(');
   end Procedure_Is_Parameterless;

   ------------------
   -- From_Pragmas --
   ------------------

   procedure From_Pragmas (Image   : Text;
                           Builder : in out Output.Builder'Class;
                           Unit    : out Ada_Unit;
                           Options : LML.Options.Any'Class :=
                             LML.Options.No_Options)
   is
      use LML.Options.Pragmas;

      function Strict_Names (Opts : LML.Options.Any'Class)
                             return Yeison.Any is
      --  Statement form (not a conditional expression) on purpose: GNAT 15
      --  ICEs on a constant initialized by a conditional expression whose
      --  else branch is `raise ... with ... & External_Tag (...)`.
      --
      --  Returns Yeison.Any rather than Yeison.Vec on purpose too: with
      --  assertions on, GNAT <= 11 evaluates Vec's Dynamic_Predicate on
      --  an already-finalized temporary of the function result, which
      --  dereferences a null Impl and surfaces as Program_Error
      --  "finalize/adjust raised exception" at the Strict declaration
      --  below. Both branches construct vectors anyway.
      begin
         if Opts in LML.Options.Default_No_Options'Class then
            return Yeison.Empty_Vec;
         elsif Opts in Input_Options'Class then
            return Input_Options (Opts).Strict;
         else
            raise Program_Error with
              "unexpected Options type for From_Pragmas: "
              & Ada.Tags.External_Tag (Opts'Tag);
         end if;
      end Strict_Names;

      Strict : constant Yeison.Any := Strict_Names (Options);

      Lower_Case_Keys : constant Boolean :=
        (if Options in Input_Options'Class
         then Input_Options (Options).Lower_Case_Keys
         else No_Input_Options.Lower_Case_Keys);
      --  Falls back to the Input_Options default when none were supplied.
      use type Yeison.Any;  --  brings "=" into scope for Inner_Maps

      package Inner_Maps is new
        Ada.Containers.Indefinite_Ordered_Maps
          (Key_Type     => Text,
           Element_Type => Yeison.Any);

      package Outer_Maps is new
        Ada.Containers.Indefinite_Ordered_Maps
          (Key_Type     => Text,
           Element_Type => Inner_Maps.Map,
           "="          => Inner_Maps."=");

      Acc : aliased Outer_Maps.Map;
      Pos : Index := Image'First;

      ----------------
      -- Normalized --
      ----------------

      function Normalized (Id : Text) return Text
      is (if Lower_Case_Keys then Wide.To_Lower (Id) else Id);
      --  Apply the key-casing policy to an identifier (pragma name or key).

      --------------------
      -- Record_Pragma --
      --------------------

      procedure Record_Pragma (Name, Key : Text; Value : Yeison.Any) is
         --  Insert (4-arg) either creates the inner map or hands us a
         --  cursor to the existing one; we then mutate the inner map
         --  in place via Reference.
         Outer_C  : Outer_Maps.Cursor;
         Inserted : Boolean;
      begin
         Acc.Insert (Name, Inner_Maps.Empty_Map, Outer_C, Inserted);
         declare
            Inner : Inner_Maps.Map renames
              Acc.Reference (Outer_C).Element.all;
         begin
            if Inner.Contains (Key) then
               raise Duplicate_Pragma with
                 "duplicate pragma key: "
                   & Encode (Name) & "." & Encode (Key);
            end if;
            Inner.Insert (Key, Value);
         end;
      end Record_Pragma;

      -------------------------
      -- Record_Empty_Pragma --
      -------------------------

      procedure Record_Empty_Pragma (Name : Text) is
         --  A wholly empty pragma `pragma X;` records the pragma name with
         --  an empty inner map, so it surfaces as an empty object rather
         --  than being dropped. Idempotent: re-declaring `pragma X;`, or
         --  declaring it alongside keyed forms of the same name, neither
         --  overwrites the existing entry nor raises (the 4-arg Insert is a
         --  no-op when Name is already present).
         Outer_C  : Outer_Maps.Cursor;
         Inserted : Boolean;
      begin
         Acc.Insert (Name, Inner_Maps.Empty_Map, Outer_C, Inserted);
      end Record_Empty_Pragma;

      ----------------------
      -- Try_Parse_Pragma --
      ----------------------

      procedure Try_Parse_Pragma is
         --  Pos is positioned just past the 'pragma' keyword. On any
         --  mismatch we hand off to Skip_To_Semicolon so the outer loop
         --  can keep finding subsequent pragmas.

         function Consume (C : Wide_Wide_Character) return Boolean is
            --  Skip trivia, then advance past one expected character.
         begin
            Skip_Trivia (Image, Pos);
            if not At_Char (Image, Pos, C) then
               return False;
            end if;
            Pos := Pos + 1;
            return True;
         end Consume;

         Name_F    : Index;
         Name_L    : Index_Or_Nil;
         Key_F     : Index;
         Key_L     : Index_Or_Nil;
         Value     : Yeison.Any;
         Got_Value : Boolean := False;
         Is_Strict : Boolean := False;

         procedure Bail is
            --  On a strict pragma, raise instead of silently skipping.
         begin
            if Is_Strict then
               raise LML.Invalid_Pragma_Syntax with
                 "failed to parse strict pragma: "
                 & Encode (Image (Name_F .. Name_L));
            end if;
            Skip_To_Semicolon (Image, Pos);
         end Bail;

      begin
         Skip_Trivia (Image, Pos);
         Scan_Identifier (Image, Pos, Name_F, Name_L);
         if Name_L < Name_F then
            Skip_To_Semicolon (Image, Pos);
            return;
         end if;

         --  Determine whether this pragma name is in the Strict list.
         for I in 1 .. Strict.Length loop
            if Same_Word (Image (Name_F .. Name_L),
                          Strict (Yeison.Make.Int
                            (Long_Long_Integer (I))).As_Text)
            then
               Is_Strict := True;
               exit;
            end if;
         end loop;

         Skip_Trivia (Image, Pos);
         if At_Char (Image, Pos, ';') then
            --  Wholly empty pragma `pragma X;` records the name with an
            --  empty inner map, surfacing as an empty object `{}` rather
            --  than being dropped.
            Pos := Pos + 1;
            Record_Empty_Pragma (Normalized (Image (Name_F .. Name_L)));
            return;
         end if;

         if not Consume ('(') then
            Bail;
            return;
         end if;

         Skip_Trivia (Image, Pos);
         Scan_Identifier (Image, Pos, Key_F, Key_L);
         if Key_L < Key_F then
            Bail;
            return;
         end if;

         Skip_Trivia (Image, Pos);
         if At_Char (Image, Pos, ')') then
            --  Valueless form `pragma X (Key);` yields Nil.
            Pos := Pos + 1;
            Value     := Yeison.Make.Nil;
            Got_Value := True;
         elsif Pos + 1 <= Image'Last
           and then Image (Pos) = '='
           and then Image (Pos + 1) = '>'
         then
            --  Named form `pragma X (Key => Value);` is accepted as
            --  equivalent to the positional `(Key, Value)` form.
            Pos := Pos + 2;
         elsif not Consume (',') then
            --  Catches any other shape we do not handle.
            Bail;
            return;
         end if;

         if not Got_Value then
            Skip_Trivia (Image, Pos);
            --  Discriminate the value kind by its first character. Each
            --  Scan_*_Value restores Pos on failure so we cannot end up
            --  half-consuming a value.
            if Pos > Image'Last then
               Bail;
               return;
            elsif Image (Pos) = '"' then
               Scan_String_Value (Image, Pos, Value, Got_Value);
            elsif Is_Id_Start (Image (Pos)) then
               Scan_Bool_Value (Image, Pos, Value, Got_Value);
            else
               Scan_Number_Value (Image, Pos, Value, Got_Value);
            end if;

            if not Got_Value then
               Bail;
               return;
            end if;

            if not Consume (')') then
               Bail;
               return;
            end if;
         end if;

         if not Consume (';') then
            Bail;
            return;
         end if;

         Record_Pragma (Normalized (Image (Name_F .. Name_L)),
                        Normalized (Image (Key_F  .. Key_L)),
                        Value);
      end Try_Parse_Pragma;

   begin
      Unit := Unknown;
      loop
         Skip_Trivia (Image, Pos);
         exit when Pos > Image'Last;

         if Image (Pos) = '"' then
            Skip_String_Literal (Image, Pos);

         elsif Image (Pos) = ''' then
            Skip_Apostrophe_Or_Char_Literal (Image, Pos);

         elsif Is_Id_Start (Image (Pos)) then
            declare
               First : Index;
               Last  : Index_Or_Nil;
            begin
               Scan_Identifier (Image, Pos, First, Last);
               declare
                  Word : Text renames Image (First .. Last);
               begin
                  --  The first unit-declaration keyword ends the
                  --  pragma-bearing prelude; classify it and stop. `separate`
                  --  must be recognized before the `procedure`/`function` it
                  --  precedes in a subunit.
                  if Same_Word (Word, "package") then
                     Unit := Package_Unit;
                     exit;
                  elsif Same_Word (Word, "function") then
                     Unit := Function_Unit;
                     exit;
                  elsif Same_Word (Word, "generic") then
                     Unit := Generic_Unit;
                     exit;
                  elsif Same_Word (Word, "separate") then
                     Unit := Separate_Unit;
                     exit;
                  elsif Same_Word (Word, "procedure") then
                     Unit :=
                       (if Procedure_Is_Parameterless (Image, Pos)
                        then Procedure_Without_Parameters
                        else Procedure_With_Parameters);
                     exit;
                  elsif Same_Word (Word, "pragma") then
                     Try_Parse_Pragma;
                  end if;
                  --  Other identifiers (`with`, `use`, type names, ...) are
                  --  consumed silently.
               end;
            end;

         else
            Pos := Pos + 1;
         end if;
      end loop;

      --  Hand the accumulated tree to the Builder. Building the outer
      --  map here (rather than incrementally above) means insertion
      --  order matches the iteration order of Acc (alphabetical), not
      --  source order. Good enough; revisit if needed.
      declare
         Result : Yeison.Any := Yeison.Empty_Map;
      begin
         for Outer_C in Acc.Iterate loop
            declare
               Inner     : Inner_Maps.Map renames
                 Acc.Constant_Reference (Outer_C).Element.all;
               Inner_Any : Yeison.Any := Yeison.Empty_Map;
            begin
               for Inner_C in Inner.Iterate loop
                  Inner_Any.Insert
                    (Yeison.Make.Str (Inner_Maps.Key (Inner_C)),
                     Inner_Maps.Element (Inner_C));
               end loop;
               Result.Insert
                 (Yeison.Make.Str (Outer_Maps.Key (Outer_C)),
                  Inner_Any);
            end;
         end loop;
         Output.Build (Result, Builder);
      end;
   end From_Pragmas;

   ------------------
   -- From_Pragmas --
   ------------------

   procedure From_Pragmas (Image   : Text;
                           Builder : in out Output.Builder'Class;
                           Options : LML.Options.Any'Class :=
                             LML.Options.No_Options)
   is
      Ignored : Ada_Unit;
   begin
      From_Pragmas (Image, Builder, Ignored, Options);
   end From_Pragmas;

end LML.Input.Pragmas;
