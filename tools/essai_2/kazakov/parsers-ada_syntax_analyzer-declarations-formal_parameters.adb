--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Declarations.Formal_Parameters           Spring, 2026       --
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

package body Parsers.Ada_Syntax_Analyzer.Declarations.
             Formal_Parameters is

   function Equal
            (  Left  : Formal_Access_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Formal_Access_Type_Parameter then
         return Inequal;
      else
         declare
            Other : Formal_Access_Type_Parameter renames
                    Formal_Access_Type_Parameter (Right);
         begin
            if Left.Mode /= Other.Mode then
               return Inequal;
            elsif Left.Not_Null /= Other.Not_Null then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Pointer, Other.Pointer, Mode) then
               return Inequal;
            elsif not Equal (Left.Default, Other.Default, Mode) then
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
            (  Left  : Formal_Array_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Formal_Array_Type_Parameter then
         return Inequal;
      else
         declare
            Other : Formal_Array_Type_Parameter renames
                    Formal_Array_Type_Parameter (Right);
         begin
            if not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Definition.all,
                         Other.Definition.all,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal (Left.Default, Other.Default, Mode) then
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
            (  Left  : Formal_Derived_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Formal_Derived_Type_Parameter then
         return Inequal;
      else
         declare
            Other : Formal_Derived_Type_Parameter renames
                    Formal_Derived_Type_Parameter (Right);
         begin
            if Left.Abstract_Type /= Other.Abstract_Type then
               return Inequal;
            elsif Left.With_Private /= Other.With_Private then
               return Inequal;
            elsif Left.Mode /= Other.Mode then
               return Inequal;
            elsif not Equal
                      (  Left.Parent_Type,
                         Other.Parent_Type,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Discriminants,
                         Other.Discriminants,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Interfaces,
                         Other.Interfaces,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Default,
                         Other.Default,
                         Mode
                      )  then
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
            (  Left  : Formal_Function_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Formal_Function_Parameter then
         return Inequal;
      else
         declare
            Other : Formal_Function_Parameter renames
                    Formal_Function_Parameter (Right);
         begin
            if Left.Abstract_Subprogram /=
               Other.Abstract_Subprogram then
               return Inequal;
            elsif Left.Default /= Other.Default then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
              return Inequal;
            elsif not Equal (Left.Profile, Other.Profile, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Result.all,
                         Other.Result.all,
                         Mode
                      )  then
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
            (  Left  : Formal_Incomplete_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Formal_Incomplete_Type_Parameter then
         return Inequal;
      else
         declare
            Other : Formal_Incomplete_Type_Parameter renames
                    Formal_Incomplete_Type_Parameter (Right);
         begin
            if Left.Tagged_Type /= Other.Tagged_Type then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Discriminants,
                         Other.Discriminants,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal (Left.Default, Other.Default, Mode) then
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
            (  Left  : Formal_Interface_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Formal_Interface_Type_Parameter then
         return Inequal;
      else
         declare
            Other : Formal_Interface_Type_Parameter renames
                    Formal_Interface_Type_Parameter (Right);
         begin
            if Left.Mode /= Other.Mode then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Discriminants,
                         Other.Discriminants,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Interfaces,
                         Other.Interfaces,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal (Left.Default, Other.Default, Mode) then
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
            (  Left  : Formal_Package_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Formal_Package_Parameter then
         return Inequal;
      else
         declare
            Other : Formal_Package_Parameter renames
                    Formal_Package_Parameter (Right);
         begin
            if not Equal (Left.Target, Other.Target, Mode) then
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
            (  Left  : Formal_Private_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Formal_Private_Type_Parameter then
         return Inequal;
      else
         declare
            Other : Formal_Private_Type_Parameter renames
                    Formal_Private_Type_Parameter (Right);
         begin
            if Left.Abstract_Type /= Other.Abstract_Type then
               return Inequal;
            elsif Left.Limited_Type /= Other.Limited_Type then
               return Inequal;
            elsif Left.Tagged_Type /= Other.Tagged_Type then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Default, Other.Default, Mode) then
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
            (  Left  : Formal_Procedure_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Formal_Procedure_Parameter then
         return Inequal;
      else
         declare
            Other : Formal_Procedure_Parameter renames
                    Formal_Procedure_Parameter (Right);
         begin
            if Left.Abstract_Subprogram /=
               Other.Abstract_Subprogram  then
               return Inequal;
            elsif Left.Default /= Other.Default then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
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
            (  Left  : Formal_Scalar_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Formal_Scalar_Type_Parameter then
         return Inequal;
      else
         declare
            Other : Formal_Scalar_Type_Parameter renames
                    Formal_Scalar_Type_Parameter (Right);
         begin
            if Left.Kind_Of /= Other.Kind_Of then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Default, Other.Default, Mode) then
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
            (  Left  : Formal_Type_Default;
               Right : Formal_Type_Default;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Left.Defaulted /= Right.Defaulted then
         return Inequal;
      elsif Left.Defaulted then
         if not Equal (Left.Default, Right.Default, Mode) then
            return Inequal;
         end if;
      end if;
      return True;
   end Equal;

   function Get_Class (Item : Formal_Access_Type_Parameter)
      return Program_Node_Class is
   begin
      return Formal_Access_Type_Parameter_Node;
   end Get_Class;

   function Get_Class (Item : Formal_Array_Type_Parameter)
      return Program_Node_Class is
   begin
      return Formal_Array_Type_Parameter_Node;
   end Get_Class;

   function Get_Class (Item : Formal_Derived_Type_Parameter)
      return Program_Node_Class is
   begin
      return Formal_Derived_Type_Parameter_Node;
   end Get_Class;

   function Get_Class (Item : Formal_Function_Parameter)
      return Program_Node_Class is
   begin
      return Formal_Function_Parameter_Node;
   end Get_Class;

   function Get_Class (Item : Formal_Incomplete_Type_Parameter)
      return Program_Node_Class is
   begin
      return Formal_Incomplete_Type_Parameter_Node;
   end Get_Class;

   function Get_Class (Item : Formal_Interface_Type_Parameter)
      return Program_Node_Class is
   begin
      return Formal_Interface_Type_Parameter_Node;
   end Get_Class;

   function Get_Class (Item : Formal_Package_Parameter)
      return Program_Node_Class is
   begin
      return Formal_Package_Parameter_Node;
   end Get_Class;

   function Get_Class (Item : Formal_Private_Type_Parameter)
      return Program_Node_Class is
   begin
      return Formal_Private_Type_Parameter_Node;
   end Get_Class;

   function Get_Class (Item : Formal_Procedure_Parameter)
      return Program_Node_Class is
   begin
      return Formal_Procedure_Parameter_Node;
   end Get_Class;

   function Get_Class (Item : Formal_Scalar_Type_Parameter)
      return Program_Node_Class is
   begin
      return Formal_Scalar_Type_Parameter_Node;
   end Get_Class;

   procedure Put_Subprogram
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Subprogram_Parameter'Class
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Abstract_Subprogram then
         Put (Destination, Index, " is abstract");
      end if;
      case Item.Default is
         when No_Default =>
            null;
         when Name_Default =>
            if not Item.Abstract_Subprogram then
               Put (Destination, Index, " is");
            end if;
            Put (Destination, Index, " ");
            Put (Destination, Index, Item.Default_Name);
         when Null_Default =>
            if not Item.Abstract_Subprogram then
               Put (Destination, Index, " is");
            end if;
            Put (Destination, Index, " null");
         when Box_Default =>
            if not Item.Abstract_Subprogram then
               Put (Destination, Index, " is");
            end if;
            Put (Destination, Index, " <>");
      end case;
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put_Subprogram;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Type_Default;
                Prefix      : String := ""
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Defaulted then
         Put (Destination, Index, Prefix);
         Put (Destination, Index, "or use ");
         Put (Destination, Index, Item.Default);
         Put (Destination, Index, ";");
         Pointer := Index;
      end if;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Type_Parameter'Class;
                Prefix      : String
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Item.Default, Prefix);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Access_Type_Parameter
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is ");
      if Item.Not_Null then
         Put (Destination, Index, "not null ");
      end if;
      Put (Destination, Index, Item.Pointer);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Array_Type_Parameter
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Definition.all);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Derived_Type_Parameter
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Discriminants);
      Put (Destination, Index, " is ");
      if Item.Abstract_Type then
         Put (Destination, Index, "abstract ");
      end if;
      Put (Destination, Index, Image (Item.Mode, " "));
      Put (Destination, Index, "new ");
      Put (Destination, Index, Item.Parent_Type);
      Put (Destination, Index, Item.Interfaces, " and ", " and ", "");
      if Item.With_Private then
         Put (Destination, Index, " with private");
      end if;
      Put (Destination, Index, Item, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Function_Parameter
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "with function ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Profile);
      Put (Destination, Index, " return ");
      Put (Destination, Index, Item.Result.all);
      Put_Subprogram (Destination, Index, Item);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Incomplete_Type_Parameter
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Discriminants);
      if Item.Tagged_Type then
         Put (Destination, Index, " is tagged");
      end if;
      Put (Destination, Index, Item, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Interface_Type_Parameter
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Discriminants);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Image (Item.Mode, " "));
      Put (Destination, Index, "interface");
      Put (Destination, Index, Item.Interfaces, " ", " and ", "");
      Put (Destination, Index, Item, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Package_Parameter
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "with package ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is new ");
      Put (Destination, Index, Item.Target);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Private_Type_Parameter
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Discriminants);
      Put (Destination, Index, " is ");
      if Item.Abstract_Type then
         Put (Destination, Index, "abstract ");
      end if;
      if Item.Tagged_Type then
         Put (Destination, Index, "tagged ");
      end if;
      if Item.Limited_Type then
         Put (Destination, Index, "limited ");
      end if;
      Put (Destination, Index, "private;");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Procedure_Parameter
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "with procedure ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Profile);
      Put_Subprogram (Destination, Index, Item);
      Pointer := Index;
   end Put;

   function Image
            (  Item   : Formal_Scalar_Type;
               Prefix : String := ""
            )  return String is
   begin
      case Item is
         when Formal_Decimal_Fixed_Point_Type =>
            return Prefix & "delta <> digits <>";
         when Formal_Discrete_Type =>
            return Prefix & "(<>)";
         when Formal_Floating_Point_Type =>
            return Prefix & "digits <>";
         when Formal_Integer_Type =>
            return Prefix & "range <>";
         when Formal_Modular_Type =>
            return Prefix & "mod <>";
         when Formal_Ordinal_Fixed_Point_Type =>
            return Prefix & "delta <>";
      end case;
   end Image;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Scalar_Type_Parameter
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is");
      Put (Destination, Index, Image (Item.Kind_Of, " "));
      Put (Destination, Index, Item, ";");
      Pointer := Index;
   end Put;

end Parsers.Ada_Syntax_Analyzer.Declarations.Formal_Parameters;
