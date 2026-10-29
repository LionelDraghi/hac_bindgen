--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Serialization.Store                      Summer, 2026       --
--  Separate body                                                     --
--                                Last revision :  19:35 03 Aug 2026  --
--                                                                    --
--  This  library  is  free software; you can redistribute it and/or  --
--  modify it under the terms of the GNU General Public  License  as  --
--  published by the Free Software Foundation; either version  2  of  --
--  the License, or (at your option) any later version. This library  --
--  is distributed in the hope that it will be useful,  but  WITHOUT  --
--  ANY   WARRANTY;   without   even   the   implied   warranty   of  --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU  --
--  General  Public  License  for  more  details.  You  should  have  --
--  received  a  copy  of  the GNU General Public License along with  --
--  this library; if not, write to  the  Free  Software  Foundation,  --
--  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.    --
--                                                                    --
--  As a special exception, if other files instantiate generics from  --
--  this unit, or you link this unit with other files to produce  an  --
--  executable, this unit does not by  itself  cause  the  resulting  --
--  executable to be covered by the GNU General Public License. This  --
--  exception  does not however invalidate any other reasons why the  --
--  executable file might be covered by the GNU Public License.       --
--____________________________________________________________________--

with Strings_Edit.Integers;  use Strings_Edit.Integers;

separate (Parsers.Ada_Syntax_Analyzer.Serialization)
   procedure Store
             (  Stream : in out Root_Stream_Type'Class;
                Tree   : Tokens.Argument_Token;
                Offset : in out Stream_Element_Offset;
                Trace  : File_Access := null;
                Prefix : String      := ""
             )  is
   procedure Put (Item : Tokens.Argument_Token);
   procedure Put (Item : Natural);
   procedure Put (Item : Subtype_Indication);
   procedure Put (List : Subtype_Indication_Array);
   procedure Put (Item : Subtype_Mark);
   procedure Put (List : Subtype_Mark_Array);

   function Is_Library_Context (Location : Context_Location)
      return Boolean is
   begin
      if Location.Context = null then
         return False;
      elsif Location.Context.all in Declaration_Context then
         return Declaration_Context (Location.Context.all).Kind_Of =
                Library_Unit_Context;
      else
         return False;
      end if;
   end Is_Library_Context;

   procedure Put (List : Argument_List) is
   begin
      for Index in List'Range loop
         Put (List (Index));
      end loop;
   end Put;

   procedure Put (List : Aspect_Items_Array) is
      procedure Put (This : Global_Aspect_Element) is
      begin
         Put
         (  Boolean'Pos (This.Extended)
         +  (  2
            *  (  Global_Designator_Mode'Pos (This.Kind_Of)
               +  (  Global_Designator_Mode_Mod
                  *  (  Basic_Global_Mode'Pos (This.Mode)
                     +  (  Basic_Global_Mode_Mod
                        *  This.Names_Count
         )  )  )  )  )  );
         case This.Kind_Of is
            when All_Designator_Mode          |
                 Synchronized_Designator_Mode =>
               null;
            when Global_Name_Designator_Mode =>
               Put (This.List);
         end case;
      end Put;

      procedure Put (List : Global_Aspect_Element_Ptr_Array) is
      begin
         for Index in List'Range loop
            Put (List (Index).all);
         end loop;
      end Put;

      procedure Put (This : Aspect_Specification_Item) is
      begin
         Put
         (  Aspect_Designator_Type'Pos (This.Mode)
         +  Aspect_Designator_Type_Mod * This.Elements_Count
         );
         Put (This.Mark);
         case This.Mode is
            when Value_Designator =>
               Put (This.Value);
            when No_Designator          |
                 Null_Designator        |
                 Unspecified_Designator =>
               null;
            when Global_Designator =>
               Put (This.Designator.all);
            when Global_Aspect_Elements_List_Designator =>
               Put (This.List);
         end case;
      end Put;
   begin
      for Index in List'Range loop
         Put (List (Index).all);
      end loop;
   end Put;

   procedure Put (Item : Array_Type_Definition) is
   begin
      Put
      (  Boolean'Pos (Item.Aliased_Component) + Item.Dimension * 2
      );
      Put (Item.Component);
      Put (Item.Indices);
   end Put;

   procedure Put (Item : Defining_Identifier) is
   begin
      Put (Item.Term);
      if Trace /= null then
         Put_Line
         (  Trace.all,
            Prefix & "   " & Image (Offset) &
            "Declared "    & Image (Item.Declared)
         );
      end if;
   end Put;

   procedure Put (List : Defining_Identifier_Array) is
   begin
      for Index in List'Range loop
         Put (List (Index));
      end loop;
   end Put;

   procedure Put (List : Guarded_List) is
   begin
      for Index in List'Range loop
         Put (List (Index).Guard);
         Put (List (Index).Value);
      end loop;
   end Put;

   procedure Put (Item : Location) is
      use Line_Number_Serialization;
   begin
      Put (Stream, Offset, Item.First.Line);
      Put (Item.First.Column);
      Put (Stream, Offset, Item.Next.Line);
      Put (Item.Next.Column);
   end Put;

   procedure Put (Item : Natural) is
      use Integer_Number_Serialization;
   begin
      Put (Stream, Offset, Item);
   end Put;

   procedure Put (Item : Subtype_Indication) is
   begin
      Put
      (  Boolean'Pos (Item.Not_Null)
      +  (  2
         *  (  Stubtype_Indication_Mode'Pos (Item.Mode)
            +  (  Stubtype_Indication_Mode_Mod
               *  Subtype_Constraint_Mode'Pos (Item.Constraint.Mode)
      )  )  )  );
      Put (Item.Mark);
      case Item.Constraint.Mode is
         when No_Constraint =>
            null;
         when Fixed_Point_Constraint =>
            Put (Item.Constraint.Delta_Constraint);
         when Floating_Point_Constraint =>
            Put (Item.Constraint.Digits_Constraint);
         when Index_Constraint | Discriminant_Constraint =>
            Put (Item.Constraint.Constraint);
      end case;
      case Item.Mode is
         when Subtype_Range_Mode =>
            Put (Item.Range_Constraint);
         when Range_Mode | Subtype_Mode | Unconstrained_Mode =>
            null;
      end case;
   end Put;

   procedure Put (List : Subtype_Indication_Array) is
   begin
      for Index in List'Range loop
         Put (List (Index));
      end loop;
   end Put;

   procedure Put (Item : Subtype_Mark) is
   begin
      Put (Constraint_Attribute'Pos (Item.Attribute));
      Put (Item.Name);
      case Item.Attribute is
         when Dimension_Range_Attribute =>
            Put (Item.Dimension);
         when others =>
            null;
      end case;
   end Put;

   procedure Put (List : Subtype_Mark_Array) is
   begin
      for Index in List'Range loop
         Put (List (Index));
      end loop;
   end Put;

   procedure Put (Item : Tokens.Argument_Token) is
   begin
      Store
      (  Stream => Stream,
         Tree   => Item,
         Offset => Offset,
         Trace  => Trace,
         Prefix => Prefix & "   "
      );
   end Put;

   procedure Put (Item : Unbounded_Unsigned) is
      Value     : Unbounded_Unsigned := Item;
      Remainder : Half_Word;
      Buffer    : Stream_Element_Array (1..1);
   begin
      loop
         Div (Value, 128, Remainder);
         Buffer (1) := Stream_Element (Remainder);
         if Is_Zero (Value) then
            Write (Stream, Buffer);
            return;
         end if;
         Buffer (1) := Buffer (1) or 16#80#;
         Write (Stream, Buffer);
      end loop;
   end Put;

   procedure Put (Item : Unbounded_Integer) is
      Buffer : Stream_Element_Array (1..1);
   begin
      if Is_Negative (Item) then
         Buffer (1) := 1;
      else
         Buffer (1) := 0;
      end if;
      Write (Stream, Buffer);
      Put (Get_Mantissa (Item));
   end Put;

   procedure Put (Item : Unbounded_Rational) is
      Buffer : Stream_Element_Array (1..1);
   begin
      if Is_Negative (Item) then
         Buffer (1) := 1;
      else
         Buffer (1) := 0;
      end if;
      Write (Stream, Buffer);
      Put (Get_Numerator (Item));
      Put (Get_Denominator (Item));
   end Put;

   procedure Put_Named_Term (Item : Named_Term'Class) is
      Length : Natural := Item.Value'Length * 2;
   begin
      if Item.Malformed then
         Length := Length + 1;
      end if;
      Put (Length);
      String'Write (Stream'Access, Item.Value);
      Offset := Offset + Item.Value'Length;
   end Put_Named_Term;

   procedure Put_Numeric_Literal (Item : Numeric_Literal'Class) is
   begin
      Put_Named_Term (Item);
      Put (Item.Base);
      if Item.Exponent >= 0 then
         Put (Item.Exponent * 2);
      else
         Put ((-Item.Exponent) * 2 + 1);
      end if;
   end Put_Numeric_Literal;

   procedure Put_Program_Node (This : Program_Node'Class) is
      Tag : constant Program_Node_Class := Get_Class (This);

      procedure Put (This : Declaration_Context);
      procedure Put (This : Handled_Statement_Sequence);
      procedure Put (This : Identifier_List);
      procedure Put (Item : Object_Specification);
      procedure Put (Item : Parameter_Profile; Unit : Boolean);
      procedure Put (Item : Parameter_Specification);
      procedure Put (Item : Parameter_Type);
      procedure Put (Item : Singleton_Parameter; Unit : Boolean);
      procedure Put (This : Statement_Sequence);
      procedure Put (This : Variant_Part_Item);
      procedure Put_Body (Item : Abstract_Body'Class);
      procedure Put_Compilation_Context
                (  Item : Compilation_Context'Class;
                   Unit : Boolean
                );
      procedure Put_Formal_Parameter (Item : Formal_Parameter'Class);
      procedure Put_Formal_Type_Parameter
                (  Item : Formal_Type_Parameter'Class
                );
      procedure Put_Formal_Subprogram_Parameter
                (  Item : Formal_Subprogram_Parameter'Class
                );
      procedure Put_Instantiation (Item : Abstract_Instantiation'Class);
      procedure Put_Labels (Item : Abstract_Statement_Node'Class);
      procedure Put_Loop (Item : Abstract_Loop_Statement'Class);
      procedure Put_Renaming (Item : Abstract_Renaming'Class);
      procedure Put_Scalar_Type (Item : Scalar_Type_Definition'Class);
      procedure Put_Stub (Item : Abstract_Stub'Class);
      procedure Put_Subroutine_Body (Item : Subroutine_Body'Class);
      procedure Put_Subprogram_Renaming
                (  Item : Subprogram_Renaming'Class
                );
      procedure Put_Subprogram_Specification
                (  Item : Subprogram_Specification'Class
                );
      procedure Put_Subprogram_Stub (Item : Subprogram_Stub'Class);
      procedure Put_Type (Item : Abstract_Type_Declaration'Class);
      procedure Put_Context_Clause (Item : Context_Clause'Class);

      procedure Put (This : Abort_Statement) is
      begin
         Put (This.Labels'Length);
         Put (This.Tasks'Length);
         Put (This.Tasks);
         Put_Labels (This);
      end Put;

      procedure Put (This : Accept_Statement) is
      begin
         Put
         (  Boolean'Pos (This.Is_Family)
         +  (  2
            *  (  Boolean'Pos (This.Sequence = null)
               +  (  2
                  *  (  Boolean'Pos (This.Profile = null)
                     +  (  2
                        *  This.Labels_Count
         )  )  )  )  )  );
         Put (This.Name);
         if This.Index.Present then
            Put (This.Index.Item);
         end if;
         if This.Profile /= null then
            Put (This.Profile.all, False);
         end if;
         if This.Sequence /= null then
            Put (This.Sequence.all);
         end if;
         Put_Labels (This);
      end Put;

      procedure Put (Item : Anonymous_Access_Definition) is
      begin
         case Item.Mode is
            when Access_To_All..Access_To_Variable =>
               Put
               (  Boolean'Pos (Item.Not_Null)
               +  (  4
                  *  Access_Mode'Pos (Item.Mode)
               )  );
               Put (Item.Object);
            when Access_To_Subprogram_Mode =>
               Put
               (  Boolean'Pos (Item.Not_Null)
               +  (  2
                  *  (  Boolean'Pos (Item.Profile = null)
                     +  (  2
                        *  Access_Mode'Pos (Item.Mode)
               )  )  )  );
               if Item.Profile /= null then
                  Put (Item.Profile.all, False);
               end if;
               case Item.Mode is
                  when Access_To_Function           |
                       Access_To_Protected_Function =>
                     Put (Item.Result.all);
                  when others =>
                     null;
               end case;
         end case;
      end Put;

      procedure Put (Item : Array_Type_Specification) is
      begin
         Put
         (  Boolean'Pos (Item.Aliased_Component)
         +  (  2
            *  (  Mode_Type'Pos (Item.Mode)
               +  (  Mode_Type_Mod
                  *  Item.Dimension
         )  )  )  );
         Put (Item.Indices);
         case Item.Mode is
            when Access_Mode =>
               Put (Item.Access_Component);
            when Object_Mode =>
               Put (Item.Object_Component);
         end case;
      end Put;

      procedure Put (This : Access_Type_Declaration) is
      begin
         Put
         (  Mode_Type'Pos (This.Mode)
         +  (  Mode_Type_Mod
            *  This.Aspects_Count
         )  );
         Put (This.Pointer);
         Put_Type (This);
      end Put;

      procedure Put (This : Array_Type_Declaration) is
      begin
         Put (This.Aspects_Count);
         Put (This.Definition.all);
         Put_Type (This);
      end Put;

      procedure Put (This : Assignment_Statement) is
      begin
         Put (This.Labels'Length);
         Put (This.Variable);
         Put (This.Expression);
         Put_Labels (This);
      end Put;

      procedure Put (This : Asynchronous_Transfer_Control) is
      begin
         Put
         (  Boolean'Pos (This.Triggered = null)
         +  (  2
            *  This.Labels'Length
         )  );
         Put_Program_Node (This.Trigger.all);
         Put (This.Abortable.all);
         if This.Triggered /= null then
            Put (This.Triggered.all);
         end if;
         Put_Labels (This);
      end Put;

      procedure Put (This : At_Clause) is
      begin
         Put (This.Address);
         Put (This.Name);
         Put (This.Location);
      end Put;

      procedure Put (This : Attribute_Definition_Clause) is
      begin
         Put (This.Attribute);
         Put (This.Value);
         Put (This.Name);
         Put (This.Location);
      end Put;

      procedure Put (This : Block_Statement) is
      begin
         Put
         (  Boolean'Pos (This.Named)
         +  (  2
            *  (  Boolean'Pos (This.Declarations = null)
               +  (  2
                  *  This.Labels'Length
         )  )  )  );
         if This.Declarations /= null then
            Put (This.Declarations.all);
         end if;
         Put (This.Sequence.all);
         if This.Name.Present then
            Put (This.Name.Item);
         end if;
         Put_Labels (This);
      end Put;

      procedure Put (This : Call_Statement) is
      begin
         Put (This.Labels'Length);
         Put (This.Target);
         Put_Labels (This);
      end Put;

      procedure Put (This : Case_Statement) is
         procedure Put (This : Choice_Alternative) is
         begin
            Put (This.Choice'Length);
            Put (This.Choice.all);
            Put (This.Code.all);
         end Put;
      begin
         Put
         (  Boolean'Pos (This.Default = null)
         +  (  2
            *  This.Labels'Length
         )  );
         Put (This.Count);
         Put (This.Selector);
         if This.Default /= null then
            Put (This.Default.all);
         end if;
         for Index in This.Alternatives'Range loop
            Put (This.Alternatives (Index));
         end loop;
         Put_Labels (This);
      end Put;

      procedure Put (This : Chunk_Specification) is
      begin
         case This.Mode is
            when Chunk_Any =>
               null;
            when Chunk_Parameter =>
               Put (This.Name, False);
            when Chunk_Expression =>
               Put (This.Value);
         end case;
         Put (This.Location);
      end Put;

      procedure Put (This : Conditional_Entry_Call) is
      begin
         Put
         (  Boolean'Pos (This.Accepted_Code = null)
         +  (  2
            *  This.Labels'Length
         )  );
         Put_Program_Node (This.Entry_Call.all);
         Put (This.Rejected_Code.all);
         if This.Accepted_Code /= null then
            Put (This.Accepted_Code.all);
         end if;
         Put_Labels (This);
      end Put;

      procedure Put (This : Context_Location) is
      begin
         if This.Context = null then
            Put (0);
         elsif Is_Library_Unit (This) then
            Put (Declaration_Context (This.Context.all));
         else
            Put (0);
         end if;
      end Put;

      procedure Put (This : Decimal_Fixed_Point_Type_Declaration) is
      begin
         Put (Boolean'Pos (This.Constrained) + 2 * This.Aspects_Count);
         Put (This.Delta_Value);
         Put (This.Digits_Value);
         Put_Scalar_Type (This);
      end Put;

      procedure Put (This : Declaration_Context) is
         Length  : Natural := 0;
         Library : constant Boolean := Is_Library_Context (This.Parent);
      begin
         if This.Declarations /= null then
            Length := This.Declarations'Length;
         end if;
         Put
         (  Boolean'Pos (Library)
         +  (  2
            *  (  Compilation_Context_Type'Pos (This.Kind_Of)
               +  (  Compilation_Context_Type_Mod
                  *  Length
         )  )  )  );
         if Library then
            Put (Declaration_Context (This.Parent.Context.all));
         end if;
         if Trace /= null then
            Put (Trace.all, Prefix & Image (Offset));
            Put_Line
            (  Trace.all,
               "Declaration_Context " &
               Image (This.Kind_Of)   &
               ", items "             &
               Image (Length)
            );
         end if;
         for Index in This.Declarations'Range loop
            Put_Program_Node (This.Declarations (Index).all);
         end loop;
         Put (This.Location);
         Put (This.Scope);
      end Put;

      procedure Put (This : Delay_Statement) is
      begin
         Put
         (  Boolean'Pos (This.Relative)
         +  2 * This.Labels'Length
         );
         Put (This.Time);
         Put_Labels (This);
      end Put;

      procedure Put (This : Derived_Type_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Abstract_Type)
         +  (  2
            *  (  Boolean'Pos (This.Limited_Type)
               +  (  2
                  *  (  Boolean'Pos (This.Extension_Record)
                     +  (  2
                        *  (  Boolean'Pos (This.Discriminants = null)
                           +  (  2
                              *  Boolean'Pos
                                 (  This.Extension_Record
                                 and then
                                    This.Extension = null
         )  )  )  )  )  )  )  )  );
         Put (This.Aspects_Count);
         Put (This.Interfaces_Count);
         Put (This.Parent_Type);
         if This.Discriminants /= null then
            Put (This.Discriminants.all, False);
         end if;
         Put (This.Interfaces);
         if This.Extension_Record and then This.Extension /= null then
            Put (This.Extension.all);
         end if;
         Put_Type (This);
      end Put;

      procedure Put (List : Guarded_Alternatives_Array) is
      begin
         for Index in List'Range loop
            Put (List (Index).Guard);
            Put (List (Index).Code.all);
         end loop;
      end Put;

      procedure Put (This : Enumeration_Representation_Clause) is
      begin
         Put (This.Enumeration_Count);
         Put (This.Enumeration);
         Put (This.Name);
         Put (This.Location);
      end Put;

      procedure Put (This : Enumeration_Type_Declaration) is
      begin
         Put (This.Aspects_Count);
         Put (This.List_Length);
         Put (This.List);
         Put_Type (This);
      end Put;

      procedure Put (This : Entry_Body) is
      begin
         Put
         (  Boolean'Pos (This.Has_Index)
         +  (  2
            *  (  Boolean'Pos (This.Profile = null)
               +  (  2
                  *  (  Overriding_Indicator_Type'Pos (This.Overrides)
                     +  (  Overriding_Indicator_Type_Mod
                        *  This.Aspects_Count
         )  )  )  )  )  );
         if This.Profile /= null then
            Put (This.Profile.all, False);
         end if;
         Put (This.Declarations.all);
         Put (This.Code.all);
         Put (This.Barrier);
         if This.Index.Present then
            Put (This.Index.Item);
         end if;
         Put_Body (This);
      end Put;

      procedure Put (This : Entry_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Is_Family)
         +  (  2
            *  (  Boolean'Pos (This.Profile = null)
               +  (  2
                  *  (  Overriding_Indicator_Type'Pos (This.Overrides)
                     +  (  Overriding_Indicator_Type_Mod
                        *  This.Aspects_Count
         )  )  )  )  )  );
         Put (This.Name);
         if This.Profile /= null then
            Put (This.Profile.all, False);
         end if;
         if This.Index.Present then
            Put (This.Index.Item);
         end if;
         Put (This.Aspects);
         Put (This.Location);
      end Put;

      procedure Put (This : Exception_Declaration) is
      begin
         Put (This.Count);
         Put (This.Aspects_Count);
         Put (This.Names);
         Put (This.Aspects);
         Put (This.Location);
      end Put;

      procedure Put (This : Exception_Handler) is
      begin
         Put
         (  Boolean'Pos (This.Has_Parameter)
         +  This.Choices_Count * 2
         );
         Put (This.Sequence.all);
         Put (This.Choices);
         if This.Has_Parameter then
            Put (This.Parameter, False);
         end if;
      end Put;

      procedure Put (This : Exception_Renaming) is
      begin
         Put (This.Aspects_Count);
         Put_Renaming (This);
      end Put;

      procedure Put (This : Exit_Statement) is
      begin
         Put
         (  Boolean'Pos (This.Named)
         +  (  2
            *  (  Boolean'Pos (This.Conditional)
               +  (  2
                  *  (  Boolean'Pos (This.Loop_Of = null)
                     +  (  2
                        *  This.Labels'Length
         )  )  )  )  )  );
         if This.Named then
            Put (This.Loop_Name.Item);
         end if;
         if This.Conditional then
            Put (This.Condition.Item);
         end if;
         Put_Labels (This);
      end Put;

      procedure Put (This : Extended_Return_Statement) is
      begin
         Put
         (  Boolean'Pos (This.Initialized)
         +  (  2
            *  (  Boolean'Pos (This.Code = null)
               +  (  2
                  *  This.Labels'Length
         )  )  )  );
         Put (This.Result, False);
         if This.Code /= null then
            Put (This.Code.all);
         end if;
         if This.Initial.Present then
            Put (This.Initial.Item);
         end if;
         Put_Labels (This);
      end Put;

      procedure Put (This : Floating_Point_Type_Declaration) is
      begin
         Put (Boolean'Pos (This.Constrained) + 2 * This.Aspects_Count);
         Put (This.Digits_Value);
         Put_Scalar_Type (This);
      end Put;

      procedure Put (This : For_Loop_Statement) is
         Parameter  : Boolean;
         Chunk_Mode : Natural;
      begin
         case This.Mode is
            when In_Interation_Mode | Of_Interation_Mode =>
               Parameter := This.In_Reverse;
            when Formal_Part_Mode =>
               Parameter := This.Formal_Part = null;
            when List_Mode =>
               Parameter := This.Iterator = null;
         end case;
         if This.Chunk = null then
            Chunk_Mode := Chunk_Specification_Type_Mod - 1;
         else
            Chunk_Mode :=
               Chunk_Specification_Type'Pos (This.Chunk.Mode);
         end if;
         Put
         (  Boolean'Pos (This.Named)
         +  (  2
            *  (  Boolean'Pos (This.Has_Iterator_Filter)
               +  (  2
                  *  (  Boolean'Pos (Parameter)
                     +  (  2
                        *  This.Labels'Length
         )  )  )  )  )  );
         Put
         (  Chunk_Mode
         +  (  Chunk_Specification_Type_Mod
            *  (  Iterator_Mode'Pos (This.Mode)
               +  (  Iterator_Mode_Mod
                  *  This.Aspects_Count
         )  )  )  );
         if This.Chunk /= null then
            Put (This.Chunk.all);
         end if;
         if This.Iterator_Filter.Present then
            Put (This.Iterator_Filter.Item);
         end if;
         case This.Mode is
            when In_Interation_Mode | Of_Interation_Mode =>
               Put (This.Parameter, False);
               Put (This.Iterator_Subtype);
            when Formal_Part_Mode | List_Mode =>
               Put (This.Iterator_Call);
               case This.Mode is
                  when In_Interation_Mode | Of_Interation_Mode =>
                     null;
                  when Formal_Part_Mode =>
                     if This.Formal_Part /= null then
                        Put (This.Formal_Part.all, False);
                     end if;
                  when List_Mode =>
                     if This.Iterator /= null then
                        Put (This.Iterator.all);
                     end if;
               end case;
         end case;
         Put (This.Aspects);
         Put_Loop (This);
      end Put;

      procedure Put (This : Formal_Access_Type_Parameter) is
      begin
         Put
         (  Boolean'Pos (This.Not_Null)
         +  (  2
            *  (  Boolean'Pos (This.Defaulted)
               +  (  2
                  *  Mode_Type'Pos (This.Mode)
         )  )  )  );
         Put (This.Aspects_Count);
         Put (This.Pointer);
         Put_Formal_Type_Parameter (This);
      end Put;

      procedure Put (This : Formal_Array_Type_Parameter) is
      begin
         Put
         (  Boolean'Pos (This.Defaulted)
         +  (  2
            *  This.Aspects_Count
         )  );
         Put (This.Definition.all);
         Put_Formal_Type_Parameter (This);
      end Put;

      procedure Put (This : Formal_Derived_Type_Parameter) is
      begin
         Put
         (  Boolean'Pos (This.Abstract_Type)
         +  (  2
            *  (  Boolean'Pos (This.With_Private)
               +  (  2
                  *  (  Boolean'Pos (This.Defaulted)
                     +  (  2
                        *  This.Aspects_Count
         )  )  )  )  )  );
         Put
         (  Boolean'Pos (This.Discriminants = null)
         +  (  2
            *  (  Derived_Interface_Type'Pos (This.Mode)
               +  (  Derived_Interface_Type_Mod
                  *  This.Interfaces_Count
         )  )  )  );
         Put (This.Parent_Type);
         if This.Discriminants /= null then
            Put (This.Discriminants.all, False);
         end if;
         Put (This.Interfaces);
         Put_Formal_Type_Parameter (This);
      end Put;

      procedure Put (This : Formal_Function_Parameter) is
      begin
         Put
         (  Boolean'Pos (This.Abstract_Subprogram)
         +  (  2
            *  (  Boolean'Pos (This.Profile = null)
               +  (  2
                  *  (  Formal_Subprogram_Default_Type'Pos
                           (This.Default)
                     +  (  Formal_Subprogram_Default_Type_Mod
                        *  This.Aspects_Count
         )  )  )  )  )  );
         Put (This.Result.all);
         Put_Formal_Subprogram_Parameter (This);
      end Put;

      procedure Put (This : Formal_Incomplete_Type_Parameter) is
      begin
         Put
         (  Boolean'Pos (This.Tagged_Type)
         +  (  2
            *  (  Boolean'Pos (This.Defaulted)
               +  (  2
                  *  (  Boolean'Pos (This.Discriminants = null)
         )  )  )  )  );
         if This.Discriminants /= null then
            Put (This.Discriminants.all, False);
         end if;
         Put_Formal_Type_Parameter (This);
      end Put;

      procedure Put (This : Formal_Interface_Type_Parameter) is
      begin
         Put
         (  Boolean'Pos (This.Defaulted)
         +  (  2
            *  (  Boolean'Pos (This.Discriminants = null)
               +  (  2
                  *  This.Aspects_Count
         )  )  )  );
         Put
         (  Interface_Type'Pos (This.Mode)
         +  (  Interface_Type_Mod
            *  This.Interfaces_Count
         )  );
         if This.Discriminants /= null then
            Put (This.Discriminants.all, False);
         end if;
         Put (This.Interfaces);
         Put_Formal_Type_Parameter (This);
      end Put;

      procedure Put (This : Formal_Package_Parameter) is
      begin
         Put (This.Aspects_Count);
         Put (This.Target);
         Put_Formal_Parameter (This);
      end Put;

      procedure Put (This : Formal_Procedure_Parameter) is
      begin
         Put
         (  Boolean'Pos (This.Abstract_Subprogram)
         +  (  2
            *  (  Boolean'Pos (This.Profile = null)
               +  (  2
                  *  (  Formal_Subprogram_Default_Type'Pos
                           (This.Default)
                     +  (  Formal_Subprogram_Default_Type_Mod
                        *  This.Aspects_Count
         )  )  )  )  )  );
         Put_Formal_Subprogram_Parameter (This);
      end Put;

      procedure Put (This : Formal_Private_Type_Parameter) is
      begin
         Put
         (  Boolean'Pos (This.Discriminants = null)
         +  (  2
            *  (  Boolean'Pos (This.Abstract_Type)
               +  (  2
                  *  (  Boolean'Pos (This.Limited_Type)
                     +  (  2
                        *  (  Boolean'Pos (This.Tagged_Type)
                           +  (  2
                              *  Boolean'Pos (This.Defaulted)
         )  )  )  )  )  )  )  );
         Put (This.Aspects_Count);
         if This.Discriminants /= null then
            Put (This.Discriminants.all, False);
         end if;
         Put_Formal_Type_Parameter (This);
      end Put;

      procedure Put (This : Formal_Scalar_Type_Parameter) is
      begin
         Put
         (  Boolean'Pos (This.Defaulted)
         +  (  2
            *  (  Formal_Scalar_Type'Pos (This.Kind_Of)
               +  (  Formal_Scalar_Type_Mod
                  *  This.Aspects_Count
         )  )  )  );
         Put_Formal_Type_Parameter (This);
      end Put;

      procedure Put (This : Function_Body) is
      begin
         Put
         (  Boolean'Pos (This.Separate_Body)
         +  (  2
            *  (  Boolean'Pos (This.Profile = null)
               +  (  2
                  *  (  Overriding_Indicator_Type'Pos (This.Overrides)
                     +  (  Overriding_Indicator_Type_Mod
                        *  This.Aspects_Count
         )  )  )  )  )  );
         Put_Subroutine_Body (This);
         Put (This.Result.all);
      end Put;

      procedure Put (This : Function_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Private_Unit)
         +  (  2
            *  (  Boolean'Pos (This.Generic_Unit)
               +  (  2
                  *  (  Boolean'Pos (This.Abstract_Subprogram)
                     +  (  2
                        *  (  Boolean'Pos (This.Profile = null)
                           +  (  2
                              *  Overriding_Indicator_Type'Pos
                                 (  This.Overrides
         )  )  )  )  )  )  )  )  );
         Put (This.Aspects_Count);
         Put_Subprogram_Specification (This);
         Put (This.Result.all);
      end Put;

      procedure Put (This : Function_Expression) is
      begin
         Put
         (  Boolean'Pos (This.Profile = null)
         +  (  2
            *  (  Overriding_Indicator_Type'Pos (This.Overrides)
               +  (  Overriding_Indicator_Type_Mod
                  *  This.Aspects_Count
         )  )  )  );
         if This.Profile /= null then
            Put (This.Profile.all, False);
         end if;
         Put (This.Name);
         Put (This.Result.all);
         Put (This.Expression);
         Put (This.Aspects);
         Put (This.Location);
      end Put;

      procedure Put (This : Function_Instantiation) is
      begin
         Put
         (  Overriding_Indicator_Type'Pos (This.Overrides)
         +  (  Overriding_Indicator_Type_Mod
            *  This.Aspects_Count
         )  );
         Put_Instantiation (This);
      end Put;

      procedure Put (This : Function_Renaming) is
      begin
         Put
         (  Boolean'Pos (This.Private_Unit)
         +  (  2
            *  (  Boolean'Pos (This.Generic_Unit)
               +  (  2
                  *  (  Boolean'Pos (This.Profile = null)
                     +  (  2
                        *  Overriding_Indicator_Type'Pos
                           (  This.Overrides
         )  )  )  )  )  )  );
         Put (This.Aspects_Count);
         Put_Subprogram_Renaming (This);
         Put (This.Result.all);
      end Put;

      procedure Put (This : Function_Stub) is
      begin
         Put
         (  Boolean'Pos (This.Profile = null)
         +  (  2
            *  (  Overriding_Indicator_Type'Pos (This.Overrides)
               +  (  Overriding_Indicator_Type_Mod
                  *  This.Aspects_Count
         )  )  )  );
         Put (This.Result.all);
         Put_Subprogram_Stub (This);
      end Put;

      procedure Put (This : Goto_Statement) is
      begin
         Put (This.Labels_Count);
         Put (This.Name);
         Put_Labels (This);
      end Put;

      procedure Put (This : If_Statement) is
      begin
         Put (Boolean'Pos (This.Default = null) + 2 * This.Count);
         Put (This.Labels_Count);
         if This.Default /= null then
            Put (This.Default.all);
         end if;
         Put (This.Alternatives);
         Put_Labels (This);
      end Put;

      procedure Put (This : Loop_Statement) is
      begin
         Put (Boolean'Pos (This.Named) + 2 * This.Labels_Count);
         Put_Loop (This);
      end Put;

      procedure Put (This : Modular_Type_Declaration) is
      begin
         Put (Boolean'Pos (This.Constrained) + 2 * This.Aspects_Count);
         Put (This.Modulus);
         Put_Scalar_Type (This);
      end Put;

      procedure Put (This : Null_Procedure) is
      begin
         Put
         (  Boolean'Pos (This.Private_Unit)
         +  (  2
            *  (  Boolean'Pos (This.Generic_Unit)
               +  (  2
                  *  (  Boolean'Pos (This.Abstract_Subprogram)
                     +  (  2
                        *  (  Boolean'Pos (This.Profile = null)
                           +  (  2
                              *  Overriding_Indicator_Type'Pos
                                 (  This.Overrides
         )  )  )  )  )  )  )  )  );
         Put (This.Aspects_Count);
         Put_Subprogram_Specification (This);
      end Put;

      procedure Put (This : Null_Statement) is
      begin
         Put (This.Labels_Count);
         Put_Labels (This);
      end Put;

      procedure Put (This : Handled_Statement_Sequence) is
      begin
         Put (This.List'Length);
         Put (This.Handlers'Length);
         Put (This.Labels'Length);
         for Index in This.List'Range loop
            Put_Program_Node (This.List (Index).all);
         end loop;
         for Index in This.Handlers'Range loop
            Put (This.Handlers (Index).all);
         end loop;
         Put_Labels (This);
         Put (This.Location);
      end Put;

      procedure Put (This : Identifier_List) is
      begin
         Put (This.List'Length);
         for Index in This.List'Range loop
            Put (This.List (Index), False);
         end loop;
         Put (This.Location);
         Put (This.Scope);
      end Put;

      procedure Put (This : Incomplete_Type_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Tagged_Type)
         +  (  2
            *  (  Boolean'Pos (This.Discriminants = null)
         )  )  );
         if This.Discriminants /= null then
            Put (This.Discriminants.all, False);
         end if;
         Put_Type (This);
      end Put;

      procedure Put (This : Interface_Type_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Discriminants = null)
         +  (  2
            *  This.Interfaces_Count
         )  );
         Put
         (  Interface_Type'Pos (This.Mode)
         +  (  Interface_Type_Mod
            *  This.Aspects_Count
         )  );
         if This.Discriminants /= null then
            Put (This.Discriminants.all, False);
         end if;
         Put (This.Interfaces);
         Put_Type (This);
      end Put;

      procedure Put (This : Object_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Initialized)
         +  (  2
            *  (  Boolean'Pos (This.Immutable)
               +  (  2
                  *  (  Boolean'Pos (This.Aliased_Object)
                     +  (  2
                        *  This.Aspects_Count
         )  )  )  )  )  );
         Put (This.Count);
         Put (This.Definition.all);
         if This.Initial.Present then
            Put (This.Initial.Item);
         end if;
         Put (This.Names);
         Put (This.Aspects);
         Put (This.Location);
      end Put;

      procedure Put (This : Object_Renaming) is
      begin
         Put (This.Aspects_Count);
         Put (This.Type_Of);
         Put_Renaming (This);
      end Put;

      procedure Put (Item : Object_Specification) is
      begin
         case Item.Mode is
            when Object_Mode =>
               Put (2 * Mode_Type'Pos (Item.Mode));
               Put (Item.Variable);
            when In_Mode | Inout_Mode | Out_Mode =>
               Put
               (  Boolean'Pos (Item.Not_Null)
               +  2 * Mode_Type'Pos (Item.Mode)
               );
               Put (Item.Result);
            when Access_Mode =>
               Put (2 * Mode_Type'Pos (Item.Mode));
               Put (Item.Pointer);
            when Array_Mode =>
               Put (2 * Mode_Type'Pos (Item.Mode));
               Put (Item.Array_Object.all);
            when Constant_Mode =>
               Put (2 * Mode_Type'Pos (Item.Mode));
         end case;
      end Put;

      procedure Put (This : Ordinary_Fixed_Point_Type_Declaration) is
      begin
         Put (Boolean'Pos (This.Constrained) + 2 * This.Aspects_Count);
         Put (This.Delta_Value);
         Put_Scalar_Type (This);
      end Put;

      procedure Put (This : Package_Body) is
      begin
         Put
         (  Boolean'Pos (This.Separate_Body)
         +  (  2
            *  (  Boolean'Pos (This.Code = null)
               +  (  2
                  *  This.Aspects_Count
         )  )  )  );
         Put (This.Declarations.all);
         Put (This.Full_Name);
         if This.Parent.Separate_Body then
            Put (This.Parent.Parent);
         end if;
         if This.Code /= null then
            Put (This.Code.all);
         end if;
         Put_Body (This);
      end Put;

      procedure Put (This : Package_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Private_Unit)
         +  (  2
            *  (  Boolean'Pos (This.Generic_Unit)
               +  (  2
                  *  (  Boolean'Pos (This.Private_Part = null)
                     +  (  2
                        *  This.Aspects_Count
         )  )  )  )  )  );
         if This.Generic_Unit then
            Put
            (  Declaration_Context
               (  This.Public_Part.Parent.Context.all
            )  );
         end if;
         Put (This.Public_Part.all);
         Put (This.Full_Name);
         Put (This.Name);
         if This.Private_Part /= null then
            Put (This.Private_Part.all);
         end if;
         Put (This.Aspects);
         Put (This.Location);
      end Put;

      procedure Put (This : Package_Instantiation) is
      begin
         Put (This.Aspects_Count);
         Put_Instantiation (This);
      end Put;

      procedure Put (This : Package_Renaming) is
      begin
         Put
         (  Boolean'Pos (This.Generic_Unit)
         +  (  2
            *  This.Aspects_Count
         )  );
         Put (This.Parent);
         Put (This.Full_Name);
         Put_Renaming (This);
      end Put;

      procedure Put (This : Package_Stub) is
      begin
         Put (This.Aspects_Count);
         Put_Stub (This);
      end Put;

      procedure Put (This : Parallel_Block_Statement) is
         Chunk_Mode : Natural;
      begin
         if This.Chunk = null then
            Chunk_Mode := Chunk_Specification_Type_Mod - 1;
         else
            Chunk_Mode :=
               Chunk_Specification_Type'Pos (This.Chunk.Mode);
         end if;
         Put (This.Labels_Count);
         Put
         (  Chunk_Mode
         +  (  Chunk_Specification_Type_Mod
            *  This.Paths_Count
         )  );
         Put (Boolean'Pos (This.Chunk = null) + 2 * This.Aspects_Count);
         if This.Chunk /= null then
            Put (This.Chunk.all);
         end if;
         for Index in This.Paths'Range loop
            Put (This.Paths (Index).all);
         end loop;
         Put_Labels (This);
      end Put;

      procedure Put (Item : Parameter_Type) is
      begin
         Put
         (  Boolean'Pos (Item.Present)
         +  (  2
            *  (  Boolean'Pos (Item.Aliased_Parameter)
               +  (  2
                  *  (  Boolean'Pos (Item.Constant_Parameter)
                     +  (  2
                        *  Component_Mode'Pos (Item.Mode)
         )  )  )  )  )  );
         if Item.Present then
            case Item.Mode is
               when Access_Mode =>
                  Put (Item.Access_Parameter);
               when Object_Mode =>
                  Put (Item.Object_Parameter);
            end case;
         end if;
      end Put;

      procedure Put (This : Pragma_Clause) is
         procedure Put (Item : Pragma_Argument_Association) is
         begin
            Put (Boolean'Pos (Item.Named));
            if Item.Argument.Present then
               Put (Item.Argument.Item);
            end if;
            Put (Item.Value);
         end Put;
      begin
         Put (This.Count);
         Put (This.Name);
         for Index in This.Associations'Range loop
            Put (This.Associations (Index));
         end loop;
         Put (This.Location);
      end Put;

      procedure Put (Item : Parameter_Profile; Unit : Boolean) is
      begin
         Put (Item.List'Length);
         Put_Compilation_Context (Item, Unit);
         for Index in Item.List'Range loop
            Put (Item.List (Index).all);
         end loop;
      end Put;

      procedure Put (Item : Parameter_Specification) is
      begin
         Put
         (  Boolean'Pos (Item.Aliased_Parameter)
         +  (  2
            *  (  Boolean'Pos (Item.Defaulted)
               +  (  2
                  *  Item.Parameters_Count
         )  )  )  );
         case Item.Mode is
            when In_Mode | Inout_Mode | Out_Mode =>
               Put
               (  Boolean'Pos (Item.Not_Null)
               +  (  2
                  *  (  Mode_Type'Pos (Item.Mode)
                     +  (  Mode_Type_Mod
                        *  Item.Aspects_Count
               )  )  )  );
               Put (Item.Value);
            when Access_Mode =>
               Put
               (  2
               *  (  Mode_Type'Pos (Item.Mode)
                  +  (  Mode_Type_Mod
                     *  Item.Aspects_Count
               )  )  );
               Put (Item.Pointer);
         end case;
         for Index in Item.Parameters'Range loop
            Put (Item.Parameters (Index));
         end loop;
         Put (Item.Aspects);
         if Item.Default.Present then
            Put (Item.Default.Item);
         end if;
         Put (Item.Location);
      end Put;

      procedure Put (This : Private_Type_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Abstract_Type)
         +  (  2
            *  (  Boolean'Pos (This.Tagged_Type)
               +  (  2
                  *  (  Boolean'Pos (This.Limited_Type)
                     +  (  2
                        *  (  Boolean'Pos (This.Discriminants = null)
                           +  (  2
                              *  This.Aspects_Count
         )  )  )  )  )  )  )  );
         if This.Discriminants /= null then
            Put (This.Discriminants.all, False);
         end if;
         Put_Type (This);
      end Put;

      procedure Put (This : Private_Extension_Type_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Abstract_Type)
         +  (  2
            *  (  Boolean'Pos (This.Discriminants = null)
               +  (  2
                  *  This.Aspects_Count
         )  )  )  );
         Put
         (  Derived_Interface_Type'Pos (This.Mode)
         +  (  Derived_Interface_Type_Mod
            *  This.Interfaces_Count
         )  );
         Put (This.Parent_Type);
         if This.Discriminants /= null then
            Put (This.Discriminants.all, False);
         end if;
         Put (This.Interfaces);
         Put_Type (This);
      end Put;

      procedure Put (This : Procedure_Body) is
      begin
         Put
         (  Boolean'Pos (This.Separate_Body)
         +  (  2
            *  (  Boolean'Pos (This.Profile = null)
               +  (  2
                  *  (  Overriding_Indicator_Type'Pos (This.Overrides)
                     +  (  Overriding_Indicator_Type_Mod
                        *  This.Aspects_Count
         )  )  )  )  )  );
         Put_Subroutine_Body (This);
      end Put;

      procedure Put (This : Procedure_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Private_Unit)
         +  (  2
            *  (  Boolean'Pos (This.Generic_Unit)
               +  (  2
                  *  (  Boolean'Pos (This.Abstract_Subprogram)
                     +  (  2
                        *  (  Boolean'Pos (This.Profile = null)
                           +  (  2
                              *  Overriding_Indicator_Type'Pos
                                 (  This.Overrides
         )  )  )  )  )  )  )  )  );
         Put (This.Aspects_Count);
         Put_Subprogram_Specification (This);
      end Put;

      procedure Put (This : Procedure_Instantiation) is
      begin
         Put
         (  Overriding_Indicator_Type'Pos (This.Overrides)
         +  (  Overriding_Indicator_Type_Mod
            *  This.Aspects_Count
         )  );
         Put_Instantiation (This);
      end Put;

      procedure Put (This : Procedure_Renaming) is
      begin
         Put
         (  Boolean'Pos (This.Private_Unit)
         +  (  2
            *  (  Boolean'Pos (This.Generic_Unit)
               +  (  2
                  *  (  Boolean'Pos (This.Profile = null)
                     +  (  2
                        *  Overriding_Indicator_Type'Pos
                           (  This.Overrides
         )  )  )  )  )  )  );
         Put (This.Aspects_Count);
         Put_Subprogram_Renaming (This);
      end Put;

      procedure Put (This : Procedure_Stub) is
      begin
         Put
         (  Boolean'Pos (This.Profile = null)
         +  (  2
            *  (  Overriding_Indicator_Type'Pos (This.Overrides)
               +  (  Overriding_Indicator_Type_Mod
                  *  This.Aspects_Count
         )  )  )  );
         Put_Subprogram_Stub (This);
      end Put;

      procedure Put (This : Protected_Type_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Private_Part = null)
         +  (  2
            *  (  Boolean'Pos (This.Discriminants = null)
               +  (  2
                  *  This.Aspects_Count
         )  )  )  );
         Put (This.Interfaces_Count);
         Put (This.Public_Part.all);
         if This.Private_Part /= null then
            Put (This.Private_Part.all);
         end if;
         if This.Discriminants /= null then
            Put (This.Discriminants.all, False);
         end if;
         Put (This.Interfaces);
         Put_Type (This);
      end Put;

      procedure Put (This : Protected_Body) is
      begin
         Put
         (  Boolean'Pos (This.Separate_Body)
         +  (  2
            *  This.Aspects_Count
         )  );
         Put (This.Declarations.all);
         if This.Parent.Separate_Body then
            Put (This.Parent.Parent);
         end if;
         Put_Body (This);
      end Put;

      procedure Put (This : Protected_Stub) is
      begin
         Put (This.Aspects_Count);
         Put_Stub (This);
      end Put;

      procedure Put (This : Raise_Statement) is
      begin
         Put
         (  Boolean'Pos (This.Reraise)
         +  (  2
            *  (  Boolean'Pos (This.Has_Text)
               +  (  2
                  *  This.Labels_Count
         )  )  )  );
         if not This.Reraise then
            Put (This.Name);
            if This.Text.Present then
               Put (This.Text.Item);
            end if;
         end if;
         Put_Labels (This);
      end Put;

      procedure Put (This : Record_Representation_Clause) is
         procedure Put (Item : Component_Clause) is
         begin
            Put (Item.Name);
            Put (Item.Position);
            Put (Item.Bit_Range);
         end Put;
      begin
         Put
         (  Boolean'Pos (This.Modulus.Present)
         +  (  2
            *  This.Components_Count
         )  );
         for Index in This.Components'Range loop
            Put (This.Components (Index));
         end loop;
         if This.Modulus.Present then
            Put (This.Modulus.Item);
         end if;
         Put (This.Name);
         Put (This.Location);
      end Put;

      procedure Put (This : Record_Type_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Abstract_Type)
         +  (  2
            *  (  Boolean'Pos (This.Tagged_Type)
               +  (  2
                  *  (  Boolean'Pos (This.Limited_Type)
                     +  (  2
                        *  (  Boolean'Pos (This.Discriminants = null)
                           +  (  2
                              *  Boolean'Pos (This.Components = null)
         )  )  )  )  )  )  )  );
         Put (This.Aspects_Count);
         if This.Discriminants /= null then
            Put (This.Discriminants.all, False);
         end if;
         if This.Components /= null then
            Put (This.Components.all);
         end if;
         Put_Type (This);
      end Put;

      procedure Put (This : Requeue_Statement) is
      begin
         Put
         (  Boolean'Pos (This.With_Abort)
         +  (  2
            *  This.Labels_Count
         )  );
         Put (This.Name);
         Put_Labels (This);
      end Put;

      procedure Put (This : Selective_Accept) is
         procedure Put (This : Select_Alternative) is
         begin
            Put
            (  Boolean'Pos (This.Guarded)
            +  (  2
               *  (  Boolean'Pos
                     (  (  This.Mode = Accept_Alternative
                        or else
                           This.Mode = Delay_Alternative
                        )
                     and then
                        This.Code /= null
                     )
                  +  (  2
                     *  Select_Alternative_Type'Pos (This.Mode)
            )  )  )  );
            if This.Guarded then
               Put (This.Guard.Item);
            end if;
            case This.Mode is
               when Accept_Alternative | Delay_Alternative =>
                  if This.Code /= null then
                     Put (This.Code.all);
                  end if;
                  case This.Mode is
                     when Accept_Alternative =>
                        Put (This.Accept_Statement.all);
                     when Delay_Alternative =>
                        Put (This.Delay_Statement.all);
                     when Terminate_Alternative =>
                        null;
                  end case;
               when Terminate_Alternative =>
                  null;
            end case;
         end Put;
      begin
         Put
         (  Boolean'Pos (This.Default = null)
         +  (  2
            *  This.Labels_Count
         )  );
         Put (This.Count);
         if This.Default /= null then
            Put (This.Default.all);
         end if;
         for Index in This.Alternatives'Range loop
            Put (This.Alternatives (Index));
         end loop;
         Put_Labels (This);
      end Put;

      procedure Put (This : Signed_Integer_Type_Declaration) is
      begin
         Put (This.Aspects_Count);
         Put_Scalar_Type (This);
      end Put;

      procedure Put (This : Single_Protected_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Public_Part = null)
         +  (  2
            *  (  Boolean'Pos (This.Private_Part = null)
               +  (  2
                  *  This.Aspects_Count
         )  )  )  );
         Put (This.Interfaces_Count);
         Put (This.Name);
         if This.Public_Part /= null then
            Put (This.Public_Part.all);
         end if;
         if This.Private_Part /= null then
            Put (This.Private_Part.all);
         end if;
         Put (This.Interfaces);
         Put (This.Aspects);
         Put (This.Location);
      end Put;

      procedure Put (This : Single_Task_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Public_Part = null)
         +  (  2
            *  (  Boolean'Pos (This.Private_Part = null)
               +  (  2
                  *  This.Aspects_Count
         )  )  )  );
         Put (This.Interfaces_Count);
         Put (This.Name);
         if This.Public_Part /= null then
            Put (This.Public_Part.all);
         end if;
         if This.Private_Part /= null then
            Put (This.Private_Part.all);
         end if;
         Put (This.Interfaces);
         Put (This.Aspects);
         Put (This.Location);
      end Put;

      procedure Put (This : Simple_Return_Statement) is
      begin
         Put
         (  Boolean'Pos (This.Has_Result)
         +  (  2
            *  This.Labels'Length
         )  );
         if This.Has_Result then
            Put (This.Result.Item);
         end if;
         Put_Labels (This);
      end Put;

      procedure Put (Item : Singleton_Parameter; Unit : Boolean) is
      begin
         Put_Compilation_Context (Item, Unit);
         Put (Item.Name);
         Put (Item.Type_Of);
      end Put;

      procedure Put (This : Statement_Sequence) is
      begin
         Put (This.List'Length);
         Put (This.Labels'Length);
         for Index in This.List'Range loop
            Put_Program_Node (This.List (Index).all);
         end loop;
         Put_Labels (This);
      end Put;

      procedure Put (This : Subtype_Declaration) is
      begin
         Put (This.Aspects_Count);
         Put (This.Indication);
         Put_Type (This);
      end Put;

      procedure Put (This : Task_Body) is
      begin
         Put
         (  Boolean'Pos (This.Separate_Body)
         +  (  2
            *  This.Aspects_Count
         )  );
         Put (This.Declarations.all);
         Put (This.Code.all);
         if This.Parent.Separate_Body then
            Put (This.Parent.Parent);
         end if;
         Put_Body (This);
      end Put;

      procedure Put (This : Task_Type_Declaration) is
      begin
         Put
         (  Boolean'Pos (This.Discriminants = null)
         +  (  2
            *  (  Boolean'Pos (This.Public_Part = null)
               +  (  2
                  *  (  Boolean'Pos (This.Private_Part = null)
                     +  (  2
                        *  This.Aspects_Count
         )  )  )  )  )  );
         Put (This.Interfaces_Count);
         if This.Discriminants /= null then
            Put (This.Discriminants.all, False);
         end if;
         if This.Public_Part /= null then
            Put (This.Public_Part.all);
         end if;
         if This.Private_Part /= null then
            Put (This.Private_Part.all);
         end if;
         Put (This.Interfaces);
         Put_Type (This);
      end Put;

      procedure Put (This : Task_Stub) is
      begin
         Put (This.Aspects_Count);
         Put_Stub (This);
      end Put;

      procedure Put (This : Timed_Entry_Call) is
      begin
         Put
         (  Boolean'Pos (This.Accepted_Code = null)
         +  (  2
            *  (  Boolean'Pos (This.Expired_Code = null)
               +  (  2
                  *  This.Labels'Length
         )  )  )  );
         Put_Program_Node (This.Entry_Call.all);
         Put_Program_Node (This.Timer.all);
         if This.Accepted_Code /= null then
            Put (This.Accepted_Code.all);
         end if;
         if This.Expired_Code /= null then
            Put (This.Expired_Code.all);
         end if;
         Put_Labels (This);
      end Put;

      procedure Put (This : While_Loop_Statement) is
      begin
         Put (Boolean'Pos (This.Named) + 2 * This.Labels_Count);
         Put (This.Condition);
         Put_Loop (This);
      end Put;

      procedure Put (This : Use_Package_Clause) is
      begin
         Put (This.Length);
         Put_Context_Clause (This);
      end Put;

      procedure Put (This : Use_Type_Clause) is
      begin
         Put (Boolean'Pos (This.All_Type) + 2 * This.Length);
         Put_Context_Clause (This);
      end Put;

      procedure Put (This : With_Clause) is
      begin
         Put
         (  Boolean'Pos (This.Limited_With)
         +  (  2
            *  (  Boolean'Pos (This.Private_With)
               +  (  2
                  *  This.Length
         )  )  )  );
         Put_Context_Clause (This);
      end Put;

      procedure Put (This : Variant_Part_Item) is
      begin
         Put (This.Choices_Count);
         Put (This.Components.all);
         Put (This.Choices);
         Put (This.Location);
      end Put;

      procedure Put (This : Variant_Part) is
      begin
         Put (This.Count);
         Put (This.Discriminant);
         for Index in This.Alternatives'Range loop
            Put (This.Alternatives (Index).all);
         end loop;
         Put (This.Location);
      end Put;

      procedure Put_Body (Item : Abstract_Body'Class) is
      begin
         Put (Item.Name);
         Put (Item.Aspects);
         Put (Item.Location);
      end Put_Body;

      procedure Put_Compilation_Context
                (  Item : Compilation_Context'Class;
                   Unit : Boolean
                )  is
         Library : constant Boolean :=
                   Unit and then Is_Library_Context (Item.Parent);
      begin
         if Trace /= null then
            Put (Trace.all, Prefix & Image (Offset));
            Put (Trace.all, Ada.Tags.Expanded_Name (Item'Tag));
            Put (Trace.all, " at " & Image (Item.Location));
            Put (Trace.all, ", parent " & Image (Item.Parent));
            if Library then
               Put (Trace.all, ", library unit");
            end if;
            New_Line (Trace.all);
         end if;
         Put (Boolean'Pos (Library));
         if Library then
            Put (Declaration_Context (Item.Parent.Context.all));
         end if;
         Put (Item.Location);
         Put (Item.Scope);
      end Put_Compilation_Context;

      procedure Put_Formal_Parameter (Item : Formal_Parameter'Class) is
      begin
         Put (Item.Name);
      end Put_Formal_Parameter;

      procedure Put_Formal_Type_Parameter
                (  Item : Formal_Type_Parameter'Class
                )  is
      begin
         if Item.Default.Defaulted then
            Put (Item.Default.Default);
         end if;
         Put (Item.Aspects);
         Put_Formal_Parameter (Item);
      end Put_Formal_Type_Parameter;

      procedure Put_Instantiation
                (  Item : Abstract_Instantiation'Class
                )  is
      begin
         Put (Item.Full_Name);
         Put (Item.Name);
         Put (Item.Target);
         Put (Item.Aspects);
         Put (Item.Location);
      end Put_Instantiation;

      procedure Put_Loop (Item : Abstract_Loop_Statement'Class) is
      begin
         if Item.Name.Present then
            Put (Item.Name.Item);
         end if;
         Put (Item.Sequence.all);
         Put_Labels (Item);
      end Put_Loop;

      procedure Put_Labels (Item : Abstract_Statement_Node'Class) is
      begin
         Put (Item.Location);
         for Index in Item.Labels'Range loop
            Put (Item.Labels (Index));
         end loop;
      end Put_Labels;

      procedure Put_Formal_Subprogram_Parameter
                (  Item : Formal_Subprogram_Parameter'Class
                )  is
      begin
         if Item.Profile /= null then
            Put (Item.Profile.all, False);
         end if;
         case Item.Default is
            when Name_Default =>
               Put (Item.Default_Name);
            when No_Default | Box_Default | Null_Default =>
               null;
         end case;
         Put (Item.Aspects);
         Put_Formal_Parameter (Item);
      end Put_Formal_Subprogram_Parameter;

      procedure Put_Renaming (Item : Abstract_Renaming'Class) is
      begin
         Put (Item.Name);
         Put (Item.Target);
         Put (Item.Aspects);
         Put (Item.Location);
      end Put_Renaming;

      procedure Put_Scalar_Type (Item : Scalar_Type_Definition'Class) is
      begin
         if Item.Constraint.Present then
            Put (Item.Constraint.Item);
         end if;
         Put_Type (Item);
      end Put_Scalar_Type;

      procedure Put_Stub (Item : Abstract_Stub'Class) is
      begin
         Put (Item.Name);
         Put (Item.Aspects);
         Put (Item.Location);
      end Put_Stub;

      procedure Put_Subprogram_Renaming
                (  Item : Subprogram_Renaming'Class
                )  is
      begin
         Put (Item.Parent);
         Put (Item.Full_Name);
         if Item.Profile /= null then
            Put (Item.Profile.all, False);
         end if;
         Put_Renaming (Item);
      end Put_Subprogram_Renaming;

      procedure Put_Subprogram_Specification
                (  Item : Subprogram_Specification'Class
                )  is
      begin
         if Item.Generic_Unit then
            Put (Declaration_Context (Item.Parent.Context.all));
         else
            Put (Item.Parent);
         end if;
         if Item.Profile /= null then
            Put (Item.Profile.all, False);
         end if;
         Put (Item.Full_Name);
         Put (Item.Name);
         Put (Item.Aspects);
         Put (Item.Location);
      end Put_Subprogram_Specification;

      procedure Put_Subprogram_Stub (Item : Subprogram_Stub'Class) is
      begin
         if Item.Profile /= null then
            Put (Item.Profile.all, False);
         end if;
         Put_Stub (Item);
      end Put_Subprogram_Stub;

      procedure Put_Subroutine_Body (Item : Subroutine_Body'Class) is
      begin
         if Item.Profile /= null then
            Put (Item.Profile.all, True);
         end if;
         Put (Item.Declarations.all);
         Put (Item.Code.all);
         Put (Item.Full_Name);
         if Item.Parent.Separate_Body then
            Put (Item.Parent.Parent);
         end if;
         Put_Body (Item);
      end Put_Subroutine_Body;

      procedure Put_Type (Item : Abstract_Type_Declaration'Class) is
      begin
         Put (Item.Name);
         Put (Item.Aspects);
         Put (Item.Location);
      end Put_Type;

      procedure Put_Context_Clause (Item : Context_Clause'Class) is
      begin
         Put (Item.List);
         Put (Item.Location);
      end Put_Context_Clause;

   begin
      Put (Program_Node_Class'Pos (Tag) + Term_Class_Mod);
      if Trace /= null then
         Put (Trace.all, Prefix & Image (Offset));
         Put (Trace.all, Program_Node_Class'Image (Tag));
         Put_Line
         (  Trace.all,
            Integer'Image
            (  Program_Node_Class'Pos (Tag) + Term_Class_Mod
         )  );
      end if;
      case Tag is
         when Abort_Statement_Node =>
            Put (Abort_Statement (This));
         when Accept_Statement_Node =>
            Put (Accept_Statement (This));
         when Access_Type_Declaration_Node =>
            Put (Access_Type_Declaration (This));
         when Array_Type_Declaration_Node =>
            Put (Array_Type_Declaration (This));
         when Assignment_Statement_Node =>
            Put (Assignment_Statement (This));
         when Asynchronous_Transfer_Control_Node =>
            Put (Asynchronous_Transfer_Control (This));
         when At_Clause_Node =>
            Put (At_Clause (This));
         when Attribute_Definition_Clause_Node =>
            Put (Attribute_Definition_Clause (This));
         when Block_Statement_Node =>
            Put (Block_Statement (This));
         when Call_Statement_Node =>
            Put (Call_Statement (This));
         when Case_Statement_Node =>
            Put (Case_Statement (This));
         when Chunk_Specification_Node =>
            declare
               Item : Chunk_Specification renames
                      Chunk_Specification (This);
            begin
               Put (Chunk_Specification_Type'Pos (Item.Mode));
               Put (Item);
            end;
         when Conditional_Entry_Call_Node =>
            Put (Conditional_Entry_Call (This));
         when Decimal_Fixed_Point_Type_Declaration_Node =>
            Put (Decimal_Fixed_Point_Type_Declaration (This));
         when Declaration_Context_Node =>
            Put (Declaration_Context (This));
         when Delay_Statement_Node =>
            Put (Delay_Statement (This));
         when Derived_Type_Declaration_Node =>
            Put (Derived_Type_Declaration (This));
         when Enumeration_Representation_Clause_Node =>
            Put (Enumeration_Representation_Clause (This));
         when Enumeration_Type_Declaration_Node =>
            Put (Enumeration_Type_Declaration (This));
         when Entry_Body_Node =>
            Put (Entry_Body (This));
         when Entry_Declaration_Node =>
            Put (Entry_Declaration (This));
         when Exception_Declaration_Node =>
            Put (Exception_Declaration (This));
         when Exception_Handler_Node =>
            Put (Exception_Handler (This));
         when Exception_Renaming_Node =>
            Put (Exception_Renaming (This));
         when Exit_Statement_Node =>
            Put (Exit_Statement (This));
         when Extended_Return_Statement_Node =>
            Put (Extended_Return_Statement (This));
         when Floating_Point_Type_Declaration_Node =>
            Put (Floating_Point_Type_Declaration (This));
         when For_Loop_Statement_Node =>
            Put (For_Loop_Statement (This));
         when Formal_Access_Type_Parameter_Node =>
            Put (Formal_Access_Type_Parameter (This));
         when Formal_Array_Type_Parameter_Node =>
            Put (Formal_Array_Type_Parameter (This));
         when Formal_Derived_Type_Parameter_Node =>
            Put (Formal_Derived_Type_Parameter (This));
         when Formal_Function_Parameter_Node =>
            Put (Formal_Function_Parameter (This));
         when Formal_Incomplete_Type_Parameter_Node =>
            Put (Formal_Incomplete_Type_Parameter (This));
         when Formal_Interface_Type_Parameter_Node =>
            Put (Formal_Interface_Type_Parameter (This));
         when Formal_Package_Parameter_Node =>
            Put (Formal_Package_Parameter (This));
         when Formal_Private_Type_Parameter_Node =>
            Put (Formal_Private_Type_Parameter (This));
         when Formal_Procedure_Parameter_Node =>
            Put (Formal_Procedure_Parameter (This));
         when Formal_Scalar_Type_Parameter_Node =>
            Put (Formal_Scalar_Type_Parameter (This));
         when Function_Body_Node =>
            Put (Function_Body (This));
         when Function_Declaration_Node =>
            Put (Function_Declaration (This));
         when Function_Expression_Node =>
            Put (Function_Expression (This));
         when Function_Instantiation_Node =>
            Put (Function_Instantiation (This));
         when Function_Renaming_Node =>
            Put (Function_Renaming (This));
         when Function_Stub_Node =>
            Put (Function_Stub (This));
         when Goto_Statement_Node =>
            Put (Goto_Statement (This));
         when If_Statement_Node =>
            Put (If_Statement (This));
         when Incomplete_Type_Declaration_Node =>
            Put (Incomplete_Type_Declaration (This));
         when Identifier_List_Node =>
            Put (Identifier_List (This));
         when Interface_Type_Declaration_Node =>
            Put (Interface_Type_Declaration (This));
         when Handled_Statement_Sequence_Node =>
            Put (Handled_Statement_Sequence (This));
         when Loop_Statement_Node =>
            Put (Loop_Statement (This));
         when Modular_Type_Declaration_Node =>
            Put (Modular_Type_Declaration (This));
         when Null_Procedure_Node =>
            Put (Null_Procedure (This));
         when Null_Statement_Node =>
            Put (Null_Statement (This));
         when Object_Declaration_Node =>
            Put (Object_Declaration (This));
         when Object_Renaming_Node =>
            Put (Object_Renaming (This));
         when Ordinary_Fixed_Point_Type_Declaration_Node =>
            Put (Ordinary_Fixed_Point_Type_Declaration (This));
         when Package_Body_Node =>
            Put (Package_Body (This));
         when Package_Renaming_Node =>
            Put (Package_Renaming (This));
         when Package_Declaration_Node =>
            Put (Package_Declaration (This));
         when Package_Instantiation_Node =>
            Put (Package_Instantiation (This));
         when Package_Stub_Node =>
            Put (Package_Stub (This));
         when Parallel_Block_Node =>
            Put (Parallel_Block_Statement (This));
         when Parameter_Profile_Node =>
            Put (Parameter_Profile (This), False);
         when Parameter_Specification_Node =>
            Put (Parameter_Specification (This));
         when Pragma_Clause_Node =>
            Put (Pragma_Clause (This));
         when Private_Type_Declaration_Node =>
            Put (Private_Type_Declaration (This));
         when Private_Extension_Type_Declaration_Node =>
            Put (Private_Extension_Type_Declaration (This));
         when Procedure_Body_Node =>
            Put (Procedure_Body (This));
         when Procedure_Declaration_Node =>
            Put (Procedure_Declaration (This));
         when Procedure_Instantiation_Node =>
            Put (Procedure_Instantiation (This));
         when Procedure_Renaming_Node =>
            Put (Procedure_Renaming (This));
         when Procedure_Stub_Node =>
            Put (Procedure_Stub (This));
         when Protected_Body_Node =>
            Put (Protected_Body (This));
         when Protected_Stub_Node =>
            Put (Protected_Stub (This));
         when Protected_Type_Declaration_Node =>
            Put (Protected_Type_Declaration (This));
         when Raise_Statement_Node =>
            Put (Raise_Statement (This));
         when Record_Representation_Clause_Node =>
            Put (Record_Representation_Clause (This));
         when Record_Type_Declaration_Node =>
            Put (Record_Type_Declaration (This));
         when Requeue_Statement_Node =>
            Put (Requeue_Statement (This));
         when Selective_Accept_Node =>
            Put (Selective_Accept (This));
         when Signed_Integer_Type_Declaration_Node =>
            Put (Signed_Integer_Type_Declaration (This));
         when Simple_Return_Statement_Node =>
            Put (Simple_Return_Statement (This));
         when Single_Protected_Declaration_Node =>
            Put (Single_Protected_Declaration (This));
         when Single_Task_Declaration_Node =>
            Put (Single_Task_Declaration (This));
         when Singleton_Parameter_Node =>
            Put (Singleton_Parameter (This), False);
         when Statement_Sequence_Node =>
            Put (Statement_Sequence (This));
         when Subtype_Declaration_Node =>
            Put (Subtype_Declaration (This));
         when Task_Body_Node =>
            Put (Task_Body (This));
         when Task_Stub_Node =>
            Put (Task_Stub (This));
         when Task_Type_Declaration_Node =>
            Put (Task_Type_Declaration (This));
         when Timed_Entry_Call_Node =>
            Put (Timed_Entry_Call (This));
         when Use_Package_Clause_Node =>
            Put (Use_Package_Clause (This));
         when Use_Type_Clause_Node =>
            Put (Use_Type_Clause (This));
         when Variant_Part_Node =>
            Put (Variant_Part (This));
         when Variant_Part_Item_Node =>
            Put (Variant_Part_Item (This));
         when While_Loop_Statement_Node =>
            Put (While_Loop_Statement (This));
         when With_Clause_Node =>
            Put (With_Clause (This));
      end case;
      if Trace /= null then
         Put (Trace.all, Prefix & Image (Offset) & "--- ");
         Put_Line (Trace.all, Program_Node_Class'Image (Tag));
      end if;
   end Put_Program_Node;

   procedure Put (This : Node'Class) is
      procedure Put_Term_Class (Value : Term_Class) is
      begin
         Put (Term_Class'Pos (Value));
         if Trace /= null then
            Put (Trace.all, Prefix & Image (Offset));
            Put (Trace.all, Term_Class'Image (Value));
            Put_Line
            (  Trace.all,
               Integer'Image (Term_Class'Pos (Value)) & ' '
            );
         end if;
      end Put_Term_Class;
   begin
      if This in Program_Node'Class then
         Put_Program_Node (Program_Node'Class (This));
      else
         case Get_Class (This) is
            when Case_Node =>
               Put_Term_Class (Case_Node_Term);
               declare
                  Item : Case_Expression renames
                         Case_Expression (This);
               begin
                  Put
                  (  Boolean'Pos (Item.Has_Others) + Item.Count * 2
                  );
                  Put (Item.Selector);
                  for Index in Item.Alternatives'Range loop
                     declare
                        This : Case_Alternative renames
                               Item.Alternatives (Index);
                     begin
                        Put (This.Choice'Length);
                        Put (This.Choice.all);
                        Put (This.Value);
                     end;
                  end loop;
                  if Item.Has_Others then
                     Put (Item.Others_Alternative);
                  end if;
               end;
            when Declare_Node =>
               Put_Term_Class (Declare_Node_Term);
               declare
                  Item : Declare_Expression renames
                         Declare_Expression (This);
               begin
                  Put (Item.Count);
                  Put (Item.Expression);
                  for Index in Item.Items'Range loop
                     Put (Item.Items (Index).Value.all);
                     Put (Item.Items (Index).Location);
                  end loop;
               end;
            when Declare_Item_Node =>
               if This in Declare_Renaming_Item then
                  Put_Term_Class (Declare_Renaming_Item_Term);
                  declare
                     Item : Declare_Renaming_Item renames
                            Declare_Renaming_Item (This);
                  begin
                     Put
                     (  Boolean'Pos (Item.Has_Mark)
                     +  Item.Aspects_Count * 2
                     );
                     Put (Item.Name);
                     Put (Item.Object);
                     if Item.Has_Mark then
                        Put (Item.Mark);
                     end if;
                     Put (Item.Aspects);
                  end;
               elsif This in Declare_Object_Item then
                  Put_Term_Class (Declare_Object_Item_Term);
                  declare
                     Item : Declare_Object_Item renames
                            Declare_Object_Item (This);
                  begin
                     Put
                     (  Boolean'Pos (Item.Array_Object)
                     +  Item.Names_Count * 2
                     );
                     Put (Item.Aspects_Count);
                     Put (Item.Value);
                     Put (Item.Names);
                     if Item.Array_Object then
                        Put (Item.Definition.all);
                     else
                        Put (Item.Object);
                     end if;
                     Put (Item.Aspects);
                  end;
               else
                  raise Data_Error;
               end if;
            when Expression_Node =>
               Put_Term_Class (Expression_Node_Term);
               declare
                  Item : Expression renames Expression (This);
               begin
                  Put (Item.Count);
                  Put (Operations'Pos (Item.Operation));
                  Put (Item.Operands);
               end;
            when For_Node =>
               Put_Term_Class (For_Node_Term);
               declare
                  Item : For_Expression renames
                         For_Expression (This);
               begin
                  Put
                  (  For_Qualifier'Pos (Item.Qualifier)
                  +  Natural (Item.Options) * For_Qualifier_Mod
                  );
                  Put (Item.Aspects_Count);
                  Put (Item.Identifier);
                  if 0 /= (Item.Options and For_Range) then
                     Put (Item.Range_Type);
                  end if;
                  Put (Item.Iterator);
                  Put (Item.Expression);
                  if 0 /= (Item.Options and For_Condition) then
                     Put (Item.Condition);
                  end if;
                  if 0 /= (Item.Options and For_Key) then
                     Put (Item.Key);
                  end if;
                  if 0 /= (Item.Options and For_Chunk) then
                     Put (Item.Chunk);
                  end if;
                  Put (Item.Aspects);
               end;
            when If_Node =>
               Put_Term_Class (If_Node_Term);
               declare
                  Item : If_Expression renames
                         If_Expression (This);
               begin
                  Put (Boolean'Pos (Item.Has_Else) + Item.Count * 2);
                  Put (Item.Alternatives);
                  if Item.Has_Else then
                     Put (Item.Else_Alternative);
                  end if;
               end;
            when Raise_Node =>
               Put_Term_Class (Raise_Node_Term);
               declare
                  Item : Raise_Expression renames
                         Raise_Expression (This);
               begin
                  Put (Boolean'Pos (Item.Has_Message));
                  Put (Item.Name);
                  if Item.Has_Message then
                     Put (Item.Message);
                  end if;
               end;
            when Term_Node =>
               if This in Integer_Literal then
                  Put_Term_Class (Integer_Literal_Term);
                  Put_Numeric_Literal (Integer_Literal (This));
               elsif This in Real_Literal then
                  Put_Term_Class (Real_Literal_Term);
                  Put_Numeric_Literal (Real_Literal (This));
               elsif This in String_Literal then
                  Put_Term_Class (String_Literal_Term);
                  Put_Named_Term (String_Literal (This));
               elsif This in Character_Literal then
                  Put_Term_Class (Character_Literal_Term);
                  Put_Named_Term (Character_Literal (This));
               elsif This in Identifier then
                  Put_Term_Class (Identifier_Term);
                  Put_Named_Term (Identifier (This));
               elsif This in Null_Aggregate then
                  Put_Term_Class (Null_Aggregate_Term);
               elsif This in Universal_Boolean then
                  Put_Term_Class (Universal_Boolean_Term);
                  Put (Boolean'Pos (Universal_Boolean (This).Value));
               elsif This in Universal_Integer then
                  Put_Term_Class (Universal_Integer_Term);
                  Put (Get_Value (Universal_Integer (This)));
               elsif This in Universal_Real then
                  Put_Term_Class (Universal_Real_Term);
                  Put (Get_Value (Universal_Real (This)));
               elsif This in Box_Choice then
                  Put_Term_Class (Box_Choice_Term);
               elsif This in Target_Name then
                  Put_Term_Class (Target_Name_Term);
               else
                  Raise_Exception
                  (  Program_Error'Identity,
                     "Invalid expression term " &
                     Ada.Tags.Expanded_Name (This'Tag)
                  );
               end if;
         end case;
         if Trace /= null then
            Put (Trace.all, Prefix & Image (Offset));
            Put (Trace.all, "= ");
            Put_Line (Trace.all, Image (This));
         end if;
      end if;
   end Put;
begin
   Put (Tree.Value.all);
   Put (Tree.Location);
end Store;
