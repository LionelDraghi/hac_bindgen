--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Declarations.Formal_Parameters           Spring, 2026       --
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

package Parsers.Ada_Syntax_Analyzer.Declarations.Formal_Parameters is
--
-- Formal_Parameter -- The base type of formal parameters
--
   type Formal_Parameter is abstract new Declaration_Node with record
      Name : aliased Defining_Identifier;
   end record;
--
-- Formal_Type_Default -- The default of a type
--
--    Defaulted - If there is a default
--
   type Formal_Type_Default (Defaulted : Boolean) is record
      case Defaulted is
          when True =>
             Default : Subtype_Mark;
          when False =>
             null;
      end case;
   end record;
--
-- Formal_Subprogram_Default_Type -- The default of a subprogram
--
   type Formal_Subprogram_Default_Type is
        (  No_Default,    -- No default
           Name_Default,  -- generic ... is <name>
           Box_Default,   -- generic ... is <>
           Null_Default   -- generic ... is null
        );
   subtype Formal_Function_Default_Type is
      Formal_Subprogram_Default_Type range No_Default..Box_Default;
--
-- Formal_Type_Parameter -- The base type of formal type
--
   type Formal_Type_Parameter
        (  Defaulted     : Boolean;
           Aspects_Count : Natural
        )  is abstract new Formal_Parameter with
   record
      Aspects : Aspect_Items_Array (1..Aspects_Count);
      Default : Formal_Type_Default (Defaulted => Defaulted);
   end record;
--
-- Formal_Scalar_Type -- Formal scalar types ARM 12.5
--
   type Formal_Scalar_Type is
        (  Formal_Decimal_Fixed_Point_Type,
           Formal_Discrete_Type,
           Formal_Floating_Point_Type,
           Formal_Integer_Type,
           Formal_Modular_Type,
           Formal_Ordinal_Fixed_Point_Type
        );
   function Image
            (  Item   : Formal_Scalar_Type;
               Prefix : String := ""
            )  return String;
--
-- Formal_Access_Type_Parameter -- A formal access type
--
   type Formal_Access_Type_Parameter
        (  Mode          : Access_Mode;
           Not_Null      : Boolean;
           Defaulted     : Boolean;
           Aspects_Count : Natural
        )  is new Formal_Type_Parameter
                  (  Defaulted     => Defaulted,
                     Aspects_Count => Aspects_Count
                  )  with
   record
      Pointer : Anonymous_Access_Definition (Mode);
   end record;
--
-- Formal_Array_Type_Parameter -- A formal array type
--
   type Formal_Array_Type_Parameter is
      new Formal_Type_Parameter with
   record
      Definition : Array_Type_Specification_Ptr;
   end record;
--
-- Formal_Derived_Type_Parameter -- A formal derived type
--
   type Formal_Derived_Type_Parameter
        (  Abstract_Type    : Boolean;
           With_Private     : Boolean;
           Mode             : Derived_Interface_Type;
           Interfaces_Count : Natural;
           Defaulted        : Boolean;
           Aspects_Count    : Natural
        )  is new Formal_Type_Parameter
                  (  Defaulted     => Defaulted,
                     Aspects_Count => Aspects_Count
                  )  with
   record
      Parent_Type   : Tokens.Argument_Token;
      Discriminants : Parameter_Profile_Ptr;
      Interfaces    : Subtype_Mark_Array (1..Interfaces_Count);
   end record;
--
-- Formal_Subprogram_Parameter -- The base type of a formal subprogram
--
   type Formal_Subprogram_Parameter
        (  Abstract_Subprogram : Boolean;
           Aspects_Count       : Natural;
           Default             : Formal_Subprogram_Default_Type
        )  is abstract new Formal_Parameter with
   record
      Profile : Parameter_Profile_Ptr;
      Aspects : Aspect_Items_Array (1..Aspects_Count);
      case Default is
         when Name_Default =>
            Default_Name : Tokens.Argument_Token;
         when No_Default | Box_Default | Null_Default =>
            null;
      end case;
   end record;
--
-- Formal_Function_Parameter -- A formal function parameter
--
   type Formal_Function_Parameter
        (  Abstract_Subprogram : Boolean;
           Aspects_Count       : Natural;
           Default             : Formal_Function_Default_Type
        )  is new Formal_Subprogram_Parameter
                  (  Abstract_Subprogram => Abstract_Subprogram,
                     Default             => Default,
                     Aspects_Count       => Aspects_Count
                  )  with
   record
      Result : Object_Specification_Ptr;
   end record;
--
-- Formal_Incomplete_Type_Parameter -- A formal incomplete type
--
   type Formal_Incomplete_Type_Parameter
        (  Tagged_Type : Boolean;
           Defaulted   : Boolean
        )  is new Formal_Type_Parameter
                  (  Defaulted     => Defaulted,
                     Aspects_Count => 0
                  )  with
   record
      Discriminants : Parameter_Profile_Ptr;
   end record;
--
-- Formal_Interface_Type_Parameter -- A formal interface type
--
   type Formal_Interface_Type_Parameter
        (  Mode             : Interface_Type;
           Interfaces_Count : Natural;
           Defaulted        : Boolean;
           Aspects_Count    : Natural
        )  is new Formal_Type_Parameter
                  (  Defaulted     => Defaulted,
                     Aspects_Count => Aspects_Count
                  )  with
   record
      Discriminants : Parameter_Profile_Ptr;
      Interfaces    : Subtype_Mark_Array (1..Interfaces_Count);
   end record;
--
-- Formal_Package_Parameter -- A formal package
--
   type Formal_Package_Parameter (Aspects_Count : Natural) is
      new Formal_Parameter with
   record
      Target  : Tokens.Argument_Token;
      Aspects : Aspect_Items_Array (1..Aspects_Count);
   end record;
--
-- Formal_Private_Type_Parameter -- A formal private type
--
   type Formal_Private_Type_Parameter
        (  Abstract_Type : Boolean;
           Limited_Type  : Boolean;
           Tagged_Type   : Boolean;
           Defaulted     : Boolean;
           Aspects_Count : Natural
        )  is new Formal_Type_Parameter
                  (  Defaulted     => Defaulted,
                     Aspects_Count => Aspects_Count
                  )  with
   record
      Discriminants : Parameter_Profile_Ptr;
   end record;
--
-- Formal_Procedure_Parameter -- A formal procedure
--
   type Formal_Procedure_Parameter is
      new Formal_Subprogram_Parameter with null record;
--
-- Formal_Scalar_Type_Parameter -- A formal scalar type
--
   type Formal_Scalar_Type_Parameter
        (  Kind_Of       : Formal_Scalar_Type;
           Defaulted     : Boolean;
           Aspects_Count : Natural
        )  is new Formal_Type_Parameter
                  (  Defaulted     => Defaulted,
                     Aspects_Count => Aspects_Count
                  )  with null record;
private
   function Equal
            (  Left  : Formal_Access_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Formal_Array_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Formal_Derived_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Formal_Function_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Formal_Incomplete_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Formal_Interface_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Formal_Package_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Formal_Private_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Formal_Procedure_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Formal_Scalar_Type_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Formal_Type_Default;
               Right : Formal_Type_Default;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;

   function Get_Class (Item : Formal_Access_Type_Parameter)
       return Program_Node_Class;
   function Get_Class (Item : Formal_Array_Type_Parameter)
       return Program_Node_Class;
   function Get_Class (Item : Formal_Derived_Type_Parameter)
       return Program_Node_Class;
   function Get_Class (Item : Formal_Function_Parameter)
      return Program_Node_Class;
   function Get_Class (Item : Formal_Incomplete_Type_Parameter)
      return Program_Node_Class;
   function Get_Class (Item : Formal_Interface_Type_Parameter)
       return Program_Node_Class;
   function Get_Class (Item : Formal_Package_Parameter)
      return Program_Node_Class;
   function Get_Class (Item : Formal_Private_Type_Parameter)
       return Program_Node_Class;
   function Get_Class (Item : Formal_Procedure_Parameter)
       return Program_Node_Class;
   function Get_Class (Item : Formal_Scalar_Type_Parameter)
       return Program_Node_Class;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Access_Type_Parameter
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Array_Type_Parameter
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Derived_Type_Parameter
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Function_Parameter
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Incomplete_Type_Parameter
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Interface_Type_Parameter
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Package_Parameter
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Private_Type_Parameter
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Procedure_Parameter
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Formal_Scalar_Type_Parameter
             );

end Parsers.Ada_Syntax_Analyzer.Declarations.Formal_Parameters;
