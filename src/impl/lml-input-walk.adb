package body LML.Input.Walk is

   ----------
   -- Walk --
   ----------

   procedure Walk (N : Node; Builder : in out Output.Builder'Class) is

      ------------------
      -- Process_Pair --
      ------------------

      procedure Process_Pair (Key : Text; Value : Node) is
      begin
         Builder.Insert (Key);
         Walk (Value, Builder);
      end Process_Pair;

      ------------------
      -- Process_Item --
      ------------------

      procedure Process_Item (Value : Node) is
      begin
         Walk (Value, Builder);
      end Process_Item;

   begin
      case Classify (N) is
         when Scalar =>
            Emit_Scalar (N, Builder);

         when Map =>
            Builder.Begin_Map;
            Iterate_Pairs (N, Process_Pair'Access);
            Builder.End_Map;

         when Vec =>
            Builder.Begin_Vec;
            Iterate_Items (N, Process_Item'Access);
            Builder.End_Vec;
      end case;
   end Walk;

end LML.Input.Walk;
