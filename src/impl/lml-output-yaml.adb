with Ada.Characters.Wide_Wide_Latin_1;

with Yeison_Utils;

package body LML.Output.YAML is

   package Chars renames Ada.Characters.Wide_Wide_Latin_1;

   -------------
   -- To_List --
   -------------

   function To_List (Structure : Structures) return Stacks.List is
   begin
      return List : Stacks.List do
         List.Append (Structure);
      end return;
   end To_List;

   -------
   -- S --
   -------

   function S (This : UText) return Text
               renames To_Wide_Wide_String;

   ------------
   -- Append --
   ------------

   procedure Append (This : in out Builder; Str : Text) is
   begin
      Append (This.Result, Str);
   end Append;

   --------------
   -- New_Line --
   --------------

   procedure New_Line (This : in out Builder) is
   begin
      Append (This.Result, Chars.LF);
   end New_Line;

   ---------
   -- Tab --
   ---------

   function Tab (This : Builder) return Text
   is (S (Integer'Max (0, This.Depth) * "  "));

   ------------
   -- Indent --
   ------------

   procedure Indent (This : in out Builder) is
   begin
      Append (This.Result, This.Tab);
   end Indent;

   ------------------
   -- Array_Marker --
   ------------------

   procedure Array_Marker (This : in out Builder) is
   begin
      This.Indent;
      This.Append ("- ");
   end Array_Marker;

   -------------------
   -- Append_Scalar --
   -------------------

   procedure Append_Scalar (This : in out Builder; Val : Scalar) is
      use all type Yeison.Kinds;
   begin
      case Val.Kind is
         when Str_Kind =>
            Append (This.Result,
                    Yeison_Utils.YAML_Double_Quote_Escape (Val.As_Text));
         when others =>
            Append (This.Result, Yeison.Make.Scalar (Val).Image);
      end case;
   end Append_Scalar;

   -----------------
   -- Append_Impl --
   -----------------

   overriding procedure Append_Impl (This : in out Builder; Val : Scalar) is
   begin
      case This.Stack.Last_Element is
         when Root =>
            This.Append_Scalar (Val);
         when Map =>
            This.Append (" ");
            This.Append_Scalar (Val);
         when List =>
            This.Array_Marker;
            This.Append_Scalar (Val);
      end case;

      This.New_Line;
   end Append_Impl;

   -----------------
   -- Insert_Impl --
   -----------------

   overriding procedure Insert_Impl (This : in out Builder; K : Text) is
   begin
      if This.Stack.Last_Element = Root then
         raise Constraint_Error with "Cannot insert key with unopenend map";
      elsif This.Stack.Last_Element /= Map then
         raise Constraint_Error with "Cannot insert key with opened list";
      end if;

      This.Indent;
      This.Append (Yeison_Utils.YAML_Double_Quote_Escape (K));
      This.Append (":");
      This.Keys.Delete_Last;
   end Insert_Impl;

   --------------------
   -- Begin_Map_Impl --
   --------------------

   overriding procedure Begin_Map_Impl (This : in out Builder) is
      Parent : constant Structures := This.Stack.Last_Element;
   begin
      This.Stack.Append (Map);
      case Parent is
         when List =>
            This.Array_Marker;
            This.New_Line;
         when Map =>
            This.New_Line;
         when Root =>
            null;
      end case;
      This.Depth := This.Depth + 1;
   end Begin_Map_Impl;

   ------------------
   -- End_Map_Impl --
   ------------------

   overriding procedure End_Map_Impl (This : in out Builder) is
   begin
      if This.Stack.Last_Element = Root then
         raise Constraint_Error with "Attempt to end map when stack is empty";
      elsif This.Stack.Last_Element /= Map then
         raise Constraint_Error with "Attempt to end map when list is open";
      else
         This.Stack.Delete_Last;
         This.Depth := This.Depth - 1;
      end if;
   end End_Map_Impl;

   --------------------
   -- Begin_Vec_Impl --
   --------------------

   overriding procedure Begin_Vec_Impl (This : in out Builder) is
      Parent : constant Structures := This.Stack.Last_Element;
   begin
      This.Stack.Append (List);
      case Parent is
         when List =>
            This.Array_Marker;
            This.New_Line;
         when Map =>
            This.New_Line;
         when Root =>
            null;
      end case;
      This.Depth := This.Depth + 1;
   end Begin_Vec_Impl;

   ------------------
   -- End_Vec_Impl --
   ------------------

   overriding procedure End_Vec_Impl (This : in out Builder) is
   begin
      if This.Stack.Is_Empty then
         raise Constraint_Error with "Attempt to end list when stack is empty";
      elsif This.Stack.Last_Element /= List then
         raise Constraint_Error with "Attempt to end list when map is open";
      else
         This.Stack.Delete_Last;
         This.Depth := This.Depth - 1;
      end if;
   end End_Vec_Impl;

end LML.Output.YAML;
