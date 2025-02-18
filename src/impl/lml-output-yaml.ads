private with Ada.Containers.Doubly_Linked_Lists;
private with Ada.Strings.Wide_Wide_Unbounded;

package LML.Output.YAML with Preelaborate is

   subtype Parent is Output.Builder;

   type Builder is new Parent with private;

   overriding function To_Text (This : Builder) return Text;

   type Styles is
     (Compact, -- Default
      --  The first element of an array is always in the same line as the '-'.
      --  For nested arrays it can be somewhat confusing, but it is what is
      --  usually seen in hand-produced documents.

      Expanded
      --  Arrays of non-scalars always have a standalone '-' in its own line.
      --  This favors understanding the hierarchy (similar to JSON style).

      --  Arrays of scalars are always in compact mode.
     );

   procedure Set_Style (This : in out Builder; Style : Styles);

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
      Inline : Boolean := False; -- Whether next item goes in the same line
      Style  : Styles  := Compact;
   end record with
     Type_Invariant => not Stack.Is_Empty;

   overriding function Make return Builder is (others => <>);

   overriding procedure Insert_Impl (This : in out Builder; K : Text);

   overriding procedure Append_Impl (This : in out Builder; Val : Scalar);

   overriding procedure Begin_Map_Impl (This : in out Builder);

   overriding procedure End_Map_Impl (This : in out Builder);

   overriding procedure Begin_Vec_Impl (This : in out Builder);

   overriding procedure End_Vec_Impl (This : in out Builder);

end LML.Output.YAML;
