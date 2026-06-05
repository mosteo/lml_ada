with TOML;

with LML.Output.Tree;

package LML.Output.TOML with Preelaborate is

   subtype Parent is Output.Builder;

   type Builder is new Parent with private;

   --  This Builder reconstructs the TOML structure, which can be retrieved if
   --  needed.

   function To_TOML (This : Builder) return Standard.TOML.TOML_Value;

   function Last_Leaf (This : Builder) return Standard.TOML.TOML_Value;
   --  Last table/vector opened, for debug

private

   use Standard.TOML;

   --  Operations for the generic tree builder, with TOML_Value as the node.

   function No_Node return TOML_Value is (No_TOML_Value);

   function Has_Value (N : TOML_Value) return Boolean is (N.Is_Present);

   function Is_Composite (N : TOML_Value) return Boolean
   is (N.Kind in Composite_Value_Kind);

   function Is_Map (N : TOML_Value) return Boolean is (N.Kind = TOML_Table);

   function Empty_Map return TOML_Value is (Create_Table);

   function Empty_Vec return TOML_Value is (Create_Array);

   function New_Scalar (V : Scalar) return TOML_Value;

   function New_Nil return TOML_Value
   is (raise LML.Unsupported_Error with "TOML does not support null values");

   procedure Set_In_Map (Map : in out TOML_Value; Key : Text; Val : TOML_Value);

   procedure Append_To_Vec (Vec : in out TOML_Value; Val : TOML_Value);

   function Image (Root : TOML_Value) return Text
   is (Decode (Root.Dump_As_String));

   package Trees is new Output.Tree
     (Node          => TOML_Value,
      No_Node       => No_Node,
      Has_Value     => Has_Value,
      Is_Composite  => Is_Composite,
      Is_Map        => Is_Map,
      Empty_Map     => Empty_Map,
      Empty_Vec     => Empty_Vec,
      New_Scalar    => New_Scalar,
      New_Nil       => New_Nil,
      Set_In_Map    => Set_In_Map,
      Append_To_Vec => Append_To_Vec,
      Image         => Image);

   type Builder is new Trees.Builder with null record;

   -------------
   -- To_TOML --
   -------------

   function To_TOML (This : Builder) return Standard.TOML.TOML_Value
   is (if This.Has_Root then This.Root_Node
       elsif This.Is_Building then This.First_Open
       else raise Program_Error with "No data");

   ---------------
   -- Last_Leaf --
   ---------------

   function Last_Leaf (This : Builder) return Standard.TOML.TOML_Value
   is (This.Last_Open);

end LML.Output.TOML;
