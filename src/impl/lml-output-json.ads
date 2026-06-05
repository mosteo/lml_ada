with Yeison_12;

with LML.Output.Tree;

package LML.Output.JSON with Preelaborate is

   package Yeison renames Yeison_12;

   subtype Parent is Output.Builder;

   type Builder is new Parent with private;

   --  To_Text (overridden in the generic base) and the Output.Builder
   --  primitives are inherited; nothing format-specific is added here.

private

   use type Yeison.Kinds;

   --  Operations for the generic tree builder, with Yeison.Any as the node.

   function No_Node return Yeison.Any is (Yeison.Make.Nil);

   function Has_Value (N : Yeison.Any) return Boolean is (N.Has_Value);

   function Is_Composite (N : Yeison.Any) return Boolean
   is (N.Kind in Yeison.Composite_Kinds);

   function Is_Map (N : Yeison.Any) return Boolean
   is (N.Kind = Yeison.Map_Kind);

   function New_Scalar (Val : Scalar) return Yeison.Any
   is (Yeison.Make.Scalar (Val));

   function New_Nil return Yeison.Any is (Yeison.Make.Nil);

   function Image (Root : Yeison.Any) return Text
   is (Root.Image (Format => Yeison.JSON));

   procedure Set_In_Map
     (Map : in out Yeison.Any; Key : Text; Val : Yeison.Any);

   procedure Append_To_Vec (Vec : in out Yeison.Any; Val : Yeison.Any);

   package Trees is new Output.Tree
     (Node          => Yeison.Any,
      No_Node       => No_Node,
      Has_Value     => Has_Value,
      Is_Composite  => Is_Composite,
      Is_Map        => Is_Map,
      Empty_Map     => Yeison.Empty_Map,
      Empty_Vec     => Yeison.Empty_Vec,
      New_Scalar    => New_Scalar,
      New_Nil       => New_Nil,
      Set_In_Map    => Set_In_Map,
      Append_To_Vec => Append_To_Vec,
      Image         => Image);

   type Builder is new Trees.Builder with null record;

end LML.Output.JSON;
