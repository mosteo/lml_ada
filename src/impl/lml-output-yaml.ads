private with Ada.Containers.Doubly_Linked_Lists;
private with Ada.Strings.Wide_Wide_Unbounded;

package LML.Output.YAML with Preelaborate is

   subtype Parent is Output.Builder;

   type Builder is new Parent with private;

   overriding function To_Text (This : Builder) return Text;

private

   package Value_Stacks is new
     Ada.Containers.Indefinite_Doubly_Linked_Lists (Yeison.Any, Yeison."=");

   use Ada.Strings.Wide_Wide_Unbounded;
   subtype UText is Unbounded_Wide_Wide_String;

   type Structures is (Root, Map, List);

   package Stacks is new Ada.Containers.Doubly_Linked_Lists (Structures);

   function To_List (Structure : Structures) return Stacks.List;

   type Builder is new Parent with record
      Depth  : Integer := -1;
      Result : UText;
      Stack  : Stacks.List := To_List (Root);
   end record with
     Type_Invariant => not Stack.Is_Empty;

   overriding function Make return Builder is (others => <>);

   overriding procedure Insert_Impl (This : in out Builder; K : Text);

   overriding procedure Append_Impl (This : in out Builder; Val : Scalar);

   overriding procedure Begin_Map_Impl (This : in out Builder);

   overriding procedure End_Map_Impl (This : in out Builder);

   overriding procedure Begin_Vec_Impl (This : in out Builder);

   overriding procedure End_Vec_Impl (This : in out Builder);

   -------------
   -- To_Text --
   -------------

   overriding function To_Text (This : Builder) return Text
   is (To_Wide_Wide_String (This.Result));

end LML.Output.YAML;
