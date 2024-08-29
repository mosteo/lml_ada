with TOML;

package LML.Output.TOML is

   subtype Parent is Output.Builder;

   type Builder is new Parent with private;

   procedure Clear (This : in out Builder);

   overriding function To_Text (This : in out Builder) return Text;

   --  This Builder reconstructs the TOML structure, which can be retrieved if
   --  needed.

   function To_TOML (This : Builder) return Standard.TOML.TOML_Value;

   function Last_Leaf (This : Builder) return Standard.TOML.TOML_Value;
   --  Last table/vector opened, for debug

private

   use Standard.TOML;

   package Value_Stacks is new
     Ada.Containers.Indefinite_Doubly_Linked_Lists (TOML_Value);

   type Builder is new Parent with record
      Parent : Value_Stacks.List;
      Root   : TOML_Value := No_TOML_Value;
   end record;

   overriding procedure Append_Impl (This : in out Builder; V : Text);

   overriding procedure Begin_Map_Impl (This : in out Builder);

   overriding procedure End_Map_Impl (This : in out Builder);

   overriding procedure Begin_Vec_Impl (This : in out Builder);

   overriding procedure End_Vec_Impl (This : in out Builder);

   -------------
   -- To_TOML --
   -------------

   function To_TOML (This : Builder) return Standard.TOML.TOML_Value
   is (if This.Root.Is_Present then
          This.Root
       elsif not This.Parent.Is_Empty then
          This.Parent.First_Element
       else raise Program_Error with "No data");

   ---------------
   -- Last_Leaf --
   ---------------

   function Last_Leaf (This : Builder) return Standard.TOML.TOML_Value
   is (if This.Parent.Is_Empty then
          No_TOML_Value
       else
          This.Parent.Last_Element);

end LML.Output.TOML;
