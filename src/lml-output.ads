private with Ada.Containers.Indefinite_Doubly_Linked_Lists;

package LML.Output with Preelaborate is

   type Builder is tagged private;

   procedure Insert (This : in out Builder'Class; K : Text);
   --  Creates the key for the next element in a table

   procedure Append (This : in out Builder'Class; Val : Scalar);
   --  Appends a value to a vector, or provides the value for the previous key

   procedure Begin_Map (This : in out Builder'Class);

   procedure End_Map (This : in out Builder'Class);

   procedure Begin_Vec (This : in out Builder'Class);

   procedure End_Vec (This : in out Builder'Class);

   function To_Text (This : Builder) return Text
   is (raise Program_Error with "must be overriden");

   function Make return Builder
   is (raise Program_Error with "must be overriden");

   --  Other conveniences

   procedure Build (This    : Yeison.Any;
                    Builder : in out Output.Builder'Class);

   function To_Builder (This   : Yeison.Any;
                        Format : Formats)
                        return Builder'Class;
   --  Returns a builder that already has processed This (To_Text will
   --  immediately return the image of This).

private

   package Key_Stacks is
     new Ada.Containers.Indefinite_Doubly_Linked_Lists (Text);

   procedure Insert_Impl (This : in out Builder; K : Text) is null;

   procedure Append_Impl (This : in out Builder; Val : Scalar) is null;

   procedure Begin_Map_Impl (This : in out Builder) is null;

   procedure End_Map_Impl (This : in out Builder) is null;

   procedure Begin_Vec_Impl (This : in out Builder) is null;

   procedure End_Vec_Impl (This : in out Builder) is null;

   procedure On_Completion (This : in out Builder) is null;

   type Builder is tagged record
      Level : Natural := 0;
      First : Boolean := True;
      Keys  : Key_Stacks.List;
   end record;

   function Pop (This : in out Builder'Class) return Text;
   --  Removes and returns the first pending key to be inserted in parent table

   --  Following subprograms are intended to simplify outputting "on the fly",
   --  not needed for outputters that build the data structure in memory.

   -------------------
   -- Current_Level --
   -------------------

   function Current_Level (This : Builder'Class) return Natural
   is (This.Level);

   ----------------------------
   -- Is_First_In_Collection --
   ----------------------------

   function Is_First_In_Collection (This : Builder'Class) return Boolean
   is (This.First);

end LML.Output;
