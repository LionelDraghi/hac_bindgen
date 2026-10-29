--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Bodies                                   Spring, 2026       --
--  Implementation                                                         --
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

package body Parsers.Ada_Syntax_Analyzer.Bodies is

   function Equal_Abstract_Body
            (  Left  : Abstract_Body'Class;
               Right : Abstract_Body'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if not Equal
             (  Left.Declarations.all,
                Right.Declarations.all,
                Mode
             )  then
         return Inequal;
      elsif not Equal (Left.Name, Right.Name, Mode) then
         return Inequal;
      elsif not Equal (Left.Aspects, Right.Aspects, Mode) then
         return Inequal;
      elsif 0 = (Location_Independent and Mode) then
         if Left.Location /= Right.Location then
            return Inequal;
         end if;
      end if;
      return True;
   end Equal_Abstract_Body;

   function Equal_Executable_Body
            (  Left  : Executable_Body'Class;
               Right : Executable_Body'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Left.Overrides /= Right.Overrides then
         return Inequal;
      elsif not Equal (Left.Code.all, Right.Code.all, Mode) then
         return Inequal;
      end if;
      return Equal_Abstract_Body (Left, Right, Mode);
   end Equal_Executable_Body;

   function Equal_Subroutine_Body
            (  Left  : Subroutine_Body'Class;
               Right : Subroutine_Body'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Left.Overrides /= Right.Overrides then
         return Inequal;
      elsif not Equal (Left.Parent, Right.Parent, Mode) then
         return Inequal;
      elsif not Equal (Left.Full_Name, Right.Full_Name, Mode) then
         return Inequal;
      elsif not Equal_Abstract_Body (Left, Right, Mode) then
         return Inequal;
      end if;
      return True;
   end Equal_Subroutine_Body;

   function Equal
            (  Left  : Entry_Body;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Entry_Body then
         return Inequal;
      else
         declare
            Other : Entry_Body renames Entry_Body (Right);
         begin
            if Left.Has_Index /= Other.Has_Index then
               return Inequal;
            elsif Left.Has_Index and then
                  not Equal (Left.Index, Other.Index, Mode) then
               return Inequal;
            elsif not Equal (Left.Profile, Other.Profile, Mode) then
               return Inequal;
            elsif not Equal (Left.Barrier, Other.Barrier, Mode) then
               return Inequal;
            elsif not Equal_Executable_Body (Left, Other, Mode) then
               return Inequal;
            end if;
            return True;
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Function_Expression;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Function_Expression then
         return Inequal;
      else
         declare
            Other : Function_Expression renames
                    Function_Expression (Right);
         begin
            if Left.Overrides /= Other.Overrides then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Result.all,
                         Other.Result.all,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Expression,
                         Other.Expression,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal (Left.Profile, Other.Profile, Mode) then
               return Inequal;
            elsif not Equal (Left.Aspects, Other.Aspects, Mode) then
               return Inequal;
            elsif 0 = (Location_Independent and Mode) then
               if Left.Location /= Other.Location then
                  return Inequal;
               end if;
            end if;
            return True;
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Function_Body;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Function_Body then
         return Inequal;
      else
         declare
            Other : Function_Body renames Function_Body (Right);
         begin
            if not Equal (Left.Result.all, Other.Result.all, Mode) then
               return Inequal;
            elsif not Equal_Subroutine_Body (Left, Other, Mode) then
               return Inequal;
            end if;
            return True;
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Null_Procedure;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Null_Procedure then
         return Inequal;
      else
         declare
            Other : Null_Procedure renames
                    Null_Procedure (Right);
         begin
            if Left.Private_Unit /= Other.Private_Unit then
               return Inequal;
            elsif Left.Generic_Unit /= Other.Generic_Unit then
               return Inequal;
            elsif Left.Abstract_Subprogram /=
                  Other.Abstract_Subprogram then
               return Inequal;
            elsif Left.Overrides /= Other.Overrides then
               return Inequal;
            elsif not Equal (Left.Profile, Other.Profile, Mode) then
               return Inequal;
            elsif not Equal (Left.Full_Name, Other.Full_Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Aspects, Other.Aspects, Mode) then
               return Inequal;
            elsif 0 = (Location_Independent and Mode) then
               if Left.Location /= Other.Location then
                  return Inequal;
               end if;
            end if;
            return True;
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Package_Body;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Package_Body then
         return Inequal;
      else
         declare
            Other : Package_Body renames Package_Body (Right);
         begin
            if not Equal (Left.Full_Name, Other.Full_Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Parent, Other.Parent, Mode) then
               return Inequal;
            elsif not Equal (Left.Code, Other.Code, Mode) then
               return Inequal;
            elsif not Equal_Abstract_Body (Left, Other, Mode) then
               return Inequal;
            end if;
            return True;
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Procedure_Body;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Procedure_Body then
         return Inequal;
      else
         declare
            Other : Procedure_Body renames Procedure_Body (Right);
         begin
            return Equal_Subroutine_Body (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Protected_Body;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Protected_Body then
         return Inequal;
      else
         declare
            Other : Protected_Body renames Protected_Body (Right);
         begin
            return
            (  Equal (Left.Parent, Other.Parent, Mode)
            and then
               Equal_Abstract_Body (Left, Other, Mode)
            );
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Task_Body;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Task_Body then
         return Inequal;
      else
         declare
            Other : Task_Body renames Task_Body (Right);
         begin
            return
            (  Equal (Left.Parent, Other.Parent, Mode)
            and then
               Equal_Executable_Body (Left, Other, Mode)
            );
         end;
      end if;
   end Equal;


   function Get_Class (Item : Entry_Body)
      return Program_Node_Class is
   begin
      return Entry_Body_Node;
   end Get_Class;

   function Get_Class (Item : Function_Expression)
      return Program_Node_Class is
   begin
      return Function_Expression_Node;
   end Get_Class;

   function Get_Class (Item : Function_Body)
      return Program_Node_Class is
   begin
      return Function_Body_Node;
   end Get_Class;

   function Get_Class (Item : Null_Procedure)
      return Program_Node_Class is
   begin
      return Null_Procedure_Node;
   end Get_Class;

   function Get_Class (Item : Package_Body) return Program_Node_Class is
   begin
      return Package_Body_Node;
   end Get_Class;

   function Get_Class (Item : Procedure_Body)
      return Program_Node_Class is
   begin
      return Procedure_Body_Node;
   end Get_Class;

   function Get_Class (Item : Protected_Body)
      return Program_Node_Class is
   begin
      return Protected_Body_Node;
   end Get_Class;

   function Get_Class (Item : Task_Body) return Program_Node_Class is
   begin
      return Task_Body_Node;
   end Get_Class;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Entry_Body
             )  is
      Index : Integer := Pointer;
   begin
      if Is_Library_Unit (Item.Declarations.Parent) then
         Put (Destination, Index, Item.Declarations.Parent);
      end if;
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "entry ");
      Put (Destination, Index, Item.Name);
      if Item.Index.Present then
         Put (Destination, Index, " (for ");
         Put (Destination, Index, Item.Index.Item);
         Put (Destination, Index, ")");
      end if;
      Put (Destination, Index, Item.Profile);
      Put (Destination, Index, " when ");
      Put (Destination, Index, Item.Barrier);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Declarations.all);
      Put (Destination, Index, "begin ");
      Put (Destination, Index, Item.Code.all);
      Put (Destination, Index, "end ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Function_Expression
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "function ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Profile);
      Put (Destination, Index, " return ");
      Put (Destination, Index, Item.Result.all);
      Put (Destination, Index, " is (");
      Put (Destination, Index, Item.Expression);
      Put (Destination, Index, ")");
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Function_Body
             )  is
      Index : Integer := Pointer;
   begin
      if Is_Library_Unit (Item.Declarations.Parent) then
         Put (Destination, Index, Item.Declarations.Parent);
      end if;
      Put (Destination, Index, Item.Parent);
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "function ");
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, Item.Profile);
      Put (Destination, Index, " return ");
      Put (Destination, Index, Item.Result.all);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Declarations.all);
      Put (Destination, Index, "begin ");
      Put (Destination, Index, Item.Code.all);
      Put (Destination, Index, "end ");
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Null_Procedure
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Private_Unit then
         Put (Destination, Index, "private ");
      end if;
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "procedure ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Profile);
      Put (Destination, Index, " is null");
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Package_Body
             )  is
      Index : Integer := Pointer;
   begin
      if Is_Library_Unit (Item.Declarations.Parent) then
         Put (Destination, Index, Item.Declarations.Parent);
      end if;
      Put (Destination, Index, Item.Parent);
      Put (Destination, Index, "package body ");
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Declarations.all);
      if Item.Code /= null then
         Put (Destination, Index, "begin ");
         Put (Destination, Index, Item.Code.all);
      end if;
      Put (Destination, Index, "end ");
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Procedure_Body
             )  is
      Index : Integer := Pointer;
   begin
      if Is_Library_Unit (Item.Declarations.Parent) then
         Put (Destination, Index, Item.Declarations.Parent);
      end if;
      Put (Destination, Index, Item.Parent);
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "procedure ");
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, Item.Profile);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Declarations.all);
      Put (Destination, Index, "begin ");
      Put (Destination, Index, Item.Code.all);
      Put (Destination, Index, "end ");
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Protected_Body
             )  is
      Index : Integer := Pointer;
   begin
      if Is_Library_Unit (Item.Declarations.Parent) then
         Put (Destination, Index, Item.Declarations.Parent);
      end if;
      Put (Destination, Index, Item.Parent);
      Put (Destination, Index, "protected body ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Declarations.all);
      Put (Destination, Index, "end ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Task_Body
             )  is
      Index : Integer := Pointer;
   begin
      if Is_Library_Unit (Item.Declarations.Parent) then
         Put (Destination, Index, Item.Declarations.Parent);
      end if;
      Put (Destination, Index, Item.Parent);
      Put (Destination, Index, "task body ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Declarations.all);
      Put (Destination, Index, "begin ");
      Put (Destination, Index, Item.Code.all);
      Put (Destination, Index, "end ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

end Parsers.Ada_Syntax_Analyzer.Bodies;
