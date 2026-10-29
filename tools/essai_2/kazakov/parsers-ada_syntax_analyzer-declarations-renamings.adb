--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Declarations.Renamings                   Spring, 2026       --
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

package body Parsers.Ada_Syntax_Analyzer.Declarations.Renamings is

   function Equal
            (  Left  : Exception_Renaming;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Exception_Renaming then
         return Inequal;
      else
         declare
            Other : Exception_Renaming renames
                    Exception_Renaming (Right);
         begin
            if not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Target, Other.Target, Mode) then
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
            (  Left  : Function_Renaming;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Function_Renaming then
         return Inequal;
      else
         declare
            Other : Function_Renaming renames
                    Function_Renaming (Right);
         begin
            if not Equal (Left.Result.all, Other.Result.all, Mode) then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Target, Other.Target, Mode) then
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
            (  Left  : Object_Renaming;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Object_Renaming then
         return Inequal;
      else
         declare
            Other : Object_Renaming renames
                    Object_Renaming (Right);
         begin
            if not Equal (Left.Type_Of, Other.Type_Of, Mode) then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Target, Other.Target, Mode) then
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
            (  Left  : Package_Renaming;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Package_Renaming then
         return Inequal;
      else
         declare
            Other : Package_Renaming renames
                    Package_Renaming (Right);
         begin
            if not Equal
                   (  Left.Parent,
                      Other.Parent,
                      Mode and not Follow_Links
                   )  then
               return Inequal;
            elsif not Equal (Left.Full_Name, Other.Full_Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Target, Other.Target, Mode) then
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
            (  Left  : Procedure_Renaming;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Procedure_Renaming then
         return Inequal;
      else
         declare
            Other : Procedure_Renaming renames
                    Procedure_Renaming (Right);
         begin
            if not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Target, Other.Target, Mode) then
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

   function Get_Class (Item : Exception_Renaming)
      return Program_Node_Class is
   begin
      return Exception_Renaming_Node;
   end Get_Class;

   function Get_Class (Item : Function_Renaming)
      return Program_Node_Class is
   begin
      return Function_Renaming_Node;
   end Get_Class;

   function Get_Class (Item : Object_Renaming)
      return Program_Node_Class is
   begin
      return Object_Renaming_Node;
   end Get_Class;

   function Get_Class (Item : Package_Renaming)
      return Program_Node_Class is
   begin
      return Package_Renaming_Node;
   end Get_Class;

   function Get_Class (Item : Procedure_Renaming)
      return Program_Node_Class is
   begin
      return Procedure_Renaming_Node;
   end Get_Class;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Exception_Renaming
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " : exception renames ");
      Put (Destination, Index, Item.Target);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Function_Renaming
             )  is
      Index : Integer := Pointer;
   begin
      if Is_Library_Unit (Item.Parent) then
         Put (Destination, Index, Item.Parent);
      end if;
      if Item.Generic_Unit then
         Put (Destination, Index, "generic ");
      end if;
      if Item.Private_Unit then
         Put (Destination, Index,"private ");
      end if;
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "function ");
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, Item.Profile);
      Put (Destination, Index, " return ");
      Put (Destination, Index, Item.Result.all);
      Put (Destination, Index, " renames ");
      Put (Destination, Index, Item.Target);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Object_Renaming
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Type_Of);
      Put (Destination, Index, " renames ");
      Put (Destination, Index, Item.Target);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Package_Renaming
              )  is
      Index : Integer := Pointer;
   begin
      if Is_Library_Unit (Item.Parent) then
         Put (Destination, Index, Item.Parent);
      end if;
      if Item.Generic_Unit then
         Put (Destination, Index, "generic ");
      end if;
      Put (Destination, Index, "package ");
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, " renames ");
      Put (Destination, Index, Item.Target);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Procedure_Renaming
             )  is
      Index : Integer := Pointer;
   begin
      if Is_Library_Unit (Item.Parent) then
         Put (Destination, Index, Item.Parent);
      end if;
      if Item.Generic_Unit then
         Put (Destination, Index, "generic ");
      end if;
      if Item.Private_Unit then
         Put (Destination, Index, "private ");
      end if;
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "procedure ");
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, Item.Profile);
      Put (Destination, Index, " renames ");
      Put (Destination, Index, Item.Target);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

end Parsers.Ada_Syntax_Analyzer.Declarations.Renamings;
