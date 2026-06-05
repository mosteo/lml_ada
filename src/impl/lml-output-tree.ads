private with Ada.Containers.Indefinite_Doubly_Linked_Lists;

generic
   type Node is private;

   with function No_Node return Node;
   --  The "no value yet" sentinel for the still-unset Root.

   with function Has_Value (N : Node) return Boolean;
   --  False for the No_Node sentinel / an unset root.

   with function Is_Composite (N : Node) return Boolean;
   with function Is_Map (N : Node) return Boolean;
   --  Kind tests on an existing node (Is_Map distinguishes the open parent).

   with function Empty_Map return Node;
   with function Empty_Vec return Node;
   with function New_Scalar (Val : Scalar) return Node;
   with function New_Nil return Node;
   --  Node constructors. New_Nil may raise for formats without null support.

   with procedure Set_In_Map (Map : in out Node; Key : Text; Val : Node);
   with procedure Append_To_Vec (Vec : in out Node; Val : Node);

   with function Image (Root : Node) return Text;
   --  Final rendering of a completed structure.

package LML.Output.Tree with Preelaborate is

   --  Shared in-memory tree-building base for the JSON and TOML output
   --  builders: it owns the stack of in-progress collections and the Root, and
   --  implements the dispatching Output.Builder primitives in terms of the
   --  format-specific node operations above. Collections are inserted into
   --  their parent on completion (insert-at-End), which works for both value
   --  (Yeison) and reference (TOML) node semantics.

   type Builder is new Output.Builder with private;

   overriding function To_Text (This : Builder) return Text;

   procedure Clear (This : in out Builder);

   --  Accessors used by the concrete builders (To_Yeison, To_TOML, Last_Leaf).

   function Has_Root (This : Builder) return Boolean;

   function Root_Node (This : Builder) return Node;

   function Is_Building (This : Builder) return Boolean;
   --  True while at least one collection is still open.

   function First_Open (This : Builder) return Node;
   function Last_Open (This : Builder) return Node;
   --  Outermost / innermost open collection (No_Node if none).

private

   package Node_Stacks is new
     Ada.Containers.Indefinite_Doubly_Linked_Lists (Node);

   type Builder is new Output.Builder with record
      Stack : Node_Stacks.List;
      --  Collections being built; completed ones move into their parent.
      Root  : Node := No_Node;
      --  Whatever remains once the structure is complete.
   end record;

   overriding function Make return Builder is (others => <>);

   overriding procedure Append_Impl (This : in out Builder; Val : Scalar);
   overriding procedure Append_Nil_Impl (This : in out Builder);
   overriding procedure Begin_Map_Impl (This : in out Builder);
   overriding procedure End_Map_Impl (This : in out Builder);
   overriding procedure Begin_Vec_Impl (This : in out Builder);
   overriding procedure End_Vec_Impl (This : in out Builder);

end LML.Output.Tree;
