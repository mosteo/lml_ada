with Yeison_12;

package LML.Output.JSON with Preelaborate is

   package Yeison renames Yeison_12;

   subtype Parent is Output.Builder;

   type Builder is new Parent with private;

   procedure Clear (This : in out Builder);

   overriding function To_Text (This : Builder) return Text;

private

   package Value_Stacks is new
     Ada.Containers.Indefinite_Doubly_Linked_Lists (Yeison.Any, Yeison."=");

   type Builder is new Parent with record
      Stack : Value_Stacks.List;
      --  Values as we go building them. When a value is completed, it is
      --  inserted in its parent.
      Root  : Yeison.Any;
      --  Whatever remains after completion
   end record with
     Type_Invariant => (if not Stack.Is_Empty then not Root.Is_Valid);

   -------------------
   -- Current_Value --
   -------------------

   function Current_Root (This : Builder) return Yeison.Any
   is (if This.Root.Is_Valid
       then This.Root
       else This.Stack.First_Element);

   overriding function Make return Builder is (others => <>);

   overriding procedure Append_Impl (This : in out Builder; Val : Scalar);

   overriding procedure Begin_Map_Impl (This : in out Builder);

   overriding procedure End_Map_Impl (This : in out Builder);

   overriding procedure Begin_Vec_Impl (This : in out Builder);

   overriding procedure End_Vec_Impl (This : in out Builder);

end LML.Output.JSON;
