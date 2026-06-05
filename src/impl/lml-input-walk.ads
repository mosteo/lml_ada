with LML.Output;

package LML.Input.Walk with Preelaborate is

   type Walk_Category is (Scalar, Map, Vec);
   --  Tree nodes are either leaves (any scalar, emitted by the format-specific
   --  Emit_Scalar) or one of the two collection kinds the walker recurses on.

   generic
      type Node (<>) is private;

      with function Classify (N : Node) return Walk_Category;

      with procedure Emit_Scalar (N       : Node;
                                  Builder : in out Output.Builder'Class);
      --  Format-specific leaf emission (covers e.g. TOML Inf/NaN). Built on
      --  LML.Input.Emit.

      with procedure Iterate_Pairs
             (N       : Node;
              Process : not null access
                          procedure (Key : Text; Value : Node));
      --  Visits each key/value pair of a map node in order.

      with procedure Iterate_Items
             (N       : Node;
              Process : not null access procedure (Value : Node));
      --  Visits each element of an array node in order.

   procedure Walk (N : Node; Builder : in out Output.Builder'Class);
   --  Recursively drives Builder from the parsed tree rooted at N.

end LML.Input.Walk;
