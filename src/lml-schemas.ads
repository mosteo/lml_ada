private with Ada.Strings.Wide_Wide_Unbounded;

with Yeison_12;

package LML.Schemas with Preelaborate is

   --  Validate a Yeison value (the data) against a schema, where the schema
   --  is itself a Yeison value following JSON Schema 2020-12 semantics (a
   --  common subset; see the package body and README for what is covered).
   --
   --  Both Data and Schema are plain Yeison values: the schema's original
   --  textual format (JSON, YAML, ...) is irrelevant here. Callers typically
   --  obtain them via LML.From_Text.
   --
   --  A schema is either a boolean (true accepts everything, false rejects
   --  everything) or a map of keywords. Reporting is first-failure only: the
   --  result tells whether the data is valid and, if not, carries a single
   --  message locating the first violation.
   --
   --  Schema keywords that are not implemented and could mask an invalid
   --  document (notably $ref) raise LML.Unsupported_Error, so callers can
   --  distinguish "data is invalid" from "schema uses an unsupported
   --  feature". Pure annotations (description, default, examples, ...) are
   --  ignored.

   package Yeison renames Yeison_12;

   type Result (<>) is tagged private;
   --  To be able to apply the following methods

   function Is_Valid (This : Result) return Boolean;

   function Error (This : Result) return Text;
   --  Empty when This is valid; otherwise a message of the form
   --  "<instance-path>: <reason>" locating the first violation, e.g.
   --  "/Alire_Test/Timeout: expected number, found String".

   function Validate (Data, Schema : Yeison.Any) return Result;

private

   package WWU renames Ada.Strings.Wide_Wide_Unbounded;

   --  A default discriminant keeps the type mutable, so the body can use a
   --  single Result accumulator and overwrite it as keywords are checked.
   type Result_Data (Valid : Boolean := True) is record
      case Valid is
         when True  => null;
         when False => Message : WWU.Unbounded_Wide_Wide_String;
      end case;
   end record;

   type Result is tagged record
      Data : Result_Data;
   end record;

   function Is_Valid (This : Result) return Boolean is (This.Data.Valid);

   function Error (This : Result) return Text
   is (if This.Data.Valid
       then ""
       else WWU.To_Wide_Wide_String (This.Data.Message));

end LML.Schemas;
