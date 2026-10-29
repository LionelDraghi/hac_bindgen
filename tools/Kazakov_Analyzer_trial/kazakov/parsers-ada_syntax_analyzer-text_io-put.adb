--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer                 Luebeck            --
--        Text_IO .Put                             Summer, 2026       --
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

with Ada.Text_IO;  use Ada.Text_IO;

with Parsers.Ada_Syntax_Analyzer.Bodies;
use  Parsers.Ada_Syntax_Analyzer.Bodies;

with Parsers.Ada_Syntax_Analyzer.Declarations.Formal_Parameters;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Formal_Parameters;

with Parsers.Ada_Syntax_Analyzer.Declarations.Renamings;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Renamings;

with Parsers.Ada_Syntax_Analyzer.Declarations.Stubs;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Stubs;

with Parsers.Ada_Syntax_Analyzer.Declarations.Types;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Types;

with Parsers.Ada_Syntax_Analyzer.Statements;

with Parsers.Ada_Syntax_Analyzer.Expression_IO;
use  Parsers.Ada_Syntax_Analyzer.Statements;

separate (Parsers.Ada_Syntax_Analyzer.Text_IO)
   procedure Put
             (  Tree   : Tokens.Argument_Token;
                Output : File_Type := Standard_Output;
                Prefix : String    := "";
                Nested : Nesting   := Top
             )  is
   procedure Put
             (  This   : Object_Specification;
                Prefix : String;
                Nested : Nesting
             );
   procedure Put
             (  This   : Parameter_Profile;
                Prefix : String;
                Head   : String
             );
   procedure Put
             (  This   : Parameter_Profile_Ptr;
                Prefix : String;
                Head   : String
             );
   procedure Put
             (  This   : Parameter_Specification;
                Prefix : String;
                Nested : Nesting
             );
   procedure Put
             (  This   : Singleton_Parameter;
                Prefix : String;
                Nested : Nesting
             );
   procedure Put (List : Singleton_Parameter_Array; Prefix : String);
   procedure Put
             (  This   : Subtype_Indication;
                Prefix : String;
                Nested : Nesting
             );
   procedure Put
             (  This   : Subtype_Mark;
                Prefix : String;
                Nested : Nesting
             );
   procedure Put (This : Statement_Sequence; Prefix : String);
   procedure Put
             (  List   : Subtype_Indication_Array;
                Prefix : String
             );
   procedure Put_Interfaces
             (  List   : Subtype_Mark_Array;
                Prefix : String;
                First  : String := "and"
             );
   procedure Put_Labels
             (  Labels : Defining_Identifier_Array;
                Prefix : String
             );
   procedure Put_Name (Name : Tokens.Argument_Token);
   procedure Put_Names (List : Argument_List; Prefix : String);
------------------------------------------------------------------------
   procedure Put (Identifier : Defining_Identifier) is
   begin
      Put_Name (Identifier.Term);
   end Put;

   procedure Put (List : Defining_Identifier_Array) is
   begin
      for Index in List'Range loop
         if Index > List'First then
            Put (Output, ", ");
         end if;
         Put (List (Index));
      end loop;
   end Put;

   procedure Put (List : Argument_List; Prefix : String) is
   begin
      if List'Length > 0 then
         for Index in List'First..List'Last - 1 loop
            Expression_IO.Put
            (  List (Index),
               Output,
               Prefix & "|  ",
               Child
            );
         end loop;
         Expression_IO.Put
         (  List (List'Last),
            Output,
            Prefix & "   ",
            Child
         );
      end if;
   end Put;

   procedure Put (List : Aspect_Items_Array; Prefix : String) is
      procedure Put
                (  This   : Global_Aspect_Element;
                   Prefix : String;
                   Nested : Nesting
                );

      procedure Put
                (  List   : Global_Aspect_Element_Ptr_Array;
                   Prefix : String;
                   Nested : Nesting
                )  is
         Mode : Nesting := Nested;
      begin
         for Index in List'First..List'Last - 1 loop
            Put (List (Index).all, Prefix & "|  ", Mode);
            Mode := Child;
         end loop;
         Put (List (List'Last).all, Prefix & "   ", Mode);
      end Put;

      procedure Put
                (  This   : Global_Aspect_Element;
                   Prefix : String;
                   Nested : Nesting
                )  is
      begin
         case Nested is
            when Top =>
               Put (Output, Prefix);
            when Child =>
               if Prefix'Length >= 3 then
                  Put
                  (  Output,
                     Prefix (Prefix'First..Prefix'Last - 3) & "|__"
                  );
               end if;
            when Inline =>
               null;
         end case;
         if This.Extended then
            Put (Output, "overriding ");
         end if;
         Put (Output, Image (This.Mode));
         case This.Kind_Of is
            when All_Designator_Mode =>
               Put_Line (Output, " all");
            when Synchronized_Designator_Mode =>
               Put_Line (Output, " synchronized");
            when Global_Name_Designator_Mode =>
               New_Line (Output);
               Put (This.List, Prefix);
         end case;
      end Put;

      procedure Put
                (  This   : Aspect_Specification_Item;
                   Prefix : String;
                   Nested : Nesting
                )  is
      begin
         Expression_IO.Put (This.Mark, Output, Prefix, Nested);
         case This.Mode is
            when Value_Designator =>
               Expression_IO.Put
               (  This.Value,
                  Output,
                  Prefix & "   ",
                  Child
               );
            when No_Designator =>
               null;
            when Null_Designator =>
               Put_Line (Output, "|__null");
            when Unspecified_Designator =>
               Put_Line (Output, "|__unspecified");
            when Global_Designator =>
               Put (This.Designator.all, Prefix & "|  ", Child);
            when Global_Aspect_Elements_List_Designator =>
               Put (This.List, Prefix & "|  ", Child);
         end case;
      end Put;
   begin
      if List'Length > 0 then
         if List'Length = 1 then
            Put_Line (Output, Prefix & "aspect");
         else
            Put_Line (Output, Prefix & "aspects");
         end if;
         for Index in List'First..List'Last - 1 loop
            Put (List (Index).all, Prefix & "|  ", Child);
         end loop;
         Put (List (List'Last).all, Prefix & "   ", Child);
      end if;
   end Put;

   procedure Put
             (  This   : Anonymous_Access_Definition;
                Prefix : String;
                Nested : Nesting
             )  is
      Shift : Natural := 7;
   begin
      case Nested is
         when Top =>
            Put (Output, Prefix);
         when Child =>
            if Prefix'Length >= 3 then
               Put
               (  Output,
                  Prefix (Prefix'First..Prefix'Last - 3) & "|__"
               );
            end if;
         when Inline =>
            null;
      end case;
      if This.Not_Null then
         Put (Output, "not null ");
         Shift := Shift + 9;
      end if;
      case This.Mode is
         when Access_To_All =>
            Put (Output, "all ");
            Shift := Shift + 4;
            Put (Output, "access ");
            Put (This.Object, Prefix & (1..Shift => ' '), Inline);
         when Access_To_Constant =>
            Put (Output, "constant ");
            Shift := Shift + 8;
            Put (Output, "access ");
            Put (This.Object, Prefix & (1..Shift => ' '), Inline);
         when Access_To_Variable =>
            Put (Output, "access ");
            Put (This.Object, Prefix & (1..Shift => ' '), Inline);
         when Access_To_Procedure =>
            Put_Line (Output, "access procedure");
            Put (This.Profile, Prefix & "   ", "parameter");
         when Access_To_Protected_Procedure =>
            Put_Line (Output, "access protected procedure");
            Put (This.Profile, Prefix & "   ", "parameter");
         when Access_To_Function =>
            Put_Line (Output, "access function");
            Put (This.Profile,    Prefix & "   ", "parameter");
            Put (Output,          Prefix & "   return ");
            Put (This.Result.all, Prefix & "          ", Inline);
         when Access_To_Protected_Function =>
            Put_Line (Output, "access protected function");
            Put (This.Profile,    Prefix & "   ", "parameter");
            Put (Output,          Prefix & "   return ");
            Put (This.Result.all, Prefix & "          ", Inline);
      end case;
   end Put;

   procedure Put
             (  This   : Array_Type_Specification;
                Prefix : String;
                Nested : Nesting
             )  is
   begin
      case Nested is
         when Top =>
            Put (Output, Prefix);
         when Child =>
            if Prefix'Length >= 3 then
               Put
               (  Output,
                  Prefix (Prefix'First..Prefix'Last - 3) & "|__"
               );
            end if;
         when Inline =>
            null;
      end case;
      Put_Line (Output, "array");
      Put (This.Indices, Prefix);
      Put (Output, Prefix & "of ");
      case This.Mode is
         when Access_Mode =>
            Put (This.Access_Component, Prefix & "   ", Inline);
         when Object_Mode =>
            Put (This.Object_Component, Prefix & "   ", Inline);
      end case;
   end Put;

   procedure Put (This : Chunk_Specification; Prefix : String) is
   begin
      case This.Mode is
         when Chunk_Any =>
            null;
         when Chunk_Parameter =>
            Put (This.Name, Prefix, Top);
         when Chunk_Expression =>
            Expression_IO.Put
            (  This.Value,
               Output,
               Prefix,
               Top
            );
      end case;
   end Put;

   procedure Put
             (  This   : Compilation_Context'Class;
                Prefix : String;
                Head   : Boolean := True
             )  is
   begin
      if This in Declaration_Context then
         declare
            Context : Declaration_Context renames
                      Declaration_Context (This);
         begin
            if Context.Declarations = null then
               if Head then
                  Put_Line (Output, Prefix & "   declaration");
               end if;
            else
               declare
                  Shift : Natural := 3;
                  List  : Declaration_Ptr_Array renames
                          Declaration_Context (This).Declarations.all;
               begin
                  if List'Length = 0 then
                     return;
                  end if;
                  if Head then
                     Put (Output, Prefix & "   declaration");
                     if List'Length > 1 then
                        Put_Line (Output, "s");
                     else
                        New_Line (Output);
                     end if;
                  else
                     Shift := 0;
                  end if;
                  for Index in List'First..List'Last - 1 loop
                     Put
                     (  Tree   => (  List (Index).all'Unchecked_Access,
                                     List (Index).Location
                                  ),
                        Output => Output,
                        Prefix => Prefix & (1..Shift => ' ') & "|  ",
                        Nested => Child
                     );
                  end loop;
                  Put
                  (  Tree   => (  List (List'Last).all'Unchecked_Access,
                                  List (List'Last).Location
                               ),
                     Output => Output,
                     Prefix => Prefix & (1..Shift => ' ') & "   ",
                     Nested => Child
                  );
               end;
            end if;
         end;
      elsif This in Singleton_Parameter then
         Put (Singleton_Parameter (This), Prefix, Top);
      elsif This in Identifier_List then
         Put (Identifier_List (This).List, Prefix);
      end if;
   end Put;

   procedure Put (This : Context_Location; Prefix : String) is
   begin
      if This.Context /= null then
         Put (This.Context.all, Prefix);
      end if;
   end Put;

   procedure Put
             (  This   : Exception_Handler;
                Prefix : String;
                Nested : Nesting
             )  is
   begin
      case Nested is
         when Top =>
            Put (Output, Prefix);
         when Child =>
            if Prefix'Length >= 3 then
               Put
               (  Output,
                  Prefix (Prefix'First..Prefix'Last - 3) & "|__"
               );
            end if;
         when Inline =>
            null;
      end case;
      Put (Output, "when ");
      if This.Has_Parameter then
         Put (This.Parameter, Prefix, Inline);
      else
         New_Line (Output);
      end if;
      if This.Choices_Count = 0 then
         Put_Line (Output, Prefix & "|__others");
      else
         Put (This.Choices, Prefix);
      end if;
      Put_Line (Output, Prefix & "=>");
      Put (This.Sequence.all, Prefix);
   end Put;

   procedure Put (This : Formal_Type_Default; Prefix : String) is
   begin
      if This.Defaulted then
         Put (Output, Prefix & ":= ");
         Put (This.Default, Prefix & "   ", Inline);
      end if;
   end Put;

   procedure Put (This : Handled_Statement_Sequence; Prefix : String) is
   begin
      Put (Statement_Sequence (This), Prefix);
      Put_Labels (This.Labels, Prefix);
      if This.Handlers_Count > 0 then
         Put_Line (Output, Prefix & "exception");
         for Index in This.Handlers'First..This.Handlers'Last - 1 loop
            Put
            (  This.Handlers (Index).all,
               Prefix & "|  ",
               Child
            );
         end loop;
         Put
         (  This.Handlers (This.Handlers'Last).all,
            Prefix & "   ",
            Child
         );
      end if;
   end Put;

   procedure Put
             (  This   : Object_Specification;
                Prefix : String;
                Nested : Nesting
             )  is
      Shift : Natural := 0;
      procedure Not_Null is
      begin
         if This.Not_Null then
            Put (Output, "not null ");
            Shift := Shift + 9;
         end if;
      end Not_Null;

   begin
      case Nested is
         when Top =>
            Put (Output, Prefix);
         when Child =>
            if Prefix'Length >= 3 then
               Put
               (  Output,
                  Prefix (Prefix'First..Prefix'Last - 3) & "|__"
               );
            end if;
         when Inline =>
            null;
      end case;
      case This.Mode is
         when Object_Mode =>
            Put (This.Variable, Prefix, Inline);
         when In_Mode =>
            Not_Null;
            Put (This.Result, Prefix & (1..Shift =>     ' '), Inline);
         when Inout_Mode =>
            Put (Output, "in out ");
            Not_Null;
            Put (This.Result, Prefix & (1..Shift + 7 => ' '), Inline);
         when Out_Mode =>
            Put (Output, "out ");
            Not_Null;
            Put (This.Result, Prefix & (1..Shift + 4 => ' '), Inline);
         when Access_Mode =>
            Put (This.Pointer, Prefix, Inline);
         when Array_Mode =>
            Put (This.Array_Object.all, Prefix, Inline);
         when Constant_Mode =>
            Put_Line (Output, "<named number>");
      end case;
   end Put;

   procedure Put
             (  This   : Parameter_Profile;
                Prefix : String;
                Head   : String
             )  is
      List : Parameter_Specification_Ptr_Array renames This.List;
   begin
      if List'Length > 0 then
         if List'Length > 1 then
            Put_Line (Output, Prefix & Head & "s");
         else
            Put_Line (Output, Prefix & Head);
         end if;
         for Index in List'First..List'Last - 1 loop
            Put (List (Index).all, Prefix & "|  ", Child);
         end loop;
         Put (List (List'Last).all, Prefix & "   ", Child);
      end if;
   end Put;

   procedure Put
             (  This   : Parameter_Profile_Ptr;
                Prefix : String;
                Head   : String
             )  is
   begin
      if This /= null then
         Put (This.all, Prefix, Head);
      end if;
   end Put;

   procedure Put
             (  This   : Parameter_Specification;
                Prefix : String;
                Nested : Nesting
             )  is
      Shift : Natural := 3;

      procedure Null_Exclusion is
      begin
         if This.Not_Null then
            Put (Output, "not null ");
            Shift := Shift + 9;
         end if;
      end Null_Exclusion;
   begin
      case Nested is
         when Top =>
            Put (Output, Prefix);
         when Child =>
            if Prefix'Length >= 3 then
               Put
               (  Output,
                  Prefix (Prefix'First..Prefix'Last - 3) & "|__"
               );
            end if;
         when Inline =>
            null;
      end case;
      Put (This.Parameters);
      New_Line (Output);
      Put (Output, Prefix & ":  ");
      if This.Aliased_Parameter then
         Put (Output, "aliased ");
         Shift := Shift + 8;
      end if;
      case This.Mode is
         when In_Mode =>
            Null_Exclusion;
         when Inout_Mode =>
            Put (Output, "in out ");
            Shift := Shift + 7;
            Null_Exclusion;
         when Out_Mode =>
            Put (Output, "out ");
            Shift := Shift + 4;
            Null_Exclusion;
         when Access_Mode =>
            null;
      end case;
      case This.Mode is
         when In_Mode | Inout_Mode | Out_Mode =>
            Put (This.Value,   Prefix & (1..Shift => ' '), Inline);
         when Access_Mode =>
            Put (This.Pointer, Prefix & (1..Shift => ' '), Inline);
      end case;
      if This.Default.Present then
         Put (Output, Prefix & ":= ");
         Expression_IO.Put
         (  This.Default.Item,
            Output,
            Prefix & "   ",
            Inline
         );
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Put;

   procedure Put
             (  This   : Parameter_Type;
                Prefix : String;
                Nested : Nesting
             )  is
      Shift : Natural := 0;
   begin
      if not This.Present then
         return;
      end if;
      case Nested is
         when Top =>
            Put (Output, Prefix);
         when Child =>
            if Prefix'Length >= 3 then
               Put
               (  Output,
                  Prefix (Prefix'First..Prefix'Last - 3) & "|__"
               );
            end if;
         when Inline =>
            null;
      end case;
      if This.Aliased_Parameter then
         Put (Output, "aliased ");
         Shift := Shift + 8;
      end if;
      if This.Constant_Parameter then
         Put (Output, "constant ");
         Shift := Shift + 9;
      end if;
      case This.Mode is
         when Access_Mode =>
            Put
            (  This.Access_Parameter,
               Prefix & (1..Shift => ' '),
               Inline
            );
         when Object_Mode =>
            Put
            (  This.Object_Parameter,
               Prefix & (1..Shift => ' '),
               Inline
            );
      end case;
   end Put;

   procedure Put (This : Parent_Unit; Prefix : String) is
   begin
      if This.Separate_Body then
         Put (Output, "separate ");
         Put_Name (This.Parent);
         New_Line (Output);
         Put (Output, Prefix);
      end if;
   end Put;

   procedure Put
             (  This   : Singleton_Parameter;
                Prefix : String;
                Nested : Nesting
             )  is
   begin
      case Nested is
         when Top =>
            Put (Output, Prefix);
         when Child =>
            if Prefix'Length >= 3 then
               Put
               (  Output,
                  Prefix (Prefix'First..Prefix'Last - 3) & "|__"
               );
            end if;
         when Inline =>
            null;
      end case;
      Put (This.Name);
      Put_Line (Output, " at " & Image (This.Name.Term.Location));
      if This.Type_Of.Present then
         Put (Output, Prefix & ":  ");
         Put (This.Type_Of,  Prefix & "   ", Inline);
      end if;
   end Put;

   procedure Put (List : Singleton_Parameter_Array; Prefix : String) is
   begin
      for Index in List'First..List'Last - 1 loop
         Put (List (Index), Prefix & "|  ", Child);
      end loop;
      Put (List (List'Last), Prefix & "   ", Child);
   end Put;

   procedure Put (This : Statement_Sequence; Prefix : String) is
      List : Statement_Ptr_Array renames This.List;
   begin
      for Index in List'First..List'Last - 1 loop
         Put
         (  Tree   => (  List (Index).all'Unchecked_Access,
                         Tree.Location
                      ),
            Output => Output,
            Prefix => Prefix & "|  ",
            Nested => Child
         );
      end loop;
      Put
      (  Tree   => (  List (List'Last).all'Unchecked_Access,
                      Tree.Location
                   ),
         Output => Output,
         Prefix => Prefix & "   ",
         Nested => Child
      );
   end Put;

   procedure Put
             (  This   : Subprogram_Renaming'Class;
                Prefix : String
             )  is
   begin
      if This.Generic_Unit then
         if This.Profile /= null and then
            Is_Library_Unit (This.Profile.Parent.Context.Parent)
         then
            Put_Line (Output, "<library>");
            Put
            (  This.Profile.Parent.Context.Parent,
               Prefix & "   "
            );
            Put (Output, Prefix);
         end if;
         Put (Output, "generic ");
      else
         if This.Profile /= null and then
            Is_Library_Unit (This.Profile.Parent)
         then
            Put_Line (Output, "<library>");
            Put (This.Profile.Parent, Prefix);
            Put (Output, Prefix);
         end if;
      end if;
      if This.Private_Unit then
         Put (Output, "private ");
      end if;
      Put (Output, Image (This.Overrides, " "));
   end Put;

   procedure Put
             (  This   : Subprogram_Specification'Class;
                Prefix : String
             )  is
   begin
      if This.Generic_Unit then
         if This.Profile /= null and then
            Is_Library_Unit (This.Profile.Parent.Context.Parent)
         then
            Put_Line (Output, "<library>");
            Put
            (  This.Profile.Parent.Context.Parent,
               Prefix & "   "
            );
            Put (Output, Prefix);
         end if;
         Put_Line (Output, "generic ");
         if This.Profile = null then
            Put (This.Parent, Prefix);
         else
            Put (This.Profile.Parent, Prefix);
         end if;
         Put (Output, Prefix);
      else
         if This.Profile /= null and then
            Is_Library_Unit (This.Profile.Parent)
         then
            Put_Line (Output, "<library>");
            Put (This.Profile.Parent, Prefix);
            Put (Output, Prefix);
         end if;
      end if;
      if This.Private_Unit then
         Put (Output, "private ");
      end if;
      Put (Output, Image (This.Overrides, " "));
   end Put;

   procedure Put
             (  This   : Subtype_Mark;
                Prefix : String;
                Nested : Nesting
             )  is
   begin
      Expression_IO.Put
      (  This.Name,
         Output,
         Prefix,
         Nested
      );
      case This.Attribute is
         when Class_Attribute =>
            Put_Line (Output, Prefix & "|__'Class");
         when No_Attribute =>
            null;
         when Base_Attribute =>
            Put_Line (Output, Prefix & "|__'Base");
         when Base_Range_Attribute =>
            Put_Line (Output, Prefix & "|__'Base'Range");
         when Dimension_Range_Attribute =>
            Put_Line (Output, Prefix & "|__'Range");
            Expression_IO.Put
            (  This.Dimension,
               Output,
               Prefix & "   |__",
               Child
            );
         when Range_Attribute =>
            Put_Line (Output, Prefix & "|__'Range");
      end case;
   end Put;

   procedure Put
             (  This   : Subtype_Indication;
                Prefix : String;
                Nested : Nesting
             )  is
   begin
      if This.Not_Null then
         case Nested is
            when Top =>
               Put (Output, Prefix);
            when Child =>
               if Prefix'Length >= 3 then
                  Put
                  (  Output,
                     Prefix (Prefix'First..Prefix'Last - 3) & "|__"
                  );
               end if;
            when Inline =>
               null;
         end case;
         Put (Output, "not null ");
         Put (This.Mark, Prefix & "         ", Inline);
      else
         Put (This.Mark, Prefix, Nested);
      end if;
      case This.Constraint.Mode is
         when No_Constraint =>
            null;
         when Fixed_Point_Constraint =>
            Put (Output, Prefix & "   delta ");
            Expression_IO.Put
            (  This.Constraint.Delta_Constraint,
               Output,
               Prefix & "         ",
               Inline
            );
         when Floating_Point_Constraint =>
            Put (Output, Prefix & "   digits ");
            Expression_IO.Put
            (  This.Constraint.Digits_Constraint,
               Output,
               Prefix & "          ",
               Inline
            );
         when Index_Constraint | Discriminant_Constraint =>
            Expression_IO.Put
            (  This.Constraint.Constraint,
               Output,
               Prefix & "   ",
               Top
            );
      end case;
      case This.Mode is
         when Subtype_Mode | Range_Mode =>
            null;
         when Subtype_Range_Mode =>
            Put (Output, Prefix & "   range ");
            Expression_IO.Put
            (  This.Range_Constraint,
               Output,
               Prefix & "         ",
               Inline
            );
         when Unconstrained_Mode =>
            Put (Output, Prefix & "  range <>");
      end case;
   end Put;

   procedure Put
             (  List   : Subtype_Indication_Array;
                Prefix : String
             )  is
   begin
      for Index in List'First..List'Last - 1 loop
         Put (List (Index), Prefix & "|  ", Child);
      end loop;
      Put (List (List'Last), Prefix & "   ", Child);
   end Put;

    procedure Put
              (  This   : Variant_Part_Item;
                 Prefix : String;
                 Suffix : String
              )  is
    begin
       if This.Choices_Count > 0 then
          Put_Line (Output,  Prefix & "|__when");
          Put (This.Choices, Prefix & Suffix);
          Put_Line (Output,  Prefix & Suffix & "=>");
       else
          Put_Line (Output,  Prefix & "|__others");
       end if;
       Put (This.Components.all, Prefix & Suffix, False);
    end Put;

   procedure Put_Interfaces
             (  List   : Subtype_Mark_Array;
                Prefix : String;
                First  : String := "and"
             )  is
   begin
      if List'Length > 0 then
         Put (Output, Prefix & "|__" & First & " ");
         Put_Line (Output, Image (List (List'First)));
         for Index in List'First + 1..List'Last loop
            Put (Output, Prefix & "|__and ");
            Put_Line (Output, Image (List (Index)));
         end loop;
      end if;
   end Put_Interfaces;

   procedure Put_Labels
             (  Labels : Defining_Identifier_Array;
                Prefix : String
             )  is
   begin
      for Index in Labels'Range loop
         Put (Output, "<<");
         Put (Output, Labels (Index).Name.Value);
         Put_Line (Output, ">>");
         Put (Output, Prefix);
      end loop;
   end Put_Labels;

   procedure Put_Name (Name : Tokens.Argument_Token) is
   begin
      if Name.Value.all in Expression then
         declare
            This : Expression renames Expression (Name.Value.all);
         begin
            if This.Operation = Component then
              for Index in This.Operands'Range loop
                 if Index > This.Operands'First then
                    Put (Output, ".");
                 end if;
                 Put (Output, Image (This.Operands (Index).Value.all));
              end loop;
              return;
            end if;
         end;
      end if;
      Put (Output, Image (Name.Value.all));
   end Put_Name;

   procedure Put_Names (List : Argument_List; Prefix : String) is
   begin
      for Index in List'Range loop
         Put (Output, Prefix);
         Put (Output, "|__");
         Put_Name (List (Index));
         Put (Output, " at ");
         Put_Line (Output, Image (List (Index).Location));
      end loop;
   end Put_Names;
------------------------------------------------------------------------
   procedure Do_Put (This : Abort_Statement; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      Put (Output, "abort at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Tasks, Prefix);
   end Do_Put;

   procedure Do_Put (This : Accept_Statement; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      Put (Output, "accept ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      if This.Index.Present then
         Put (Output, Prefix & "   index ");
         Expression_IO.Put
         (  This.Index.Item,
            Output,
            Prefix & "         ",
            Inline
         );
      end if;
      Put (This.Profile, Prefix & "   ", "parameter");
      if This.Sequence /= null then
         Put_Line (Output, Prefix & "do");
         Put (This.Sequence.all, Prefix);
      end if;
   end Do_Put;

   procedure Do_Put (This : Access_Type_Declaration; Prefix : String) is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Pointer, Prefix & "   ", Top);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Array_Type_Declaration; Prefix : String) is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Definition.all, Prefix & "   ", Top);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Assignment_Statement; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      Put (Output, "assignment at ");
      Put_Line (Output, Image (Tree.Location));
      Expression_IO.Put
      (  This.Variable,
         Output,
         Prefix & "   ",
         Top
      );
      Put (Output, Prefix & ":= ");
      Expression_IO.Put
      (  This.Expression,
         Output,
         Prefix & "   ",
         Inline
      );
   end Do_Put;

   procedure Do_Put
             (  This   : Asynchronous_Transfer_Control;
                Prefix : String
             )  is
   begin
      Put_Labels (This.Labels, Prefix);
      Put_Line (Output, "select at " & Image (Tree.Location));
      Put
      (  (  This.Trigger.all'Unchecked_Access,
            Tree.Location
         ),
         Output,
         Prefix & "   ",
         Top
      );
      if This.Triggered /= null then
         Put_Line (Output, Prefix & "then");
         Put (This.Triggered.all, Prefix);
      end if;
      Put_Line (Output,        Prefix & "then abort");
      Put (This.Abortable.all, Prefix);
   end Do_Put;

   procedure Do_Put (This : At_Clause; Prefix : String) is
   begin
      Put (Output, "for ");
      Put_Name (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix & "|__use at ");
      Expression_IO.Put
      (  This.Address,
         Output,
         Prefix & "          ",
         Inline
      );
   end Do_Put;

   procedure Do_Put
             (  This   : Attribute_Definition_Clause;
                Prefix : String
             )  is
   begin
      Put (Output, "for ");
      Put_Name (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix & "|__'");
      Expression_IO.Put
      (  This.Attribute,
         Output,
         Prefix & "|  ",
         Inline
      );
      Put (Output, Prefix & "|__use ");
      Expression_IO.Put
      (  This.Value,
         Output,
         Prefix & "       ",
         Inline
      );
   end Do_Put;

   procedure Do_Put (This : Block_Statement; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      if This.Named then
         Put_Name (This.Name.Item);
         Put_Line (Output, " : ");
         Put (Output, Prefix);
      end if;
      Put (Output, "block at ");
      Put_Line (Output, Image (Tree.Location));
      if This.Declarations /= null then
         Put (This.Declarations.all, Prefix);
      end if;
      Put_Line (Output, Prefix & "begin");
      Put (This.Sequence.all, Prefix);
   end Do_Put;

   procedure Do_Put (This : Call_Statement; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      Expression_IO.Put (This.Target, Output, Prefix, Inline);
   end Do_Put;

   procedure Do_Put (This : Case_Statement; Prefix : String) is
      List : Choice_Alternatives_Array renames This.Alternatives;
      Last : Integer := List'Last;
   begin
      if This.Default = null then
         Last := Last - 1;
      end if;
      Put_Labels (This.Labels, Prefix);
      Put (Output, "case at ");
      Put_Line (Output, Image (Tree.Location));
      Expression_IO.Put
      (  This.Selector,
         Output,
         Prefix & "|  ",
         Top
      );
      for Index in List'First..List'Last loop
         Put_Line (Output, Prefix & "|__when");
         Put (List (Index).Choice.all,    Prefix & "|  ");
         Put_Line (Output, Prefix & "|  =>");
         Put (List (Index).Code.all, Prefix & "|  ");
      end loop;
      if This.Default = null then
         Put_Line (Output, Prefix & "|__when");
         Put (List (List'Last).Choice.all,    Prefix & "|  ");
         Put_Line (Output, Prefix & "|__=>");
         Put (List (List'Last).Code.all, Prefix & "   ");
      else
         Put_Line (Output, Prefix & "|__when others =>");
         Put (This.Default.all, Prefix & "   ");
      end if;
   end Do_Put;

   procedure Do_Put (This : Conditional_Entry_Call; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      Put_Line (Output, "select at " & Image (Tree.Location));
      Put (Output,                 Prefix & "   ");
      Do_Put (This.Entry_Call.all, Prefix & "   ");
      if This.Accepted_Code /= null then
         Put_Line (Output,            Prefix & "then");
         Put (This.Accepted_Code.all, Prefix);
      end if;
      Put_Line (Output,            Prefix & "else");
      Put (This.Rejected_Code.all, Prefix);
   end Do_Put;

   procedure Do_Put
             (  This   : Decimal_Fixed_Point_Type_Declaration;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix);
      Put (Output, "   delta ");
      Expression_IO.Put
      (   This.Digits_Value,
          Output,
          Prefix & "        ",
          Inline
      );
      Put (Output, Prefix);
      Put (Output, "   digits ");
      Expression_IO.Put
      (   This.Digits_Value,
          Output,
          Prefix & "         ",
          Inline
      );
      if This.Constrained then
         Put (Output, Prefix);
         Put (Output, "   range ");
         Expression_IO.Put
         (  This.Constraint.Item,
             Output,
             Prefix & "         ",
             Inline
         );
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Delay_Statement; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      Put (Output, "delay at ");
      Put_Line (Output, Image (Tree.Location));
      if This.Relative then
         Expression_IO.Put
         (  This.Time,
            Output,
            Prefix & "   ",
            Top
         );
      else
         Put (Output, Prefix & "   until ");
         Expression_IO.Put
         (  This.Time,
            Output,
            Prefix & "         ",
            Inline
         );
      end if;
   end Do_Put;

   procedure Do_Put
             (  This   : Derived_Type_Declaration;
                Prefix : String
             )  is
      Shift : Natural := 0;
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Discriminants, Prefix & "   ", "discriminant");
      Put (Output, Prefix);
      Put (Output, "   ");
      if This.Abstract_Type then
         Put (Output, "abstract ");
         Shift := Shift + 9;
      end if;
      if This.Limited_Type then
         Put (Output, "limited ");
         Shift := Shift + 8;
      end if;
      if Shift > 0 then
         New_Line (Output);
         Put (Output, Prefix & "   ");
      end if;
      Put_Line (Output, "|__new " & Image (This.Parent_Type));
      Put_Interfaces (This.Interfaces, Prefix & "   ");
      if This.Extension_Record then
         if This.Extension = null then
            Put_Line (Output, Prefix & "   |__with null record");
         else
            Put (Output, Prefix);
            Put_Line (Output, "   |__with record");
            Put (This.Extension.all, Prefix & "      ", False);
         end if;
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Entry_Declaration; Prefix : String) is
   begin
      Put (Output, Image (This.Overrides, " "));
      Put (Output,"entry ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      if This.Is_Family then
         Put (Output, Prefix & "family ");
         Expression_IO.Put
         (  This.Index.Item,
            Output,
            Prefix & "       ",
            Inline
         );
      end if;
      Put (This.Profile, Prefix & "   ", "parameter");
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Entry_Body; Prefix : String) is
   begin
      Put (Output, Image (This.Overrides, " "));
      Put (Output,"entry ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      if This.Index.Present then
         Put (Output, Prefix & "index ");
         Expression_IO.Put
         (  This.Index.Item,
            Output,
            Prefix & "      ",
            Inline
         );
      end if;
      Put (This.Profile, Prefix & "   ", "parameter");
      Put (This.Declarations.all, Prefix);
      Put (Output, Prefix & "   when ");
      Expression_IO.Put
      (  This.Barrier,
         Output,
         Prefix & "        ",
         Inline
      );
      Put_Line (Output, Prefix & "begin");
      Put (This.Code.all, Prefix);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Enumeration_Representation_Clause;
                Prefix : String
             )  is
      procedure Put (This : Alternative_Pair; Suffix : String) is
      begin
         Put (Output, Prefix & "   |__");
         Expression_IO.Put
         (  This.Guard,
            Output,
            Prefix & "   " & Suffix & "|  ",
            Inline
         );
         Put (Output, Prefix & "   " & Suffix & "|__=> ");
         Expression_IO.Put
         (  This.Guard,
            Output,
            Prefix & "   " & Suffix & "      ",
            Inline
         );
      end Put;

      List : Guarded_List renames This.Enumeration;
   begin
      Put (Output, "for ");
      Put_Name (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put_Line (Output,      Prefix & "   use");
      for Index in List'First..List'Last - 1 loop
         Put (List (Index), "|  ");
      end loop;
      Put (List (List'Last), "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Enumeration_Type_Declaration;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put_Line (Output, Prefix & "   enumeration");
      Put (This.List, Prefix & "   ");
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Exception_Declaration; Prefix : String) is
   begin
      Put (Output, "exception");
      if This.Names'Length > 1 then
         Put (Output, "s");
      end if;
      Put (Output, " ");
      Put (This.Names);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Exception_Renaming; Prefix : String) is
   begin
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put_Line (Output, Prefix & ":  exception");
      Put (Output, Prefix & "   renames ");
      Expression_IO.Put
      (  This.Target,
         Output,
         Prefix & "           ",
         Inline
      );
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Exit_Statement; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      Put (Output, "exit at ");
      Put_Line (Output, Image (Tree.Location));
      if This.Loop_Name.Present then
         Put (This.Loop_Name.Item);
         New_Line (Output);
      end if;
      if This.Condition.Present then
         Put (Output, Prefix & "   when ");
         Expression_Io.Put
         (  This.Condition.Item,
            Output,
            Prefix & "        ",
            Inline
         );
      end if;
   end Do_Put;

   procedure Do_Put
             (  This   : Extended_Return_Statement;
                Prefix : String
             )  is
   begin
      Put_Labels (This.Labels, Prefix);
      Put (Output, "return at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Result, Prefix & "   ", Child);
      if This.Initial.Present then
         Put (Output, Prefix & "   := ");
         Expression_IO.Put
         (  This.Initial.Item,
            Output,
            Prefix & "      ",
            Inline
         );
      end if;
      if This.Code /= null then
         Put_Line (Output, Prefix & "do");
         Put (This.Code.all, Prefix & "   ");
      end if;
   end Do_Put;

   procedure Do_Put (This : For_Loop_Statement; Prefix : String) is
      Shift : Natural := 0;
   begin
      Put_Labels (This.Labels, Prefix);
      if This.Named then
         Put_Name (This.Name.Item);
         Put_Line (Output, " : ");
         Put (Output, Prefix);
      end if;
      Put (Output, "for at ");
      Put_Line (Output, Image (Tree.Location));
      if This.Chunk /= null then
         Put_Line (Output, Prefix & "parallel");
         Put (This.Chunk.all, Prefix & "   ");
      end if;
      case This.Mode is
         when In_Interation_Mode | Of_Interation_Mode =>
            Put (This.Parameter, Prefix & "   ");
            Put (Output, Prefix & "      ");
            if This.Mode = In_Interation_Mode then
               Put (Output, "in ");
            else
               Put (Output, "of ");
            end if;
            Shift := Shift + 9;
            if This.In_Reverse then
               Put (Output, "reverse ");
               Shift := Shift + 8;
            end if;
            Put
            (  This.Iterator_Subtype,
               Prefix & (1..Shift => ' '),
               Inline
            );
         when Formal_Part_Mode =>
            Put (This.Formal_Part, Prefix & "   ", "parameter");
            Put (Output, Prefix & "   of ");
            Expression_IO.Put
            (  This.Iterator_Call,
               Output,
               Prefix & "      ",
               Inline
            );
         when List_Mode =>
            Put (This.Iterator.List, Prefix & "   ");
            Put (Output, Prefix & "   of ");
            Expression_IO.Put
            (  This.Iterator_Call,
               Output,
               Prefix & "      ",
               Inline
            );
      end case;
      if This.Has_Iterator_Filter then
         Put_Line (Output, Prefix & "when");
         Put (This.Iterator_Filter.Item, Prefix & "   ");
      end if;
      if This.Sequence /= null then
         Put_Line (Output, Prefix & "loop");
         Put (This.Sequence.all, Prefix);
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Formal_Access_Type_Parameter;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      if This.Not_Null then
         Put (Output,       Prefix & "   not null ");
         Put (This.Pointer, Prefix & "            ", Inline);
      else
         Put (Output,       Prefix & "   ");
         Put (This.Pointer, Prefix & "   ", Inline);
      end if;
      Put (This.Default, Prefix);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Formal_Array_Type_Parameter;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Definition.all, Prefix & "   ", Top);
      Put (This.Default, Prefix);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Formal_Derived_Type_Parameter;
                Prefix : String
             )  is
      Shift : Natural := 0;
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Discriminants, Prefix & "   ", "discriminant");
      Put (Output, Prefix & "   ");
      if This.Abstract_Type then
         Put (Output, "abstract ");
         Shift := Shift + 9;
      end if;
      case This.Mode is
         when Any_Interface =>
            null;
         when Limited_Interface =>
            Put (Output, "limited ");
            Shift := Shift + 8;
         when Synchronized_Interface =>
            Put (Output, "synchronized ");
            Shift := Shift + 13;
      end case;
      if Shift > 0 then
         New_Line (Output);
         Put (Output, Prefix);
      end if;
      Put (Output, "   |__new ");
      Put_Name (This.Parent_Type);
      Put_Interfaces (This.Interfaces, Prefix & "   ");
      Put (This.Default, Prefix);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Formal_Function_Parameter;
                Prefix : String
             )  is
   begin
      Put (Output, "with ");
      if This.Abstract_Subprogram then
         Put (Output, "abstract ");
      end if;
      Put (Output, "function ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Profile,    Prefix & "   ", "parameter");
      Put (Output,          Prefix & "   return ");
      Put (This.Result.all, Prefix & "          ", Inline);
      case This.Default is
         when Name_Default =>
            Put_Line (Output, Prefix & ":= ");
            Expression_IO.Put
            (  This.Default_Name,
               Output,
               Prefix & "   ",
               Inline
            );
         when No_Default =>
            null;
         when Box_Default =>
            Put_Line (Output, Prefix & ":= <>");
      end case;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Formal_Incomplete_Type_Parameter;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Discriminants, Prefix, "discriminant");
      if This.Tagged_Type then
         Put_Line (Output, Prefix & "   tagged");
      end if;
      Put (This.Default, Prefix);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Formal_Interface_Type_Parameter;
                Prefix : String
             )  is
   begin
      case This.Mode is
         when Any_Interface =>
            null;
         when Limited_Interface =>
            Put (Output, "limited ");
         when Protected_Interface =>
            Put (Output, "protected ");
         when Synchronized_Interface =>
            Put (Output, "synchronized ");
         when Task_Interface =>
            Put (Output, "task ");
      end case;
      Put (Output, "interface ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put_Interfaces (This.Interfaces, Prefix & "   ");
      Put (This.Default, Prefix);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Formal_Package_Parameter;
                Prefix : String
             )  is
   begin
      Put (Output, "with package ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix & "new ");
      Put_Name (This.Target);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Formal_Private_Type_Parameter;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix & "  ");
      if This.Abstract_Type then
         Put (Output, "abstract ");
      end if;
      if This.Limited_Type then
         Put (Output, "limited ");
      end if;
      if This.Tagged_Type then
         Put (Output, "tagged ");
      end if;
      Put_Line (Output, "private");
      Put (This.Discriminants, Prefix, "discriminant");
      Put (This.Default, Prefix);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Formal_Procedure_Parameter;
                Prefix : String
             )  is
   begin
      Put (Output, "with ");
      if This.Abstract_Subprogram then
         Put (Output, "abstract ");
      end if;
      Put (Output, "procedure ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Profile, Prefix & "   ", "parameter");
      case This.Default is
         when Name_Default =>
            Put_Line (Output, Prefix & ":= ");
            Expression_IO.Put
            (  This.Default_Name,
               Output,
               Prefix & "   ",
               Inline
            );
         when No_Default =>
            null;
         when Box_Default =>
            Put_Line (Output, Prefix & ":= <>");
         when Null_Default =>
            Put_Line (Output, Prefix & ":= null");
      end case;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Formal_Scalar_Type_Parameter;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put_Line (Output, Prefix & "   " & Image (This.Kind_Of));
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Floating_Point_Type_Declaration;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix);
      Put (Output, "   digits ");
      Expression_IO.Put
      (   This.Digits_Value,
          Output,
          Prefix & "         ",
          Inline
      );
      if This.Constrained then
         Put (Output, Prefix);
         Put (Output, "   range ");
         Expression_IO.Put
         (  This.Constraint.Item,
             Output,
             Prefix & "         ",
             Inline
         );
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Function_Body; Prefix : String) is
   begin
      if Is_Library_Unit (This.Declarations.Parent) then
         Put_Line (Output, "<library>");
         Put (This.Declarations.Parent, Prefix);
         Put (Output, Prefix);
      end if;
      Put (This.Parent, Prefix);
      Put (Output, "function ");
      Put_Name (This.Full_Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Profile,     Prefix & "   ", "parameter");
      Put (Output,           Prefix & "   return ");
      Put (This.Result.all,  Prefix & "          ", Inline);
      Put (This.Declarations.all, Prefix);
      Put_Line (Output, Prefix & "begin");
      Put (This.Code.all, Prefix);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Function_Declaration; Prefix : String) is
   begin
      Put (This, Prefix);
      if This.Abstract_Subprogram then
         Put (Output, "abstract ");
      end if;
      Put (Output, "function ");
      Put_Name (This.Full_Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Profile,    Prefix & "   ", "parameter");
      Put (Output,          Prefix & "   return ");
      Put (This.Result.all, Prefix & "          ", Inline);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Function_Expression; Prefix : String) is
   begin
      Put (Output, "function ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Profile,    Prefix & "   ", "parameter");
      Put (Output,          Prefix & "   return ");
      Put (This.Result.all, Prefix & "          ", Inline);
      Put (Output, Prefix & ":= ");
      Expression_IO.Put
      (  This.Expression,
         Output,
         Prefix & "   ",
         Inline
      );
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Function_Instantiation; Prefix : String) is
   begin
      Put (Output, Image (This.Overrides, " "));
      Put (Output, "function ");
      Put_Name (This.Full_Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix & "   is new ");
      Put_Name (This.Target);
      New_Line (Output);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Function_Renaming; Prefix : String) is
   begin
      Put (This, Prefix);
      Put (Output,"function ");
      Put_Name (This.Full_Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      if not This.Generic_Unit then
         Put (This.Profile, Prefix & "   ", "parameter");
         Put (Output,          Prefix & "   return ");
         Put (This.Result.all, Prefix & "          ", Inline);
      end if;
      Put (Output, Prefix & "   renames ");
      Expression_IO.Put
      (  This.Target,
         Output,
         Prefix & "           ",
         Inline
      );
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Function_Stub; Prefix : String) is
   begin
      Put (Output, Image (This.Overrides, " "));
      Put (Output,"function body stub ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Profile,    Prefix & "   ", "parameter");
      Put (Output,          Prefix & "   return ");
      Put (This.Result.all, Prefix & "          ", Inline);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Goto_Statement; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      Put (Output, "goto ");
      Put_Name (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
   end Do_Put;

   procedure Do_Put (This : If_Statement; Prefix : String) is
      List : Guarded_Alternatives_Array renames This.Alternatives;
      Last : Integer := List'Last;
   begin
      if This.Default = null then
         Last := Last - 1;
      end if;
      Put_Labels (This.Labels, Prefix);
      Put (Output, "if at ");
      Put_Line (Output, Image (Tree.Location));
      if List'Length = 1 and then This.Default = null then
         Put (Output, Prefix & "|__when ");
         Expression_IO.Put
         (  List (List'First).Guard,
            Output,
            Prefix & "   |    ",
            Inline
         );
         Put_Line (Output, Prefix & "   then");
         Put (List (List'First).Code.all, Prefix & "   ");
      else
         Put (Output, Prefix & "|__when ");
         Expression_IO.Put
         (  List (List'First).Guard,
            Output,
            Prefix & "|  |    ",
            Inline
         );
         Put_Line (Output, Prefix & "|  then");
         Put (List (List'First).Code.all, Prefix & "|  ");
      end if;
      for Index in List'First + 1..Last loop
         Put (Output, Prefix & "|__when ");
         Expression_IO.Put
         (  List (Index).Guard,
            Output,
            Prefix & "|  |     ",
            Inline
         );
         Put_Line (Output, Prefix & "|  then");
         Put (List (List'First).Code.all, Prefix & "|  ");
      end loop;
      if This.Default = null then
         if List'Length > 1 then
            Put (Output, Prefix & "|__when ");
            Expression_IO.Put
            (  List (List'Last).Guard,
               Output,
               Prefix & "  |      ",
               Inline
            );
            Put_Line (Output, Prefix & "   then");
            Put (List (List'Last).Code.all, Prefix & "   ");
         end if;
      else
         Put_Line (Output, Prefix & "|__else");
         Put (This.Default.all, Prefix & "   ");
      end if;
   end Do_Put;

   procedure Do_Put
             (  This   : Incomplete_Type_Declaration;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Discriminants, Prefix & "   ", "discriminant");
      Put (Output, Prefix);
      Put (Output, "   ");
      if This.Tagged_Type then
         Put (Output, "tagged ");
      end if;
      Put_Line (Output, "incomplete");
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Interface_Type_Declaration;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Discriminants, Prefix & "   ", "discriminant");
      Put (Output, Prefix);
      Put (Output, "   ");
      case This.Mode is
         when Any_Interface =>
            null;
         when Limited_Interface =>
            Put (Output, "limited ");
         when Protected_Interface =>
            Put (Output, "protected ");
         when Synchronized_Interface =>
            Put (Output, "synchronized ");
         when Task_Interface =>
            Put (Output, "task ");
      end case;
      Put_Line (Output, "interface");
      Put_Interfaces (This.Interfaces, Prefix & "   ");
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Loop_Statement; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      if This.Named then
         Put_Name (This.Name.Item);
         Put_Line (Output, " : ");
         Put (Output, Prefix);
      end if;
      Put (Output, "loop at ");
      Put_Line (Output, Image (Tree.Location));
      if This.Sequence /= null then
         Put (This.Sequence.all, Prefix);
      end if;
   end Do_Put;

   procedure Do_Put
             (  This   : Modular_Type_Declaration;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix);
      Put (Output, "   mod ");
      Expression_IO.Put
      (  This.Modulus,
          Output,
          Prefix & "       ",
          Inline
      );
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Null_Procedure; Prefix : String) is
   begin
      if This.Private_Unit then
         Put (Output, "private ");
      end if;
      Put (Output, Image (This.Overrides, " "));
      Put (Output,"null procedure ");
      Put_Name (This.Full_Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Profile, Prefix & "   ", "parameter");
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Object_Declaration; Prefix : String) is
   begin
      if This.Aliased_Object then
         Put (Output, "aliased ");
      end if;
      if This.Immutable then
         Put (Output, "constant ");
      end if;
      if This.Names'Length > 1 then
         Put (Output, "objects ");
      else
         Put (Output, "object ");
      end if;
      Put (This.Names);
       Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix & ":  ");
      Put (This.Definition.all, Prefix & "   ", Inline);
      if This.Initial.Present then
         Put (Output, Prefix);
         Put (Output, ":= ");
         Expression_IO.Put
         (  This.Initial.Item,
            Output,
            Prefix & "   ",
            Inline
         );
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Object_Renaming; Prefix : String) is
   begin
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix & ":  ");
      Put (This.Type_Of, Prefix & "   ", Inline);
      Put (Output, Prefix & "   renames ");
      Expression_IO.Put
      (  This.Target,
         Output,
         Prefix & "           ",
         Inline
      );
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Ordinary_Fixed_Point_Type_Declaration;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix);
      Put (Output, "   delta ");
      Expression_IO.Put
      (  This.Delta_Value,
          Output,
          Prefix & "        ",
          Inline
      );
      if This.Constrained then
         Put (Output, Prefix);
         Put (Output, "   range ");
         Expression_IO.Put
         (  This.Constraint.Item,
             Output,
             Prefix & "         ",
             Inline
         );
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Package_Body; Prefix : String) is
   begin
      if Is_Library_Unit (This.Declarations.Parent) then
         Put_Line (Output, "<library>");
         Put (This.Declarations.Parent, Prefix);
         Put (Output, Prefix);
      end if;
      Put (This.Parent, Prefix);
      Put (Output,"package body ");
      Put_Name (This.Full_Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Declarations.all, Prefix);
      if This.Code /= null then
         Put_Line (Output, Prefix & "begin");
         Put (This.Code.all, Prefix);
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Package_Declaration; Prefix : String) is
   begin
      if This.Generic_Unit then
         if Is_Library_Unit (This.Public_Part.Parent.Context.Parent)
         then
            Put_Line (Output, "<library>");
            Put (This.Public_Part.Parent.Context.Parent, Prefix);
         end if;
         Put_Line (Output, "generic");
         Put (This.Public_Part.Parent, Prefix);
         Put (Output, Prefix);
      else
         if Is_Library_Unit (This.Public_Part.Parent) then
            Put_Line (Output,"<library>");
            Put (This.Public_Part.Parent, Prefix);
            Put (Output, Prefix);
         end if;
      end if;
      if This.Private_Unit then
         Put (Output, "private ");
      end if;
      Put (Output, "package ");
      Put_Name (This.Full_Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      if This.Public_Part.Declarations'Length > 0 then
         Put (This.Public_Part.all, Prefix);
      end if;
      if This.Private_Part /= null and then
         This.Private_Part.Declarations'Length > 0
      then
         Put_Line (Output, Prefix & "private");
         Put (This.Private_Part.all, Prefix);
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Package_Instantiation; Prefix : String) is
   begin
      Put (Output, "package ");
      Put_Name (This.Full_Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix & "   is new ");
      Put_Name (This.Target);
      New_Line (Output);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Package_Renaming; Prefix : String) is
   begin
      if Is_Library_Unit (This.Parent) then
         Put_Line (Output,"<library>");
         Put (This.Parent, Prefix);
         Put (Output, Prefix);
      end if;
      if This.Generic_Unit then
         Put (Output,"generic ");
      end if;
      Put (Output,"package ");
      Put_Name (This.Full_Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix & "   renames ");
      Expression_IO.Put
      (  This.Target,
         Output,
         Prefix & "           ",
         Inline
      );
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Package_Stub; Prefix : String) is
   begin
      Put (Output,"package body stub ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Parallel_Block_Statement;
                Prefix : String
             )  is
   begin
      Put_Labels (This.Labels, Prefix);
      Put (Output, "parallel at ");
      Put_Line (Output, Image (Tree.Location));
      if This.Chunk /= null then
         Put (This.Chunk.all, Prefix & "   ");
      end if;
      for Index in This.Paths'First..This.Paths'Last - 1 loop
         Put_Line (Output, Prefix & "|__and");
         Put (This.Paths (Index).all, Prefix & "|  ");
      end loop;
      Put_Line (Output, Prefix & "|__and");
      Put (This.Paths (This.Paths'Last).all, Prefix & "   ");
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Pragma_Clause; Prefix : String) is
      procedure Put
                (  This   : Pragma_Argument_Association;
                   Prefix : String;
                   Suffix : String
                )  is
      begin
         if This.Argument.Present then
            Put_Line (Output, Prefix & "|__=>");
            Expression_IO.Put
            (  This.Argument.Item,
               Output,
               Prefix & Suffix & "|  ",
               Child
            );
            Expression_IO.Put
            (  This.Value,
               Output,
               Prefix & Suffix & "   ",
               Child
            );
         else
            Expression_IO.Put
            (  This.Value,
               Output,
               Prefix & Suffix,
               Child
            );
         end if;
      end Put;
   begin
      Put (Output, "pragma ");
      Put (This.Name);
      New_Line (Output);
      if This.Associations'Length > 0 then
         for Index in 1..This.Count - 1 loop
            Put (This.Associations (Index), Prefix, "|  ");
         end loop;
         Put (This.Associations (This.Count), Prefix, "   ");
      end if;
   end Do_Put;

   procedure Do_Put
             (  This   : Private_Extension_Type_Declaration;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix);
      Put (Output, "   ");
      if This.Abstract_Type then
         Put (Output, "abstract ");
      end if;
      case This.Mode is
         when Any_Interface =>
            null;
         when Limited_Interface =>
            Put (Output, "limited ");
         when Synchronized_Interface =>
            Put (Output, "synchronized ");
      end case;
      Put_Line (Output, "private");
      if This.Discriminants /= null then
         Put (This.Discriminants.all, Prefix & "   ", "discriminant");
      end if;
      Put (Output, Prefix & "   |__new ");
      Put_Line (Output, Image (This.Parent_Type));
      Put_Interfaces (This.Interfaces, Prefix & "   ");
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Private_Type_Declaration;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix);
      Put (Output, "   ");
      if This.Abstract_Type then
         Put (Output, "abstract ");
      end if;
      if This.Tagged_Type then
         Put (Output, "tagged ");
      end if;
      if This.Limited_Type then
         Put (Output, "limited ");
      end if;
      Put_Line (Output, "private");
      if This.Discriminants /= null then
         Put (This.Discriminants.all, Prefix & "   ", "discriminant");
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Procedure_Body; Prefix : String) is
   begin
      if Is_Library_Unit (This.Declarations.Parent) then
         Put_Line (Output, "<library>");
         Put (This.Declarations.Parent, Prefix);
         Put (Output, Prefix);
      end if;
      Put (This.Parent, Prefix);
      Put (Output,"procedure ");
      Put_Name (This.Full_Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Profile, Prefix & "   ", "parameter");
      Put (This.Declarations.all, Prefix);
      Put_Line (Output, Prefix & "begin");
      Put (This.Code.all, Prefix);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Procedure_Declaration; Prefix : String) is
   begin
      Put (This, Prefix);
      if This.Abstract_Subprogram then
         Put (Output, "abstract ");
      end if;
      Put (Output,"procedure ");
      Put_Name (This.Full_Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Profile, Prefix & "   ", "parameter");
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Procedure_Instantiation; Prefix : String) is
   begin
      Put (Output, Image (This.Overrides, " "));
      Put (Output, "procedure ");
      Put_Name (This.Full_Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix & "   is new ");
      Put_Name (This.Target);
      New_Line (Output);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Procedure_Renaming; Prefix : String) is
   begin
      Put (This, Prefix);
      Put (Output,"procedure ");
      Put_Name (This.Full_Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      if not This.Generic_Unit then
         Put (This.Profile, Prefix & "   ", "parameter");
      end if;
      Put (Output, Prefix & "   renames ");
      Expression_IO.Put
      (  This.Target,
         Output,
         Prefix & "           ",
         Inline
      );
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Procedure_Stub; Prefix : String) is
   begin
      Put (Output, Image (This.Overrides, " "));
      Put (Output,"procedure body stub ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Profile, Prefix & "   ", "parameter");
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Protected_Body; Prefix : String) is
   begin
      if Is_Library_Unit (This.Declarations.Parent) then
         Put_Line (Output, "<library>");
         Put (This.Declarations.Parent, Prefix);
         Put (Output, Prefix);
      end if;
      Put (This.Parent, Prefix);
      Put (Output,"protected body ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Declarations.all, Prefix);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Protected_Stub; Prefix : String) is
   begin
      Put (Output,"protected body stub ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Protected_Type_Declaration;
                Prefix : String
             )  is
   begin
      Put (Output, "protected type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Discriminants, Prefix & "   ", "discriminant");
      Put_Interfaces (This.Interfaces, Prefix & "   ");
      if This.Public_Part.Declarations'Length > 0 then
         Put (This.Public_Part.all, Prefix);
      end if;
      if This.Private_Part /= null and then
         This.Private_Part.Declarations'Length > 0
      then
         Put_Line (Output, Prefix & "private");
         Put (This.Private_Part.all, Prefix);
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Raise_Statement; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      if This.Reraise then
         Put (Output, "raise at ");
         Put_Line (Output, Image (Tree.Location));
      else
         Put (Output, "raise ");
         Put_Name (This.Name);
         Put (Output, " at ");
         Put_Line (Output, Image (Tree.Location));
         if This.Text.Present then
            Expression_IO.Put
            (  This.Text.Item,
               Output,
               Prefix & "|  ",
               Child
           );
         end if;
      end if;
   end Do_Put;

   procedure Do_Put
             (  This   : Record_Representation_Clause;
                Prefix : String
             )  is
      procedure Put (This : Component_Clause; Suffix : String) is
      begin
         Put (Output, Prefix & "   |__");
         Put_Name (This.Name);
         New_Line (Output);
         Put (Output, Prefix & "   " & Suffix & "|__at ");
         Expression_IO.Put
         (  This.Position,
            Output,                  -- "|__at "
            Prefix &   "   " & Suffix & "|     ",
            Inline
         );
         Put (Output, Prefix & "   " & Suffix & "|__range ");
         Expression_IO.Put
         (  This.Bit_Range,
            Output,                  -- "|__range "
            Prefix &   "   " & Suffix & "|        ",
            Inline
         );
      end Put;

      List : Component_Clause_Array renames This.Components;
   begin
      Put (Output, "for ");
      Put_Name (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix & "   use record");
      if This.Modulus.Present then
         Put (Output, " at mod ");
         Expression_IO.Put
         (  This.Modulus.Item,
            Output, -- "   use record  at mod "
            Prefix &   "   |                  ",
            Inline
         );
      else
         New_Line (Output);
      end if;
      if List'Length > 0 then
         for Index in List'First..List'Last - 1 loop
            Put (List (Index), "|  ");
         end loop;
         Put (List (List'Last), "   ");
      end if;
   end Do_Put;

   procedure Do_Put (This : Record_Type_Declaration; Prefix : String) is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Discriminants, Prefix & "   ", "discriminant");
      Put (Output, Prefix);
      Put (Output, "   ");
      if This.Abstract_Type then
         Put (Output, "abstract ");
      end if;
      if This.Tagged_Type then
         Put (Output, "tagged ");
      end if;
      if This.Limited_Type then
         Put (Output, "limited ");
      end if;
      if This.Components = null then
         Put_Line (Output, "null record");
      else
         Put_Line (Output, "record");
         Put (This.Components.all, Prefix & "   ", False);
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Requeue_Statement; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      Put (Output, "requeue ");
      Put_Name (This.Name);
      if This.With_Abort then
         Put (Output, " with abort");
      end if;
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
   end Do_Put;

   procedure Do_Put (This : Selective_Accept; Prefix : String) is
      procedure Put (This : Select_Alternative; Suffix : String) is
      begin
         Put (Output, Prefix & "|__");
         if This.Guarded then
            Put (Output, "when ");
            Expression_IO.Put
            (  This.Guard.Item,
               Output,
               Prefix & Suffix & "     ",
               Inline
            );
            New_Line (Output);
            Put (Output, Prefix & Suffix);
         end if;
         case This.Mode is
            when Accept_Alternative =>
               Do_Put
               (  This.Accept_Statement.all,
                  Prefix & Suffix
               );
               if This.Code /= null then
                  Put_Line (Output,   Prefix & Suffix & "then");
                  Put (This.Code.all, Prefix & Suffix);
               end if;
            when Delay_Alternative =>
               Do_Put
               (  This.Delay_Statement.all,
                  Prefix & Suffix
               );
               if This.Code /= null then
                  Put_Line (Output,   Prefix & Suffix & "then");
                  Put (This.Code.all, Prefix & Suffix);
               end if;
            when Terminate_Alternative =>
               Put_Line (Output, "terminate");
         end case;
      end Put;
      List : Select_Alternative_Array renames This.Alternatives;
   begin
      Put_Labels (This.Labels, Prefix);
      Put_Line (Output, "select at " & Image (Tree.Location));
      for Index in List'First..List'Last - 1 loop
         Put (List (Index), "|  ");
      end loop;
      if This.Default = null then
         Put (List (List'Last), "   ");
      else
         Put (List (List'Last), "|  ");
         Put (Output, Prefix & "|__else");
         Put (This.Default.all, "   ");
      end if;
   end Do_Put;

   procedure Do_Put
             (  This   : Signed_Integer_Type_Declaration;
                Prefix : String
             )  is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (Output, Prefix);
      Put (Output, "   range ");
      Expression_IO.Put
      (  This.Constraint.Item,
          Output,
          Prefix & "         ",
          Inline
      );
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Single_Protected_Declaration;
                Prefix : String
             )  is
   begin
      Put (Output, "protected ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put_Interfaces (This.Interfaces, Prefix & "   ");
      if This.Public_Part /= null and then
         This.Public_Part.Declarations'Length > 0 then
         Put (This.Public_Part.all, Prefix);
      end if;
      if This.Private_Part /= null and then
         This.Private_Part.Declarations'Length > 0
      then
         Put_Line (Output, Prefix & "private");
         Put (This.Private_Part.all, Prefix);
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Single_Task_Declaration; Prefix : String) is
   begin
      Put (Output, "task ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put_Interfaces (This.Interfaces, Prefix & "   ");
      if This.Public_Part /= null and then
         This.Public_Part.Declarations'Length > 0 then
         Put (This.Public_Part.all, Prefix);
      end if;
      if This.Private_Part /= null and then
         This.Private_Part.Declarations'Length > 0
      then
         Put_Line (Output, Prefix & "private");
         Put (This.Private_Part.all, Prefix);
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put
             (  This   : Simple_Return_Statement;
                Prefix : String
             )  is
   begin
      Put_Labels (This.Labels, Prefix);
      Put (Output, "return at ");
      Put_Line (Output, Image (Tree.Location));
      if This.Has_Result then
         Expression_IO.Put
         (  This.Result.Item,
            Output,
            Prefix & "   ",
            Child
         );
      end if;
   end Do_Put;

   procedure Do_Put (This : Subtype_Declaration; Prefix : String) is
   begin
      Put (Output, "subtype ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Indication, Prefix & "   ", Top);
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Task_Body; Prefix : String) is
   begin
      if Is_Library_Unit (This.Declarations.Parent) then
         Put_Line (Output, "<library>");
         Put (This.Declarations.Parent, Prefix);
         Put (Output, Prefix);
      end if;
      Put (This.Parent, Prefix);
      Put (Output,"task body ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Declarations.all, Prefix);
      if This.Code /= null then
         Put_Line (Output, Prefix & "begin");
         Put (This.Code.all, Prefix);
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Task_Stub; Prefix : String) is
   begin
      Put (Output,"task body stub ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Task_Type_Declaration; Prefix : String) is
   begin
      Put (Output, "type ");
      Put (This.Name);
      Put (Output, " at ");
      Put_Line (Output, Image (Tree.Location));
      Put (This.Discriminants, Prefix & "   ", "discriminant");
      Put_Interfaces (This.Interfaces, Prefix & "   ");
      Put_Line (Output, Prefix & "   task");
      if This.Public_Part /= null and then
         This.Public_Part.Declarations'Length > 0
      then
         Put (This.Public_Part.all, Prefix & "   ");
      end if;
      if This.Private_Part /= null and then
         This.Private_Part.Declarations'Length > 0
      then
         Put_Line (Output, Prefix & "   private");
         Put (This.Private_Part.all, Prefix & "   ");
      end if;
      Put (This.Aspects, Prefix & "   ");
   end Do_Put;

   procedure Do_Put (This : Timed_Entry_Call; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      Put_Line (Output, "select at " & Image (Tree.Location));
      Put (Output,                 Prefix & "   ");
      Do_Put (This.Entry_Call.all, Prefix & "   ");
      if This.Accepted_Code /= null then
         Put_Line (Output, Prefix & "then");
         Put (This.Accepted_Code.all, Prefix);
      end if;
      Put (Output,            Prefix & "or ");
      Do_Put (This.Timer.all, Prefix & "   ");
      if This.Expired_Code /= null then
         Put_Line (Output, Prefix & "then");
         Put (This.Expired_Code.all, Prefix);
      end if;
   end Do_Put;

   procedure Do_Put (This : Use_Package_Clause; Prefix : String) is
   begin
      Put (Output, "use at ");
      Put_Line (Output, Image (Tree.Location));
      Put_Names (This.List, Prefix);
   end Do_Put;

   procedure Do_Put (This : Use_Type_Clause; Prefix : String) is
   begin
      Put (Output, "use ");
      if This.All_Type then
         Put (Output, "all ");
      end if;
      Put (Output, "type at ");
      Put_Line (Output, Image (Tree.Location));
      Put_Names (This.List, Prefix);
   end Do_Put;

   procedure Do_Put (This : Variant_Part; Prefix : String) is
   begin
      Put (Output, "case ");
      Expression_IO.Put
      (  This.Discriminant,
         Output,
         Prefix & "    ",
         Inline
      );
      declare
         List : Variant_Part_Item_Ptr_Array renames This.Alternatives;
      begin
         for Index in List'First..List'Last - 1 loop
            Put (List (Index).all, Prefix, "|  ");
         end loop;
         Put (List (List'Last).all, Prefix, "   ");
      end;
   end Do_Put;

   procedure Do_Put (This : While_Loop_Statement; Prefix : String) is
   begin
      Put_Labels (This.Labels, Prefix);
      if This.Named then
         Put_Name (This.Name.Item);
         Put_Line (Output, " : ");
         Put (Output, Prefix);
      end if;
      Put (Output, "while at ");
      Put_Line (Output, Image (Tree.Location));
      Expression_IO.Put
      (  This.Condition,
         Output,
         Prefix & "   ",
         Top
      );
      if This.Sequence /= null then
         Put_Line (Output, Prefix & "loop");
         Put (This.Sequence.all, Prefix);
      end if;
   end Do_Put;

   procedure Do_Put (This : With_Clause; Prefix : String) is
   begin
      Put (Output, "with at ");
      Put_Line (Output, Image (Tree.Location));
      Put_Names (This.List, Prefix);
   end Do_Put;

   Class : Program_Node_Class;
   This  : Node'Class renames Tree.Value.all;

begin
   if This not in Program_Node'Class then
      Expression_IO.Put
      (  Tree,
         Output,
         Prefix,
         Nested
      );
      return;
   end if;
   case Nested is
      when Top =>
         Put (Output, Prefix);
      when Child =>
         if Prefix'Length >= 3 then
            Put
            (  Output,
               Prefix (Prefix'First..Prefix'Last - 3) & "|__"
            );
         end if;
      when Inline =>
         null;
   end case;
   Class := Get_Class (Program_Node'Class (This));
   case Class is
      when Abort_Statement_Node =>
         Do_Put (Abort_Statement (This), Prefix);
      when Accept_Statement_Node =>
         Do_Put (Accept_Statement (This), Prefix);
      when Access_Type_Declaration_Node =>
         Do_Put (Access_Type_Declaration (This), Prefix);
      when Array_Type_Declaration_Node =>
         Do_Put (Array_Type_Declaration (This), Prefix);
      when Assignment_Statement_Node =>
         Do_Put (Assignment_Statement (This), Prefix);
      when Asynchronous_Transfer_Control_Node =>
         Do_Put (Asynchronous_Transfer_Control (This), Prefix);
      when At_Clause_Node =>
         Do_Put (At_Clause (This), Prefix);
      when Attribute_Definition_Clause_Node =>
         Do_Put (Attribute_Definition_Clause (This), Prefix);
      when Block_Statement_Node =>
         Do_Put (Block_Statement (This), Prefix);
      when Call_Statement_Node =>
         Do_Put (Call_Statement (This), Prefix);
      when Case_Statement_Node =>
         Do_Put (Case_Statement (This), Prefix);
      when Chunk_Specification_Node =>
         Put (Chunk_Specification (This), Prefix);
      when Conditional_Entry_Call_Node =>
         Do_Put (Conditional_Entry_Call (This), Prefix);
      when Decimal_Fixed_Point_Type_Declaration_Node =>
         Do_Put (Decimal_Fixed_Point_Type_Declaration (This), Prefix);
      when Declaration_Context_Node =>
         Put (Declaration_Context (This), Prefix);
      when Delay_Statement_Node =>
         Do_Put (Delay_Statement (This), Prefix);
      when Derived_Type_Declaration_Node =>
         Do_Put (Derived_Type_Declaration (This), Prefix);
      when Enumeration_Representation_Clause_Node =>
         Do_Put (Enumeration_Representation_Clause (This), Prefix);
      when Enumeration_Type_Declaration_Node =>
         Do_Put (Enumeration_Type_Declaration (This), Prefix);
      when Entry_Body_Node =>
         Do_Put (Entry_Body (This), Prefix);
      when Entry_Declaration_Node =>
         Do_Put (Entry_Declaration (This), Prefix);
      when Exception_Declaration_Node =>
         Do_Put (Exception_Declaration (This), Prefix);
      when Exception_Renaming_Node =>
         Do_Put (Exception_Renaming (This), Prefix);
      when Exception_Handler_Node =>
         Put (Exception_Handler (This), Prefix, Inline);
      when Exit_Statement_Node =>
         Do_Put (Exit_Statement (This), Prefix);
      when Extended_Return_Statement_Node =>
         Do_Put (Extended_Return_Statement (This), Prefix);
      when Floating_Point_Type_Declaration_Node =>
         Do_Put (Floating_Point_Type_Declaration (This), Prefix);
      when For_Loop_Statement_Node =>
         Do_Put (For_Loop_Statement (This), Prefix);
      when Formal_Access_Type_Parameter_Node =>
         Do_Put (Formal_Access_Type_Parameter (This), Prefix);
      when Formal_Array_Type_Parameter_Node =>
         Do_Put (Formal_Array_Type_Parameter (This), Prefix);
      when Formal_Derived_Type_Parameter_Node =>
         Do_Put (Formal_Derived_Type_Parameter (This), Prefix);
      when Formal_Function_Parameter_Node =>
         Do_Put (Formal_Function_Parameter (This), Prefix);
      when Formal_Incomplete_Type_Parameter_Node =>
         Do_Put (Formal_Incomplete_Type_Parameter (This), Prefix);
      when Formal_Interface_Type_Parameter_Node =>
         Do_Put (Formal_Interface_Type_Parameter (This), Prefix);
      when Formal_Package_Parameter_Node =>
         Do_Put (Formal_Package_Parameter (This), Prefix);
      when Formal_Private_Type_Parameter_Node =>
         Do_Put (Formal_Private_Type_Parameter (This), Prefix);
      when Formal_Procedure_Parameter_Node =>
         Do_Put (Formal_Procedure_Parameter (This), Prefix);
      when Formal_Scalar_Type_Parameter_Node =>
         Do_Put (Formal_Scalar_Type_Parameter (This), Prefix);
      when Function_Body_Node =>
         Do_Put (Function_Body (This), Prefix);
      when Function_Expression_Node =>
         Do_Put (Function_Expression (This), Prefix);
      when Function_Instantiation_Node =>
         Do_Put (Function_Instantiation (This), Prefix);
      when Function_Renaming_Node =>
         Do_Put (Function_Renaming (This), Prefix);
      when Function_Declaration_Node =>
         Do_Put (Function_Declaration (This), Prefix);
      when Function_Stub_Node =>
         Do_Put (Function_Stub (This), Prefix);
      when Goto_Statement_Node =>
         Do_Put (Goto_Statement (This), Prefix);
      when If_Statement_Node =>
         Do_Put (If_Statement (This), Prefix);
      when Incomplete_Type_Declaration_Node =>
         Do_Put (Incomplete_Type_Declaration (This), Prefix);
      when Identifier_List_Node =>
         Put (Identifier_List (This), Prefix);
      when Interface_Type_Declaration_Node =>
         Do_Put (Interface_Type_Declaration (This), Prefix);
      when Handled_Statement_Sequence_Node =>
         Put (Handled_Statement_Sequence (This), Prefix);
      when Loop_Statement_Node =>
         Do_Put (Loop_Statement (This), Prefix);
      when Modular_Type_Declaration_Node =>
         Do_Put (Modular_Type_Declaration (This), Prefix);
      when Null_Procedure_Node =>
         Do_Put (Null_Procedure (This), Prefix);
      when Null_Statement_Node =>
         Put_Labels (Null_Statement (This).Labels, Prefix);
         Put (Output, "null at ");
         Put_Line (Output, Image (Tree.Location));
      when Object_Declaration_Node =>
         Do_Put (Object_Declaration (This), Prefix);
      when Object_Renaming_Node =>
         Do_Put (Object_Renaming (This), Prefix);
      when Ordinary_Fixed_Point_Type_Declaration_Node =>
         Do_Put (Ordinary_Fixed_Point_Type_Declaration (This), Prefix);
      when Package_Body_Node =>
         Do_Put (Package_Body (This), Prefix);
      when Package_Renaming_Node =>
         Do_Put (Package_Renaming (This), Prefix);
      when Package_Declaration_Node =>
         Do_Put (Package_Declaration (This), Prefix);
      when Package_Instantiation_Node =>
         Do_Put (Package_Instantiation (This), Prefix);
      when Package_Stub_Node =>
         Do_Put (Package_Stub (This), Prefix);
      when Parallel_Block_Node =>
         Do_Put (Parallel_Block_Statement (This), Prefix);
      when Parameter_Profile_Node =>
         Put (Parameter_Profile (This), Prefix);
      when Parameter_Specification_Node =>
         Put (Parameter_Specification (This), Prefix, Inline);
      when Pragma_Clause_Node =>
         Do_Put (Pragma_Clause (This), Prefix);
      when Private_Type_Declaration_Node =>
         Do_Put (Private_Type_Declaration (This), Prefix);
      when Protected_Type_Declaration_Node =>
         Do_Put (Protected_Type_Declaration (This), Prefix);
      when Private_Extension_Type_Declaration_Node =>
         Do_Put (Private_Extension_Type_Declaration (This), Prefix);
      when Protected_Body_Node =>
         Do_Put (Protected_Body (This), Prefix);
      when Protected_Stub_Node =>
         Do_Put (Protected_Stub (This), Prefix);
      when Procedure_Body_Node =>
         Do_Put (Procedure_Body (This), Prefix);
      when Procedure_Declaration_Node =>
         Do_Put (Procedure_Declaration (This), Prefix);
      when Procedure_Instantiation_Node =>
         Do_Put (Procedure_Instantiation (This), Prefix);
      when Procedure_Renaming_Node =>
         Do_Put (Procedure_Renaming (This), Prefix);
      when Procedure_Stub_Node =>
         Do_Put (Procedure_Stub (This), Prefix);
      when Raise_Statement_Node =>
         Do_Put (Raise_Statement (This), Prefix);
      when Record_Representation_Clause_Node =>
         Do_Put (Record_Representation_Clause (This), Prefix);
      when Record_Type_Declaration_Node =>
         Do_Put (Record_Type_Declaration (This), Prefix);
      when Requeue_Statement_Node =>
         Do_Put (Requeue_Statement (This), Prefix);
      when Selective_Accept_Node =>
         Do_Put (Selective_Accept (This), Prefix);
      when Signed_Integer_Type_Declaration_Node =>
         Do_Put (Signed_Integer_Type_Declaration (This), Prefix);
      when Simple_Return_Statement_Node =>
         Do_Put (Simple_Return_Statement (This), Prefix);
      when Single_Protected_Declaration_Node =>
         Do_Put (Single_Protected_Declaration (This), Prefix);
      when Single_Task_Declaration_Node =>
         Do_Put (Single_Task_Declaration (This), Prefix);
      when Singleton_Parameter_Node =>
         Put (Singleton_Parameter (This), Prefix);
      when Statement_Sequence_Node =>
         Put (Statement_Sequence (This), Prefix);
      when Subtype_Declaration_Node =>
         Do_Put (Subtype_Declaration (This), Prefix);
      when Task_Body_Node =>
         Do_Put (Task_Body (This), Prefix);
      when Task_Stub_Node =>
         Do_Put (Task_Stub (This), Prefix);
      when Task_Type_Declaration_Node =>
         Do_Put (Task_Type_Declaration (This), Prefix);
      when Timed_Entry_Call_Node =>
         Do_Put (Timed_Entry_Call (This), Prefix);
      when Use_Package_Clause_Node =>
         Do_Put (Use_Package_Clause (This), Prefix);
      when Use_Type_Clause_Node =>
         Do_Put (Use_Type_Clause (This), Prefix);
      when Variant_Part_Node =>
         Do_Put (Variant_Part (This), Prefix);
      when Variant_Part_Item_Node =>
         Put (Variant_Part_Item (This), Prefix, "   ");
      when While_Loop_Statement_Node =>
         Do_Put (While_Loop_Statement (This), Prefix);
      when With_Clause_Node =>
         Do_Put (With_Clause (This), Prefix);
   end case;
end Put;
