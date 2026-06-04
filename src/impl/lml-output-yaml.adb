with Ada.Characters.Wide_Wide_Latin_1;

with Yeison_Utils;

package body LML.Output.YAML is

   package Chars renames Ada.Characters.Wide_Wide_Latin_1;

   -------------
   -- To_Text --
   -------------

   overriding function To_Text (This : Builder) return Text
   is (if This.Result /= "" and then Tail (This.Result, 1) = "" & Chars.LF
       then To_Wide_Wide_String (Head (This.Result, Length (This.Result) - 1))
       else To_Wide_Wide_String (This.Result));

   ---------------
   -- Set_Style --
   ---------------

   procedure Set_Style (This : in out Builder; Style : Styles) is
   begin
      This.Style := Style;
   end Set_Style;

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

   ----------------
   -- Flush_Open --
   ----------------

   procedure Flush_Open (This : in out Builder) is
      --  A deferred map-value collection turned out to have content: emit the
      --  newline we held back so the items go in block style below the key.
   begin
      if This.Pending_Open then
         This.Pending_Open := False;
         This.New_Line;
      end if;
   end Flush_Open;

   -----------------
   -- Apply_Style --
   -----------------

   procedure Apply_Style (This : in out Builder) is
   begin
      case This.Style is
         when Compact =>
            --  Keep the child inline after the bullet: a single separating
            --  space (the bullet itself carries none).
            This.Append (" ");
            This.Inline := True;
         when Expanded =>
            --  Break the line; no space is emitted, so the bullet leaves no
            --  trailing whitespace.
            This.New_Line;
      end case;
   end Apply_Style;

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
      if This.Inline then
         This.Inline := False;
      else
         Append (This.Result, This.Tab);
      end if;
   end Indent;

   ------------------
   -- Array_Marker --
   ------------------

   procedure Array_Marker (This : in out Builder) is
   begin
      This.Indent;
      --  Just the bullet; the separating space (or line break) is added by
      --  whatever writes the element, so an Expanded bullet has no trailing
      --  whitespace.
      This.Append ("-");
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

   ---------------------
   -- Append_Nil_Impl --
   ---------------------

   overriding procedure Append_Nil_Impl (This : in out Builder) is
   begin
      --  This nil is the content of a possibly-deferred collection: commit its
      --  held-back newline before writing the item.
      This.Flush_Open;
      case This.Stack.Last_Element is
         when Root =>
            --  A bare scalar document needs the explicit '---' marker to be a
            --  valid standalone YAML document (AdaYaml rejects it otherwise),
            --  with the value on its own line.
            This.Append ("---");
            This.New_Line;
            This.Append ("~");
         when Map =>
            This.Append (" ~");
         when List =>
            This.Array_Marker;
            This.Append (" ~");
      end case;
      This.New_Line;
   end Append_Nil_Impl;

   -----------------
   -- Append_Impl --
   -----------------

   overriding procedure Append_Impl (This : in out Builder; Val : Scalar) is
   begin
      --  This value is the content of a possibly-deferred collection: commit
      --  its held-back newline before writing the item.
      This.Flush_Open;
      case This.Stack.Last_Element is
         when Root =>
            --  A bare scalar document needs the explicit '---' marker to be a
            --  valid standalone YAML document (AdaYaml rejects it otherwise),
            --  with the value on its own line.
            This.Append ("---");
            This.New_Line;
            This.Append_Scalar (Val);
         when Map =>
            This.Append (" ");
            This.Append_Scalar (Val);
         when List =>
            This.Array_Marker;
            This.Append (" ");
            This.Append_Scalar (Val);
      end case;

      This.New_Line;
   end Append_Impl;

   -----------------
   -- Insert_Impl --
   -----------------

   overriding procedure Insert_Impl (This : in out Builder; K : Text) is
   begin
      --  This key is the first content of a possibly-deferred map: commit its
      --  held-back newline before writing the key.
      This.Flush_Open;
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
      --  Nested map: content of a deferred parent, so flush its newline.
      This.Flush_Open;
      This.Stack.Append (Map);
      case Parent is
         when List =>
            This.Array_Marker;
            This.Apply_Style;
         when Map =>
            --  Defer the newline: if this map stays empty it must render as
            --  "{}" on the key line rather than a bare "key:" (which re-parses
            --  as null).
            This.Pending_Open := True;
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
         --  Still pending means no key was inserted: an empty map. Render it
         --  inline as "{}" so it round-trips instead of becoming null.
         if This.Pending_Open then
            This.Pending_Open := False;
            This.Append (" {}");
            This.New_Line;
         end if;
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
      --  Nested vec: content of a deferred parent, so flush its newline.
      This.Flush_Open;
      This.Stack.Append (List);
      case Parent is
         when List =>
            This.Array_Marker;
            This.Apply_Style;
         when Map =>
            --  Defer the newline: if this vec stays empty it must render as
            --  "[]" on the key line rather than a bare "key:" (which re-parses
            --  as null).
            This.Pending_Open := True;
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
         --  Still pending means no element was appended: an empty vec. Render
         --  it inline as "[]" so it round-trips instead of becoming null.
         if This.Pending_Open then
            This.Pending_Open := False;
            This.Append (" []");
            This.New_Line;
         end if;
         This.Stack.Delete_Last;
         This.Depth := This.Depth - 1;
      end if;
   end End_Vec_Impl;

end LML.Output.YAML;
