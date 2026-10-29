--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Declarations.Types                       Spring, 2026       --
--  Interface                                                         --
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

with Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;

package Parsers.Ada_Syntax_Analyzer.Declarations.Types is
--
-- Abstract_Type_Declaration -- The base type of type declaration nodes
--
   type Abstract_Type_Declaration
        (  Aspects_Count : Natural
        )  is abstract new Declaration_Node with
   record
      Name    : aliased Defining_Identifier;
      Aspects : Aspect_Items_Array (1..Aspects_Count);
   end record;
--
-- Scalar_Type_Definition -- Scalar type declaration base type
--
   type Scalar_Type_Definition
        (  Constrained   : Boolean;
           Aspects_Count : Natural
        )  is abstract new Abstract_Type_Declaration
                           (  Aspects_Count => Aspects_Count
                           )  with
   record
      Constraint : Optional (Constrained);
   end record;
--
-- Access_Type_Declaration -- Access type declaration ARM 3.10
--
   type Access_Type_Declaration
        (  Mode          : Access_Mode;
           Aspects_Count : Natural
        )  is new Abstract_Type_Declaration
                  (  Aspects_Count => Aspects_Count
                  )  with
   record
      Pointer : Anonymous_Access_Definition (Mode);
   end record;
--
-- Array_Type_Declaration -- Array type declaration ARM 3.6
--
   type Array_Type_Declaration is
      new Abstract_Type_Declaration with
   record
      Definition : Array_Type_Specification_Ptr;
   end record;
--
-- Decimal_Fixed_Point_Type_Declaration -- Decimal fixed-point type  ARM
--                                         3.5.9
--
   type Decimal_Fixed_Point_Type_Declaration is
      new Scalar_Type_Definition with
   record
      Delta_Value  : Tokens.Argument_Token;
      Digits_Value : Tokens.Argument_Token;
   end record;
--
-- Derived_Type_Declaration -- Derived type declaration ARM 3.4
--
   type Derived_Type_Declaration
        (  Abstract_Type    : Boolean;
           Limited_Type     : Boolean;
           Extension_Record : Boolean;
           Interfaces_Count : Natural;
           Aspects_Count    : Natural
        )  is new Abstract_Type_Declaration
                  (  Aspects_Count => Aspects_Count
                  )  with
   record
      Parent_Type   : Subtype_Indication;
      Discriminants : Parameter_Profile_Ptr;
      Interfaces    : Subtype_Mark_Array (1..Interfaces_Count);
      case Extension_Record is
         when True =>
            Extension : Declaration_Context_Ptr;
         when False =>
            null;
      end case;
   end record;
--
-- Enumeration_Type_Declaration -- Enumeration   type  declaration  ARM
--                                 3.5.1
--
   type Enumeration_Type_Declaration
        (  List_Length   : Positive;
           Aspects_Count : Natural
        )  is new Abstract_Type_Declaration
                  (  Aspects_Count => Aspects_Count
                  )  with
   record
      List : Argument_List (1..List_Length);
   end record;
--
-- Floating_Point_Type_Declaration -- Floating-point  type   declaration
--                                    ARM 3.5.7
--
   type Floating_Point_Type_Declaration is
      new Scalar_Type_Definition with
   record
      Digits_Value : Tokens.Argument_Token;
   end record;
--
-- Incomplete_Type_Declaration -- Incomplete type declaration ARM 3.10
--
   type Incomplete_Type_Declaration
        (  Tagged_Type : Boolean
        )  is new Abstract_Type_Declaration
                  (  Aspects_Count => 0
                  )  with
   record
      Discriminants : Parameter_Profile_Ptr;
   end record;
--
-- Interface_Type_Declaration -- Interface type declaration ARM 3.9.4
--
   type Interface_Type_Declaration
        (  Mode             : Interface_Type;
           Interfaces_Count : Natural;
           Aspects_Count    : Natural
        )  is new Abstract_Type_Declaration
                  (  Aspects_Count => Aspects_Count
                  )  with
   record
      Discriminants : Parameter_Profile_Ptr;
      Interfaces    : Subtype_Mark_Array (1..Interfaces_Count);
   end record;
--
-- Modular_Type_Declaration -- Modular type declaration 3.5.4
--
   type Modular_Type_Declaration is new Scalar_Type_Definition with
   record
      Modulus : Tokens.Argument_Token;
   end record;
--
-- Ordinary_Fixed_Point_Type_Declaration -- Ordinal fixed-point type ARM
--                                          3.5.9
--
   type Ordinary_Fixed_Point_Type_Declaration is
      new Scalar_Type_Definition with
   record
      Delta_Value : Tokens.Argument_Token;
   end record;
--
-- Private_Type_Declaration -- Ordinal fixed-point type ARM 7.3
--
   type Private_Type_Declaration
        (  Abstract_Type : Boolean;
           Tagged_Type   : Boolean;
           Limited_Type  : Boolean;
           Aspects_Count : Natural
        )  is new Abstract_Type_Declaration
                  (  Aspects_Count => Aspects_Count
                  )  with
   record
      Discriminants : Parameter_Profile_Ptr;
   end record;
--
-- Private_Extension_Type_Declaration -- Private extension type declara-
--                                       tion ARM 7.3
--
   type Private_Extension_Type_Declaration
        (  Abstract_Type    : Boolean;
           Mode             : Derived_Interface_Type;
           Interfaces_Count : Natural;
           Aspects_Count    : Natural
        )  is new Abstract_Type_Declaration
                  (  Aspects_Count => Aspects_Count
                  )  with
   record
      Parent_Type   : Subtype_Indication;
      Discriminants : Parameter_Profile_Ptr;
      Interfaces    : Subtype_Mark_Array (1..Interfaces_Count);
   end record;
--
-- Protected_Type_Declaration -- Protected type declaration ARM 9.4
--
   type Protected_Type_Declaration
        (  Interfaces_Count : Natural;
           Public_Part      : access constant Declaration_Context;
           Aspects_Count    : Natural
        )  is new Abstract_Type_Declaration
                  (  Aspects_Count => Aspects_Count
                  )  with
   record
      Private_Part  : Declaration_Context_Ptr;
      Discriminants : Parameter_Profile_Ptr;
      Interfaces    : Subtype_Mark_Array (1..Interfaces_Count);
   end record;
--
-- Record_Type_Declaration -- Record type declaration ARM 3.8
--
   type Record_Type_Declaration
        (  Abstract_Type : Boolean;
           Tagged_Type   : Boolean;
           Limited_Type  : Boolean;
           Aspects_Count : Natural
        )  is new Abstract_Type_Declaration
                  (  Aspects_Count => Aspects_Count
                  )  with
   record
      Components    : Declaration_Context_Ptr;
      Discriminants : Parameter_Profile_Ptr;
   end record;
--
-- Signed_Integer_Type_Declaration -- Signed  integer  type  declaration
--                                    ARM 3.5.4
--
   type Signed_Integer_Type_Declaration
        (  Aspects_Count : Natural
        )  is new Scalar_Type_Definition
                  (  Constrained   => True,
                     Aspects_Count => Aspects_Count
                  )  with null record;
--
-- Subtype_Declaration -- Subtype declaration ARM 3.2.2
--
   type Subtype_Declaration is new Abstract_Type_Declaration with record
      Indication : Subtype_Indication;
   end record;
--
-- Task_Type_Declaration -- Task type declaration ARM 9.1
--
   type Task_Type_Declaration
        (  Aspects_Count    : Natural;
           Interfaces_Count : Natural
        )  is new Abstract_Type_Declaration
                  (  Aspects_Count => Aspects_Count
                  )  with
   record
      Discriminants : Parameter_Profile_Ptr;
      Public_Part   : Declaration_Context_Ptr;
      Private_Part  : Declaration_Context_Ptr;
      Interfaces    : Subtype_Mark_Array (1..Interfaces_Count);
   end record;

private
   function Equal
            (  Left  : Access_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Array_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Decimal_Fixed_Point_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Derived_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Enumeration_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Floating_Point_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Incomplete_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Interface_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Modular_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Ordinary_Fixed_Point_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Private_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Private_Extension_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Protected_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Record_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Signed_Integer_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Subtype_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Task_Type_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;

   function Get_Class (Item : Access_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Array_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Decimal_Fixed_Point_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Derived_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Enumeration_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Floating_Point_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Incomplete_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Interface_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Modular_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Ordinary_Fixed_Point_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Private_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Private_Extension_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Protected_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Record_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Signed_Integer_Type_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Subtype_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Task_Type_Declaration)
      return Program_Node_Class;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Access_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Array_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Decimal_Fixed_Point_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Derived_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Enumeration_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Floating_Point_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Incomplete_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Interface_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Modular_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Ordinary_Fixed_Point_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Private_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item : Private_Extension_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Protected_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Record_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Signed_Integer_Type_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item : Subtype_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Task_Type_Declaration
             );

end Parsers.Ada_Syntax_Analyzer.Declarations.Types;
