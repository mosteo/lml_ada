with LML.Output;

package LML.Input.Emit with Preelaborate is

   --  Shared scalar-emission helpers used by all input adapters (JSON, TOML
   --  and YAML), wrapping the otherwise repeated Scalars/Reals constructions.

   procedure Append_Bool (Builder : in out Output.Builder'Class;
                          Value   : Boolean);

   procedure Append_Int (Builder : in out Output.Builder'Class;
                         Value   : Yeison.Big_Int);

   procedure Append_Real (Builder : in out Output.Builder'Class;
                          Value   : Yeison.Big_Real);

   procedure Append_Inf (Builder  : in out Output.Builder'Class;
                         Positive : Boolean);

   procedure Append_NaN (Builder : in out Output.Builder'Class);

   procedure Append_Text_UTF8 (Builder : in out Output.Builder'Class;
                               S       : Text_UTF8);
   --  Decodes the UTF-8 image and appends it as a text scalar.

end LML.Input.Emit;
