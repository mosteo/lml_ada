with Yeison_12;

package LML.Output.JSON is

   package Yeison renames Yeison_12;

   subtype Parent is Output.Builder;

   type Builder is new Parent with private;

   procedure Clear (This : in out Builder);

   overriding function To_Text (This : in out Builder) return Text;

private

   package Value_Stacks is new
     Ada.Containers.Indefinite_Doubly_Linked_Lists (Yeison.Any, Yeison."=");

   type Builder is new Parent with record
      Parent : Value_Stacks.List;
      Root   : Yeison.Any := Yeison.Invalid;
   end record;

   overriding function Make return Builder is (others => <>);

   overriding procedure Append_Impl (This : in out Builder; V : Text);

   overriding procedure Begin_Map_Impl (This : in out Builder);

   overriding procedure End_Map_Impl (This : in out Builder);

   overriding procedure Begin_Vec_Impl (This : in out Builder);

   overriding procedure End_Vec_Impl (This : in out Builder);

end LML.Output.JSON;
