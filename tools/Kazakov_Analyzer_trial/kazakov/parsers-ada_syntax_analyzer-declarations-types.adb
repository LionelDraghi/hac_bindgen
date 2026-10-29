--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Declarations.Types                       Spring, 2026       --
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

package body Parsers.Ada_Syntax_Analyzer.Declarations.Types is

   function Equal
            (  Left  : Access_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Access_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Access_Type_Declaration renames
                    Access_Type_Declaration (Right);
         begin
            if Left.Mode /= Other.Mode then
               return Inequal;
            elsif not Equal (Left.Pointer, Other.Pointer, Mode) then
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
            (  Left  : Array_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Array_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Array_Type_Declaration renames
                    Array_Type_Declaration (Right);
         begin
            if not Equal
                   (  Left.Definition.all,
                      Other.Definition.all,
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
            (  Left  : Decimal_Fixed_Point_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Decimal_Fixed_Point_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Decimal_Fixed_Point_Type_Declaration renames
                    Decimal_Fixed_Point_Type_Declaration (Right);
         begin
            if Left.Constrained /= Other.Constrained then
               return Inequal;
            elsif Left.Constrained and then
                  not Equal
                      (  Left.Constraint,
                         Other.Constraint,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Delta_Value,
                         Other.Delta_Value,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Digits_Value,
                         Other.Digits_Value,
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
            (  Left  : Derived_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Derived_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Derived_Type_Declaration renames
                    Derived_Type_Declaration (Right);
         begin
            if Left.Abstract_Type /= Other.Abstract_Type then
               return Inequal;
            elsif Left.Limited_Type /= Other.Limited_Type then
               return Inequal;
            elsif Left.Extension_Record /= Other.Extension_Record then
               return Inequal;
            elsif not Equal
                      (  Left.Parent_Type,
                         Other.Parent_Type,
                         Mode
                      )  then
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
            (  Left  : Enumeration_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Enumeration_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Enumeration_Type_Declaration renames
                    Enumeration_Type_Declaration (Right);
         begin
            if not Equal (Left.List, Other.List, Mode) then
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
            (  Left  : Floating_Point_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Floating_Point_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Floating_Point_Type_Declaration renames
                    Floating_Point_Type_Declaration (Right);
         begin
            if Left.Constrained /= Other.Constrained then
               return Inequal;
            elsif Left.Constrained and then
                  not Equal
                      (  Left.Constraint,
                         Other.Constraint,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Digits_Value,
                         Other.Digits_Value,
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
            (  Left  : Incomplete_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Incomplete_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Incomplete_Type_Declaration renames
                    Incomplete_Type_Declaration (Right);
         begin
            if Left.Tagged_Type /= Other.Tagged_Type then
               return Inequal;
            elsif not Equal
                      (  Left.Discriminants,
                         Other.Discriminants,
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
            (  Left  : Interface_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Interface_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Interface_Type_Declaration renames
                    Interface_Type_Declaration (Right);
         begin
            if Left.Mode /= Other.Mode then
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
            (  Left  : Modular_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Modular_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Modular_Type_Declaration renames
                    Modular_Type_Declaration (Right);
         begin
            if Left.Constrained /= Other.Constrained then
               return Inequal;
            elsif Left.Constrained and then
                  not Equal
                      (  Left.Constraint,
                         Other.Constraint,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal (Left.Modulus, Other.Modulus, Mode) then
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
            (  Left  : Ordinary_Fixed_Point_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Ordinary_Fixed_Point_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Ordinary_Fixed_Point_Type_Declaration renames
                    Ordinary_Fixed_Point_Type_Declaration (Right);
         begin
            if Left.Constrained /= Other.Constrained then
               return Inequal;
            elsif Left.Constrained and then
                  not Equal
                      (  Left.Constraint,
                         Other.Constraint,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Delta_Value,
                         Other.Delta_Value,
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
            (  Left  : Private_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Private_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Private_Type_Declaration renames
                    Private_Type_Declaration (Right);
         begin
            if Left.Abstract_Type /= Other.Abstract_Type then
               return Inequal;
            elsif Left.Tagged_Type /= Other.Tagged_Type then
               return Inequal;
            elsif Left.Limited_Type /= Other.Limited_Type then
               return Inequal;
            elsif not Equal
                      (  Left.Discriminants,
                         Other.Discriminants,
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
            (  Left  : Private_Extension_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Private_Extension_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Private_Extension_Type_Declaration renames
                    Private_Extension_Type_Declaration (Right);
         begin
            if Left.Abstract_Type /= Other.Abstract_Type then
               return Inequal;
            elsif Left.Mode /= Other.Mode then
               return Inequal;
            elsif not Equal
                      (  Left.Parent_Type,
                         Other.Parent_Type,
                         Mode
                      )  then
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
            (  Left  : Protected_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Protected_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Protected_Type_Declaration renames
                    Protected_Type_Declaration (Right);
         begin
            if not Equal
                   (  Left.Public_Part.all,
                      Other.Public_Part.all,
                      Mode
                   )  then
               return Inequal;
            elsif not Equal
                      (  Left.Private_Part,
                         Other.Private_Part,
                         Mode
                      )  then
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
            (  Left  : Record_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Record_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Record_Type_Declaration renames
                    Record_Type_Declaration (Right);
         begin
            if Left.Abstract_Type /= Other.Abstract_Type then
               return Inequal;
            elsif Left.Tagged_Type /= Other.Tagged_Type then
               return Inequal;
            elsif Left.Limited_Type /= Other.Limited_Type then
               return Inequal;
            elsif not Equal
                      (  Left.Components,
                         Other.Components,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Discriminants,
                         Other.Discriminants,
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
            (  Left  : Signed_Integer_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Signed_Integer_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Signed_Integer_Type_Declaration renames
                    Signed_Integer_Type_Declaration (Right);
         begin
            if not Equal (Left.Constraint, Other.Constraint, Mode) then
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
            (  Left  : Subtype_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Subtype_Declaration then
         return Inequal;
      else
         declare
            Other : Subtype_Declaration renames
                    Subtype_Declaration (Right);
         begin
            if not Equal (Left.Indication, Other.Indication, Mode) then
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
            (  Left  : Task_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Task_Type_Declaration then
         return Inequal;
      else
         declare
            Other : Task_Type_Declaration renames
                    Task_Type_Declaration (Right);
         begin
            if not Equal
                   (  Left.Discriminants,
                      Other.Discriminants,
                      Mode
                   )  then
               return Inequal;
            elsif not Equal
                      (  Left.Public_Part,
                         Other.Public_Part,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Private_Part,
                         Other.Private_Part,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Interfaces,
                         Other.Interfaces,
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

   function Get_Class (Item : Access_Type_Declaration)
      return Program_Node_Class is
   begin
      return Access_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Array_Type_Declaration)
      return Program_Node_Class is
   begin
      return Array_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Decimal_Fixed_Point_Type_Declaration)
      return Program_Node_Class is
   begin
      return Decimal_Fixed_Point_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Derived_Type_Declaration)
      return Program_Node_Class is
   begin
      return Derived_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Enumeration_Type_Declaration)
      return Program_Node_Class is
   begin
      return Enumeration_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Floating_Point_Type_Declaration)
      return Program_Node_Class is
   begin
      return Floating_Point_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Incomplete_Type_Declaration)
      return Program_Node_Class is
   begin
      return Incomplete_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Interface_Type_Declaration)
      return Program_Node_Class is
   begin
      return Interface_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Modular_Type_Declaration)
      return Program_Node_Class is
   begin
      return Modular_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Ordinary_Fixed_Point_Type_Declaration)
      return Program_Node_Class is
   begin
      return Ordinary_Fixed_Point_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Private_Type_Declaration)
      return Program_Node_Class is
   begin
      return Private_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Private_Extension_Type_Declaration)
      return Program_Node_Class is
   begin
      return Private_Extension_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Protected_Type_Declaration)
      return Program_Node_Class is
   begin
      return Protected_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Record_Type_Declaration)
      return Program_Node_Class is
   begin
      return Record_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Signed_Integer_Type_Declaration)
      return Program_Node_Class is
   begin
      return Signed_Integer_Type_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Subtype_Declaration)
      return Program_Node_Class is
   begin
      return Subtype_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Task_Type_Declaration)
      return Program_Node_Class is
   begin
      return Task_Type_Declaration_Node;
   end Get_Class;

   procedure Put_Scalar_Type_Definition
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Scalar_Type_Definition'Class
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Constrained then
         Put (Destination, Index, " range ");
         Put (Destination, Index, Item.Constraint.Item);
      end if;
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put_Scalar_Type_Definition;


   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Access_Type_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Pointer);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Array_Type_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Definition.all);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Decimal_Fixed_Point_Type_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is delta ");
      Put (Destination, Index, Item.Delta_Value);
      Put (Destination, Index, " digits ");
      Put (Destination, Index, Item.Digits_Value);
      Put_Scalar_Type_Definition (Destination, Index, Item);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Declaration_Context_Ptr;
                Name        : Defining_Identifier
             )  is
      Index : Integer := Pointer;
   begin
      if Item = null then
         Put (Destination, Index, "null record");
      else
         Put (Destination, Index, "record ");
         Put (Destination, Index, Item.all);
         Put (Destination, Index, "end record");
      end if;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Derived_Type_Declaration
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
      if Item.Limited_Type then
         Put (Destination, Index, "limited ");
      end if;
      Put (Destination, Index, "new ");
      Put (Destination, Index, Item.Parent_Type);
      Put (Destination, Index, Item.Interfaces, " and ", " and ", "");
      if Item.Extension_Record then
         Put (Destination, Index, " with ");
         Put (Destination, Index, Item.Extension, Item.Name);
      end if;
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Enumeration_Type_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is ");
      Put
      (  Destination => Destination,
         Pointer     => Index,
         List        => Item.List,
         Prefix      => "(",
         Delimiter   => ", ",
         Suffix      => ")"
      );
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Floating_Point_Type_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is digits ");
      Put (Destination, Index, Item.Digits_Value);
      Put_Scalar_Type_Definition (Destination, Index, Item);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Incomplete_Type_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Discriminants);
      if Item.Tagged_Type then
         Put (Destination, Index, " is tagged");
      end if;
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Interface_Type_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Discriminants);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Image (Item.Mode, " "));
      Put (Destination, Index, "interface");
      Put (Destination, Index, Item.Interfaces, " and ", " and ", "");
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Modular_Type_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is mod ");
      Put (Destination, Index, Item.Modulus);
      Put_Scalar_Type_Definition (Destination, Index, Item);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Ordinary_Fixed_Point_Type_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is delta ");
      Put (Destination, Index, Item.Delta_Value);
      Put_Scalar_Type_Definition (Destination, Index, Item);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Private_Type_Declaration
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
      Put (Destination, Index, "private");
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Private_Extension_Type_Declaration
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
      Put (Destination, Index, " with private");
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Protected_Type_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "protected type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Discriminants);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Interfaces,
                               "new ", " and ", " with ");
      Put (Destination, Index, Item.Interfaces, "", " and ", " ");
      Put (Destination, Index, Item.Public_Part.all);
      if Item.Private_Part /= null then
         Put (Destination, Index, "private ");
         Put (Destination, Index, Item.Private_Part.all);
      end if;
      Put (Destination, Index, "end ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Record_Type_Declaration
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
      Put (Destination, Index, Item.Components, Item.Name);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Signed_Integer_Type_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is");
      Put_Scalar_Type_Definition (Destination, Index, Item);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Subtype_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "subtype ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Indication);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Task_Type_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "task type ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Discriminants);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Interfaces,
                                "new ", " and ", " with ");
      Put (Destination, Index, Item.Public_Part.all);
      if Item.Private_Part /= null then
         Put (Destination, Index, "private ");
         Put (Destination, Index, Item.Private_Part.all);
      end if;
      Put (Destination, Index, "end ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

end Parsers.Ada_Syntax_Analyzer.Declarations.Types;
