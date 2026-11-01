pragma Alire_Test;
with LML.Input.JSON;

with Lml_Tests.Support;

--  Non-ASCII text in JSON strings, escaped or not, and big input in UTF-8. Bytes
--  in 16#80# .. 16#9F# are part of UTF-8 sequences here, unlike in Latin-1.

procedure Lml_Tests.Json_Unicode is

   use Lml_Tests.Support;

   function Parsed (JSON_String : String) return Yeison.Any
   is (LML.Input.JSON.From_UTF_8 ("""" & JSON_String & """"));

   N_Tilde : constant String :=
               Character'Val (16#C3#) & Character'Val (16#B1#);
   Euro    : constant String :=
               Character'Val (16#E2#) & Character'Val (16#82#)
               & Character'Val (16#AC#);
   Emoji   : constant String :=
               Character'Val (16#F0#) & Character'Val (16#9F#)
               & Character'Val (16#98#) & Character'Val (16#80#);
   Replacement : constant String :=
               Character'Val (16#EF#) & Character'Val (16#BF#)
               & Character'Val (16#BD#);

   procedure Check (JSON_String, Expected : String) is
   begin
      Assert (Parsed (JSON_String).As_UTF_8 = Expected,
              "unexpected value for string: " & JSON_String);
   end Check;

begin
   --  As-is

   Check (N_Tilde, N_Tilde);
   Check (Euro, Euro);
   Check (Emoji, Emoji);

   --  Escaped, in the one, two and three bytes UTF-8 ranges

   Check ("\u0041", "A");
   Check ("\u00f1", N_Tilde);
   Check ("\u00F1", N_Tilde);
   Check ("\u20ac", Euro);
   Check ("a\u003cb\u003ec", "a<b>c");

   --  As a surrogate pair, for four bytes in UTF-8

   Check ("\ud83d\ude00", Emoji);
   Check ("x\uD83D\uDE00y", "x" & Emoji & "y");

   --  Unpaired surrogates are replaced, as UTF-8 cannot represent them

   Check ("\ud83d", Replacement);
   Check ("\ude00", Replacement);
   Check ("\ud83dx", Replacement & "x");
   Check ("\ud83d\u0041", Replacement & "A");

   --  Other escapes keep working next to these

   Check ("\\u0041", "\u0041");
   Check ("\u0041\n", "A" & Character'Val (10));

   --  Big input does not exhaust the stack, and takes no quadratic time to
   --  build (this would take minutes otherwise).

   declare
      Element : constant String := "{""key"":""value""},";
      Count   : constant := 100_000;

      type String_Access is access String;
      Input : constant String_Access :=
                new String (1 .. Element'Length * Count);
   begin
      for I in 0 .. Count - 1 loop
         Input (I * Element'Length + 1 .. (I + 1) * Element'Length) := Element;
      end loop;

      declare
         Value : constant Yeison.Any := LML.Input.JSON.From_UTF_8
           ("[" & Input (Input'First .. Input'Last - 1) & "]");
      begin
         Assert (Natural (Value.Length) = Count, "unexpected length");
         Assert (At_Key (At_Index (Value, Count), "key").As_UTF_8 = "value",
                 "unexpected value in last element");
      end;
   end;
end Lml_Tests.Json_Unicode;
