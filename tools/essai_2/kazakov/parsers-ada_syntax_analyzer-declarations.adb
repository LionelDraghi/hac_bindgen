--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Declarations                             Spring, 2026       --
--  Implementation                                                    --
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

with Strings_Edit;  use Strings_Edit;

package body Parsers.Ada_Syntax_Analyzer.Declarations is

   function Equal_Use_Clause
            (  Left  : Use_Clause'Class;
               Right : Use_Clause'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if 0 = (Location_Independent and Mode) and then
         Left.Location /= Right.Location then
         return Inequal;
      end if;
      if (Left.Enclosing /= Left) then
         raise Constraint_Error;
      elsif Right.Enclosing /= Right then
         raise Constraint_Error;
      elsif not Equal (Left.List, Right.List, Mode) then
         return Inequal;
      elsif 0 /= (Mode and not Follow_Links) and then
            not Equal
               (  Left.Enclosing,
                  Right.Enclosing,
                  Mode and not Follow_Links
               )  then
         return Inequal;
      elsif (Left.Previous = null) /= (Right.Previous = null) then
         return Inequal;
      elsif Left.Previous /= null then
         if 0 /= (Mode and not Follow_Links) and then
            not Equal
               (  Left.Previous.all,
                  Right.Previous.all,
                  Mode and not Follow_Links
               )  then
            return Inequal;
         end if;
      end if;
      return True;
   end Equal_Use_Clause;

   function Equal
            (  Left  : Declaration_Context;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Declaration_Context then
         return Inequal;
      else
         declare
            use Strings_Edit.Lexicographical_Order;
            Other : Declaration_Context renames
                    Declaration_Context (Right);
         begin
            if Left.Kind_Of /= Other.Kind_Of then
               return Inequal;
            elsif not Equal
                      (  Left.Parent,
                         Other.Parent,
                         Mode and not Follow_Links
                      )  then
               return Inequal;
            elsif (  (Left.Last_Use_Clause  = null)
                  /= (Other.Last_Use_Clause = null)
                  )  then
               return Inequal;
            elsif (  (Left.Last_Use_Clause  = null)
                  /= (Other.Last_Use_Clause = null)
                  )  then
               return Inequal;
            elsif 0 = (Location_Independent and Mode) then
               if Left.Location /= Other.Location then
                  return Inequal;
               elsif Left.Scope /= Other.Scope then
                  return Inequal;
               elsif 0 = (Source_Independent and Mode) then
                  if Compare (Left.File, Other.File) /= Equal then
                     return Inequal;
                  end if;
               end if;
            end if;
            if Left.Declarations /= null then
               for Index in Left.Declarations'Range loop
                  if not Equal
                         (  Left.Declarations (Index).all,
                            Other.Declarations
                            (  Index
                            -  Left.Declarations'First
                            +  Other.Declarations'First
                            ) .all,
                            Mode
                         )
                  then
                     return Inequal;
                  end if;
               end loop;
            end if;
            if 0 /= (Follow_Links and Mode) then
               if Left.Last_Use_Clause /= null and then
                  not Equal
                      (  Left.Last_Use_Clause.all,
                         Other.Last_Use_Clause.all,
                         Mode and not Follow_Links
                      )  then
                  return Inequal;
               end if;
            end if;
            return True;
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Declaration_Context_Ptr;
               Right : Declaration_Context_Ptr;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if (Left = null) /= (Right = null) then
         return Inequal;
      end if;
      return Left = null or else Equal (Left.all, Right.all, Mode);
   end Equal;

   function Equal
            (  Left  : Optional;
               Right : Optional;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Left.Present /= Right.Present then
         return Inequal;
      end if;
      return not Left.Present or else
             Equal (Left.Item, Right.Item, Mode);
   end Equal;

   function Equal
            (  Left  : Parent_Unit;
               Right : Parent_Unit;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Left.Separate_Body /= Right.Separate_Body then
         return Inequal;
      end if;
      return not Left.Separate_Body or else
             Equal (Left.Parent, Right.Parent, Mode);
   end Equal;

   function Equal
            (  Left  : Pragma_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
      function Equal (Left, Right : Pragma_Argument_Association)
         return Boolean is
      begin
         if Left.Named /= Right.Named then
            return Inequal;
         elsif Left.Named and then
               not Equal
                   (  Left.Argument.Item,
                      Right.Argument.Item,
                      Mode
                   )  then
            return Inequal;
         end if;
         return Equal (Left.Value, Right.Value, Mode);
      end Equal;
   begin
      if Right not in Pragma_Clause then
         return Inequal;
      else
         declare
            Other : Pragma_Clause renames Pragma_Clause (Right);
         begin
            if Left.Count /= Other.Count then
               return Inequal;
            end if;
            for Index in Left.Associations'Range loop
               if not Equal
                      (  Left.Associations (Index),
                         Other.Associations (Index)
                      )  then
                  return Inequal;
               end if;
            end loop;
            if 0 = (Location_Independent and Mode) and then
               Left.Location /= Other.Location then
               return Inequal;
            end if;
            return Equal (Left.Name, Other.Name, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Subtype_Mark_Array;
               Right : Subtype_Mark_Array;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Left'Length /= Right'Length then
         return Inequal;
      else
         for Index in Left'Range loop
            if not Equal
                   (  Left (Index),
                      Right (Index - Left'First + Right'First),
                      Mode
                   )  then
               return Inequal;
            end if;
         end loop;
         return True;
      end if;
   end Equal;

   function Equal
            (  Left  : Use_Package_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Use_Package_Clause then
         return Inequal;
      else
         declare
            Other : Use_Package_Clause renames
                    Use_Package_Clause (Right);
         begin
            return Equal_Use_Clause (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Use_Type_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Use_Type_Clause then
         return Inequal;
      else
         declare
            Other : Use_Type_Clause renames
                    Use_Type_Clause (Right);
         begin
            if Left.All_Type /= Other.All_Type then
               return Inequal;
            end if;
            return Equal_Use_Clause (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : With_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in With_Clause then
         return Inequal;
      else
         declare
            Other : With_Clause renames With_Clause (Right);
         begin
            if Left.Limited_With /= Other.Limited_With then
               return Inequal;
            elsif Left.Private_With /= Other.Private_With then
               return Inequal;
            elsif 0 = (Location_Independent and Mode) and then
                  Left.Location /= Other.Location then
               return Inequal;
            end if;
            return Equal (Left.List, Other.List, Mode);
         end;
      end if;
   end Equal;

   function Get_Class (Item : Declaration_Context)
      return Program_Node_Class is
   begin
      return Declaration_Context_Node;
   end Get_Class;

   function Get_Class (Item : Pragma_Clause)
      return Program_Node_Class is
   begin
      return Pragma_Clause_Node;
   end Get_Class;

   function Get_Class (Item : Use_Package_Clause)
      return Program_Node_Class is
   begin
      return Use_Package_Clause_Node;
   end Get_Class;

   function Get_Class (Item : Use_Type_Clause)
      return Program_Node_Class is
   begin
      return Use_Type_Clause_Node;
   end Get_Class;

   function Get_Class (Item : With_Clause) return Program_Node_Class is
   begin
      return With_Clause_Node;
   end Get_Class;

   function Image (Item : Compilation_Context_Type) return String is
   begin
      case Item is
         when Code_Block_Context =>
            return "declarative part";
         when Generic_Formal_Parameters_Context =>
            return "generic formal parameters declaration";
         when Library_Unit_Context =>
            return "library unit context";
         when Package_Interface_Context =>
            return "package declarative items context";
         when Package_Private_Context =>
            return "package private declarative items context";
         when Task_Interface_Context =>
            return "task public items context";
         when Task_Private_Context =>
            return "task private items context";
         when Protected_Interface_Context =>
            return "protected operation declarations context";
         when Protected_Body_Context =>
            return "protected body context";
         when Protected_Private_Context =>
            return "protected element declarations context";
         when Record_Component_Context =>
            return "record component item context";
      end case;
   end Image;

   function Is_Library_Unit (Item : Declaration_Context)
      return Boolean is
   begin
      return
      (  Item.Kind_Of = Library_Unit_Context
      or else
         (  Item.Kind_Of = Generic_Formal_Parameters_Context
         and then
            Is_Library_Unit (Item.Parent)
      )  );
   end Is_Library_Unit;

   function Get_Item
            (  Context : Declaration_Context;
               Index   : Positive
            )  return Declaration_Ptr is
   begin
      return Context.Declarations (Index);
   end Get_Item;

   function Get_Items_Number (Context : Declaration_Context)
      return Natural is
   begin
      if Context.Declarations = null then
         return 0;
      else
         return Context.Declarations'Length;
      end if;
   end Get_Items_Number;

   function Image
            (  Item   : General_Access_Modifier_Type;
               Suffix : String := " "
            )  return String is
   begin
      case Item is
         when All_Access_Modifier =>
            return "all" & Suffix;
         when Constant_Access_Modifier =>
            return "constant" & Suffix;
         when No_Access_Modifier =>
            return "";
      end case;
   end Image;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Declaration_Context
             )  is
   begin
      if Item.Declarations = null then
         return;
      end if;
      declare
         List  : Declaration_Ptr_Array renames Item.Declarations.all;
         Index : Integer := Pointer;
      begin
         if Item.Declarations'Length = 0 then
            if Item.Kind_Of = Record_Component_Context then
               Put (Destination, Index, "null; ");
            end if;
         else
            for Item in List'Range loop
               Put (Destination, Index, List (Item).all);
               Put (Destination, Index, " ");
            end loop;
         end if;
         Pointer := Index;
      end;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Prefix      : String;
                Item        : Optional;
                Suffix      : String
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Present then
         Put (Destination, Index, Prefix);
         Put (Destination, Index, Item.Item);
         Put (Destination, Index, Suffix);
         Pointer := Index;
      end if;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Parent_Unit
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Separate_Body then
         Put (Destination, Index, "separate (");
         Put (Destination, Index, Item.Parent);
         Put (Destination, Index, ") ");
      end if;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Pragma_Clause
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "pragma ");
      Put (Destination, Index, Item.Name);
      if Item.Count > 0 then
         Put (Destination, Index, " (");
         for Element in Item.Associations'Range loop
            if Element > Item.Associations'First then
               Put (Destination, Index, ", ");
            end if;
            declare
               This : Pragma_Argument_Association renames
                      Item.Associations (Element);
            begin
               if This.Named then
                  Put (Destination, Index, This.Argument.Item);
                  Put (Destination, Index, " => ");
                  Put (Destination, Index, This.Value);
               else
                  Put (Destination, Index, This.Value);
               end if;
            end;
         end loop;
         Put (Destination, Index, ")");
      end if;
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Subtype_Mark_Array;
                Prefix      : String;
                Delimiter   : String;
                Suffix      : String
             )  is
      Index : Integer := Pointer;
   begin
      if List'Length = 0 then
         return;
      else
         Put (Destination, Index, Prefix);
         for Item in List'Range loop
            if Item > List'First then
               Put (Destination, Index, Delimiter);
            end if;
            Put (Destination, Index, List (Item));
         end loop;
         Put (Destination, Index, Suffix);
         Pointer := Index;
      end if;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Use_Package_Clause
             )  is
   begin
      Put (Destination, Pointer, Item.List, "use ", ", ", ";");
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Use_Type_Clause
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "use ");
      if Item.All_Type then
         Put (Destination, Index, "all ");
      end if;
      Put (Destination, Index, Item.List, "type ", ", ", ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : With_Clause
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Limited_With then
         Put (Destination, Index, "limited ");
      end if;
      if Item.Private_With then
         Put (Destination, Index, "private ");
      end if;
      Put (Destination, Index, Item.List, "with ", ", ", ";");
      Pointer := Index;
   end Put;

end Parsers.Ada_Syntax_Analyzer.Declarations;
