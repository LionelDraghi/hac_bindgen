--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Declarations.Stubs                       Spring, 2026       --
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

package body Parsers.Ada_Syntax_Analyzer.Declarations.Stubs is

   function Equal
            (  Left  : Function_Stub;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Function_Stub then
         return Inequal;
      else
         declare
            Other : Function_Stub renames Function_Stub (Right);
         begin
            if Left.Overrides /= Other.Overrides then
               return Inequal;
            elsif not Equal (Left.Profile, Other.Profile, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Result.all,
                         Other.Result.all,
                         Mode
                      )  then
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
            (  Left  : Package_Stub;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Package_Stub then
         return Inequal;
      else
         declare
            Other : Package_Stub renames Package_Stub (Right);
         begin
            if not Equal (Left.Name, Other.Name, Mode) then
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
            (  Left  : Procedure_Stub;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Procedure_Stub then
         return Inequal;
      else
         declare
            Other : Procedure_Stub renames Procedure_Stub (Right);
         begin
            if Left.Overrides /= Other.Overrides then
               return Inequal;
            elsif not Equal (Left.Profile, Other.Profile, Mode) then
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
            (  Left  : Protected_Stub;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Protected_Stub then
         return Inequal;
      else
         declare
            Other : Protected_Stub renames Protected_Stub (Right);
         begin
            if not Equal (Left.Name, Other.Name, Mode) then
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
            (  Left  : Task_Stub;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Task_Stub then
         return Inequal;
      else
         declare
            Other : Task_Stub renames Task_Stub (Right);
         begin
            if not Equal (Left.Name, Other.Name, Mode) then
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

   function Get_Class (Item : Function_Stub) return Program_Node_Class is
   begin
      return Function_Stub_Node;
   end Get_Class;

   function Get_Class (Item : Package_Stub) return Program_Node_Class is
   begin
      return Package_Stub_Node;
   end Get_Class;

   function Get_Class (Item : Procedure_Stub)
      return Program_Node_Class is
   begin
      return Procedure_Stub_Node;
   end Get_Class;

   function Get_Class (Item : Protected_Stub)
      return Program_Node_Class is
   begin
      return Task_Stub_Node;
   end Get_Class;

   function Get_Class (Item : Task_Stub) return Program_Node_Class is
   begin
      return Task_Stub_Node;
   end Get_Class;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Function_Stub
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "function ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Profile);
      Put (Destination, Index, " return ");
      Put (Destination, Index, Item.Result.all);
      Put (Destination, Index, " is separate");
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Package_Stub
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "package ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is separate");
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Procedure_Stub
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "procedure ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Profile);
      Put (Destination, Index, " is separate");
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Protected_Stub
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "protected body ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is separate");
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Task_Stub
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "task body ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is separate");
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

end Parsers.Ada_Syntax_Analyzer.Declarations.Stubs;
