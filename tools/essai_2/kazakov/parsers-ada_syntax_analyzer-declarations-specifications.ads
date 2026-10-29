--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Declarations.Specifications              Spring, 2026       --
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

package Parsers.Ada_Syntax_Analyzer.Declarations.Specifications is
--
-- Mode_Type -- A mode applied to a parameter or result
--
   type Mode_Type is
        (  Inout_Mode,                    -- in out Sybtype_Mark
           Out_Mode,                      -- out Sybtype_Mark
           In_Mode,                       -- in Sybtype_Mark
           Access_To_All,                 -- access all
           Access_To_Constant,            -- access constant
           Access_To_Variable,            -- access
           Access_To_Procedure,           -- access procedure
           Access_To_Protected_Procedure, -- access protected procedure
           Access_To_Function,            -- access function
           Access_To_Protected_Function,  -- access protected function
           Object_Mode,                   -- Subtype_Indication
           Array_Mode,                    -- array
           Constant_Mode                  -- <number>
        );
   subtype Parameter_Mode is Mode_Type
      range Inout_Mode..Access_To_Protected_Function;
   subtype Access_Mode is Mode_Type
      range Access_To_All..Access_To_Protected_Function;
   subtype Access_To_Mode_Type is Mode_Type
      range Access_To_Constant..Access_To_Variable;
   subtype Access_To_Subprogram_Mode is Mode_Type
      range Access_To_Procedure..Access_To_Protected_Function;
   subtype Component_Mode is Mode_Type
      range Access_To_All..Object_Mode;
   subtype Result_Mode is Mode_Type
      range In_Mode..Access_To_Protected_Function;
   function Image (Mode : Mode_Type) return String;
--
-- Interface_Type -- The type of an interface
--
   type Interface_Type is
        (  Any_Interface,
           Limited_Interface,       -- limited
           Synchronized_Interface,  -- synchronized
           Protected_Interface,     -- proteced
           Task_Interface           -- task
        );
   function Image
            (  Item   : Interface_Type;
               Suffix : String := ""
            )  return String;
   subtype Derived_Interface_Type is Interface_Type
      range Any_Interface..Synchronized_Interface;

   type Object_Specification;
   type Object_Specification_Ptr is
      access constant Object_Specification;

   type Parameter_Specification;
   type Parameter_Specification_Ptr is
      access constant Parameter_Specification;

   type Parameter_Specification_Ptr_Array is
      array (Positive range <>) of Parameter_Specification_Ptr;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Parameter_Specification_Ptr_Array;
                Prefix      : String := ""
             );
--
-- Parameter_Profile -- Of a subprogram
--
--    Parameters_Count - The number of parameter specifications
--
   type Parameter_Profile
        (  Parameters_Count : Natural
        )  is new Compilation_Context with
   record
      Outer : Program_Node_Ptr;
      List  : Parameter_Specification_Ptr_Array (1..Parameters_Count);
   end record;
--
-- Get_Count -- Get number of parameters
--
--    Item - The parameter profile
--
-- Returns :
--
--    The number of individual parameters
--
   function Get_Count (Item : Parameter_Profile) return Natural;

   type Parameter_Profile_Ptr is access constant Parameter_Profile;
   function Equal
            (  Left  : Parameter_Profile_Ptr;
               Right : Parameter_Profile_Ptr;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Parameter_Profile_Ptr
             );
--
-- Anonymous_Access_Definition -- Anonymous access definition ARM 3.10
--
   type Anonymous_Access_Definition (Mode : Access_Mode) is record
      Not_Null : Boolean;
      case Mode is
         when Access_To_All..Access_To_Variable =>
            Object : Subtype_Indication;
         when Access_To_Subprogram_Mode =>
            Profile : Parameter_Profile_Ptr;
            case Mode is
               when Access_To_Function | Access_To_Protected_Function =>
                  Result : Object_Specification_Ptr;
               when others =>
                  null;
            end case;
      end case;
   end record;
   function Equal
            (  Left  : Anonymous_Access_Definition;
               Right : Anonymous_Access_Definition;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Anonymous_Access_Definition
             );
--
-- Parameter_Type -- Type of a parameter
--
--    Present            - A type is specified
--    Aliased_Parameter  - aliased
--    Constant_Parameter - constant
--    Mode               - The parameter mode
--
   type Parameter_Type
        (  Present            : Boolean        := False;
           Aliased_Parameter  : Boolean        := False;
           Constant_Parameter : Boolean        := False;
           Mode               : Component_Mode := Object_Mode
        )  is
   record
      case Present is
         when True =>
            case Mode is
               when Access_Mode =>
                  Access_Parameter : Anonymous_Access_Definition (Mode);
               when Object_Mode =>
                  Object_Parameter : Subtype_Indication;
            end case;
         when False =>
            null;
      end case;
   end record;
   function Equal
            (  Left  : Parameter_Type;
               Right : Parameter_Type;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Parameter_Type
             );
--
-- Singleton_Parameter -- A single parameter
--
-- The parameter is a  defining  identifier  and  a  context  where  the
-- parameter is visiblble.
--
--         Defining identifier
--         /
--    for I in 1..10 loop \
--       S := S + I;       > Visibility scope
--    end loop;           /
--
   type Singleton_Parameter is new Compilation_Context with record
      Name    : aliased Defining_Identifier;
      Type_Of : Parameter_Type;
   end record;
   function Equal
            (  Left  : Singleton_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;

   type Singleton_Parameter_Array is
      array (Positive range <>) of aliased Singleton_Parameter;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Singleton_Parameter_Array
             );
--
-- Identifier_List -- A list of parameters
--
--      Defining identifiers list
--         _______
--        /       \
--   for (Name, Val) of Ada.Environment_Variables.
--                      Iterate (<>) loop   \
--      Put_Line (Name & " => " & Val);      > Visibility scope
--   end loop;                              /
--
   type Identifier_List
        (  Parameters_Count : Natural
        )  is new Compilation_Context with
   record
      Outer : Program_Node_Ptr;
      List  : Singleton_Parameter_Array (1..Parameters_Count);
   end record;
   type Identifier_List_Ptr is access constant Identifier_List;
--
-- Abstract_Clause -- The base type for representation clauses
--
   type Abstract_Clause is abstract new Declaration_Node with record
      Name : Tokens.Argument_Token;
   end record;
--
-- At_Clause -- Component clause ARM 13.5.1
--
   type At_Clause is new Abstract_Clause with record
      Address : Tokens.Argument_Token;
   end record;
--
-- Array_Type_Specification -- A part of array type definition ARM 3.6
--
--    [array] (<Iindices>) of access <Access_Component> |
--                                   <Object_Component>
--
   type Array_Type_Specification
        (  Mode              : Component_Mode;
           Dimension         : Positive;
           Aliased_Component : Boolean
        )  is
   record
      Indices : Subtype_Indication_Array (1..Dimension);
      case Mode is
         when Access_Mode =>
            Access_Component : Anonymous_Access_Definition (Mode);
         when Object_Mode =>
            Object_Component : Subtype_Indication;
      end case;
   end record;
   function Equal
            (  Left  : Array_Type_Specification;
               Right : Array_Type_Specification;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Array_Type_Specification
             );
   type Array_Type_Specification_Ptr is access
      constant Array_Type_Specification;
--
-- Attribute_Definition_Clause -- ARM 13.3
--
   type Attribute_Definition_Clause is new Abstract_Clause with record
      Attribute : Tokens.Argument_Token;
      Value     : Tokens.Argument_Token;
   end record;
--
-- Component_Clause -- Component clause 13.5
--
   type Component_Clause is record
      Name      : Tokens.Argument_Token;
      Position  : Tokens.Argument_Token;
      Bit_Range : Tokens.Argument_Token;
   end record;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Component_Clause
             );
--
-- Object_Specification -- Specification of a component or result
--
   type Object_Specification (Mode : Mode_Type) is record
      case Mode is
         when Object_Mode =>
            Variable     : Subtype_Indication;
         when In_Mode | Inout_Mode | Out_Mode =>
            Not_Null     : Boolean;
            Result       : Subtype_Mark;
         when Access_Mode =>
            Pointer      : Anonymous_Access_Definition (Mode);
         when Array_Mode =>
            Array_Object : Array_Type_Specification_Ptr;
         when Constant_Mode =>
            null;
      end case;
   end record;
   function Equal
            (  Left  : Object_Specification;
               Right : Object_Specification;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Object_Specification
             );
--
-- Entry_Declaration -- Entry declaration ARM 9.5.2
--
   type Entry_Declaration
        (  Is_Family     : Boolean;
           Overrides     : Overriding_Indicator_Type;
           Aspects_Count : Natural
        )  is new Declaration_Node with
   record
      Name    : aliased Defining_Identifier;
      Profile : Parameter_Profile_Ptr;
      Aspects : Aspect_Items_Array (1..Aspects_Count);
      Index   : Optional (Is_Family);
   end record;
--
-- Enumeration_Representation_Clause -- ARM 13.4
--
   type Enumeration_Representation_Clause
        (  Enumeration_Count : Natural
        )  is new Abstract_Clause with
   record
      Enumeration : Guarded_List (1..Enumeration_Count);
   end record;
--
-- Exception_Declaration -- Exception declaration ARM 11.1
--
   type Exception_Declaration
        (  Count         : Positive;
           Aspects_Count : Natural
        )  is new Declaration_Node with
   record
      Names   : Defining_Identifier_Array (1..Count);
      Aspects : Aspect_Items_Array (1..Aspects_Count);
   end record;
--
-- Subprogram_Specification -- The base  type for  declarations  of sub-
--                             programs
--
   type Subprogram_Specification
        (  Private_Unit        : Boolean;
           Generic_Unit        : Boolean;
           Abstract_Subprogram : Boolean;
           Overrides           : Overriding_Indicator_Type;
           Aspects_Count       : Natural
        )  is abstract new Declaration_Node with
   record
      Parent    : Context_Location;
      Profile   : Parameter_Profile_Ptr;
      Full_Name : Tokens.Argument_Token;
      Name      : aliased Defining_Identifier;
      Aspects   : Aspect_Items_Array (1..Aspects_Count);
   end record;
--
-- Function_Declaration -- ARM 6.1
--
   type Function_Declaration is new Subprogram_Specification with record
      Result : Object_Specification_Ptr;
   end record;
--
-- Package_Declaration -- Package declaration ARM 7.1
--
   type Package_Declaration
        (  Private_Unit  : Boolean;
           Generic_Unit  : Boolean;
           Public_Part   : access constant Declaration_Context;
           Aspects_Count : Natural
        )  is new Declaration_Node with
   record
      Full_Name    : Tokens.Argument_Token;
      Name         : aliased Defining_Identifier;
      Private_Part : Declaration_Context_Ptr;
      Aspects      : Aspect_Items_Array (1..Aspects_Count);
   end record;
--
-- Abstract_Instantiation -- The base type of instantiations
--
   type Abstract_Instantiation
        (  Aspects_Count : Natural
        )  is abstract new Declaration_Node with
   record
      Full_Name : Tokens.Argument_Token;
      Name      : aliased Defining_Identifier;
      Target    : Tokens.Argument_Token;
      Aspects   : Aspect_Items_Array (1..Aspects_Count);
   end record;
--
-- Function_Instantiation -- Generic function instantiation ARM 12.3
--
   type Function_Instantiation
        (  Overrides     : Overriding_Indicator_Type;
           Aspects_Count : Natural
        )  is new Abstract_Instantiation
                           (  Aspects_Count => Aspects_Count
                           )  with null record;
--
-- Package_Instantiation -- Instantiation of a generic package ARM 12.3
--
   type Package_Instantiation is
      new Abstract_Instantiation with null record;
--
-- Procedure_Declaration -- Declaration of a procedure ARM 6.1
--
   type Procedure_Declaration is
      new Subprogram_Specification with null record;
--
-- Procedure_Instantiation -- Generic procedure instantiation ARM 12.3
--
   type Procedure_Instantiation
        (  Overrides     : Overriding_Indicator_Type;
           Aspects_Count : Natural
        )  is new Abstract_Instantiation
                           (  Aspects_Count => Aspects_Count
                           )  with null record;
--
-- Parameter_Specification -- Specification of a parameter profile item
--
   type Parameter_Specification
        (  Mode              : Parameter_Mode;
           Aliased_Parameter : Boolean;
           Defaulted         : Boolean;
           Parameters_Count  : Positive;
           Aspects_Count     : Natural
        )  is new Declaration_Node with
   record
      Parameters : Defining_Identifier_Array (1..Parameters_Count);
      Profile    : Parameter_Profile_Ptr;
      Aspects    : Aspect_Items_Array (1..Aspects_Count);
      Default    : Optional (Defaulted);
      case Mode is
         when In_Mode | Inout_Mode | Out_Mode =>
            Not_Null : Boolean;
            Value    : Subtype_Mark;
         when Access_Mode =>
            Pointer  : Anonymous_Access_Definition (Mode);
      end case;
   end record;
--
-- Object_Declaration -- Declaration of an object 3.3.1
--
--    Count          - The number of identifiers
--    Initialized    - The object is initialized
--    Immutable      - THe object is constant
--    Aliased_Object - Aliased
--    Definition     - The object specification
--    Aspects_Count  - The aspects count
--
   type Object_Declaration
        (  Count          : Positive;
           Initialized    : Boolean;
           Immutable      : Boolean;
           Aliased_Object : Boolean;
           Definition     : access constant Object_Specification;
           Aspects_Count  : Natural
        )  is new Declaration_Node with
   record
      Names   : Defining_Identifier_Array (1..Count);
      Aspects : Aspect_Items_Array (1..Aspects_Count);
      Initial : Optional (Initialized);
   end record;
--
-- Component_Clause_Array -- Record components representation clause ARM
--                           13.5.1
--
   type Component_Clause_Array is
      array (Positive range <>) of Component_Clause;
   type Record_Representation_Clause
        (  Components_Count : Natural;
           Has_Modulus      : Boolean
        )  is new Abstract_Clause with
   record
      Components : Component_Clause_Array (1..Components_Count);
      Modulus    : Optional (Has_Modulus);
   end record;
--
-- Single_Protected_Declaration -- Single  protected  object declaration
--                                 ARM 9.4
--
   type Single_Protected_Declaration
        (  Aspects_Count    : Natural;
           Interfaces_Count : Natural
        )  is new Declaration_Node with
   record
      Name         : aliased Defining_Identifier;
      Public_Part  : Declaration_Context_Ptr;
      Private_Part : Declaration_Context_Ptr;
      Interfaces   : Subtype_Mark_Array (1..Interfaces_Count);
      Aspects      : Aspect_Items_Array (1..Aspects_Count);
   end record;
--
-- Single_Task_Declaration -- Single task declaration ARM 9.1
--
   type Single_Task_Declaration
        (  Aspects_Count    : Natural;
           Interfaces_Count : Natural
        )  is new Declaration_Node with
   record
      Name         : aliased Defining_Identifier;
      Public_Part  : Declaration_Context_Ptr;
      Private_Part : Declaration_Context_Ptr;
      Interfaces   : Subtype_Mark_Array (1..Interfaces_Count);
      Aspects      : Aspect_Items_Array (1..Aspects_Count);
   end record;
--
-- Variant_Part_Item -- An item of the record variant part ARM 3.8.1
--
--    when <Choices> => <Components>
--
   type Variant_Part_Item
        (  Choices_Count : Natural;
           Components    : access constant Declaration_Context
        )  is new Declaration_Node with
   record
      Choices : Subtype_Indication_Array (1..Choices_Count);
   end record;
   type Variant_Part_Item_Ptr is access constant Variant_Part_Item;
   type Variant_Part_Item_Ptr_Array is
      array (Positive range <>) of Variant_Part_Item_Ptr;
--
-- Variant_Part -- Variant part of a record declarion ARM 3.8.1
--
   type Variant_Part (Count : Positive) is new Declaration_Node with
   record
      Discriminant : Tokens.Argument_Token;
      Alternatives : Variant_Part_Item_Ptr_Array (1..Count);
   end record;
------------------------------------------------------------------------
--
-- Adjusting operations to set internal links
--
   procedure Add_Outer
             (  Definition : Anonymous_Access_Definition;
                Node       : Program_Node'Class;
                Parent     : Context_Location
             );
   procedure Add_Outer
             (  Definition : Array_Type_Specification;
                Node       : Program_Node'Class;
                Parent     : Context_Location
             );
   procedure Add_Outer
             (  Definition : Object_Specification;
                Node       : Program_Node'Class;
                Parent     : Context_Location
             );
private
   function Equal
            (  Left  : At_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Attribute_Definition_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Entry_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Enumeration_Representation_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Exception_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Function_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Function_Instantiation;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Identifier_List;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Object_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Package_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Package_Instantiation;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Parameter_Profile;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Parameter_Specification;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Procedure_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Procedure_Instantiation;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Record_Representation_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Single_Protected_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Single_Task_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Variant_Part_Item;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Variant_Part;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;

   function Get_Class (Item : At_Clause) return Program_Node_Class;
   function Get_Class (Item : Attribute_Definition_Clause)
      return Program_Node_Class;
   function Get_Class (Item : Object_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Entry_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Enumeration_Representation_Clause)
      return Program_Node_Class;
   function Get_Class (Item : Exception_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Function_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Function_Instantiation)
      return Program_Node_Class;
   function Get_Class (Item : Identifier_List)
      return Program_Node_Class;
   function Get_Class (Item : Package_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Package_Instantiation)
      return Program_Node_Class;
   function Get_Class (Item : Parameter_Profile)
      return Program_Node_Class;
   function Get_Class (Item : Parameter_Specification)
      return Program_Node_Class;
   function Get_Class (Item : Procedure_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Procedure_Instantiation)
      return Program_Node_Class;
   function Get_Class (Item : Record_Representation_Clause)
      return Program_Node_Class;
   function Get_Class (Item : Single_Protected_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Single_Task_Declaration)
      return Program_Node_Class;
   function Get_Class (Item : Singleton_Parameter)
      return Program_Node_Class;
   function Get_Class (Item : Variant_Part) return Program_Node_Class;
   function Get_Class (Item : Variant_Part_Item)
      return Program_Node_Class;

   function Get_Item
            (  Context : Identifier_List;
               Index   : Positive
            )  return Declaration_Ptr;
   function Get_Item
            (  Context : Parameter_Profile;
               Index   : Positive
            )  return Declaration_Ptr;
   function Get_Item
            (  Context : Singleton_Parameter;
               Index   : Positive
            )  return Declaration_Ptr;

   function Get_Items_Number (Item : Identifier_List) return Natural;
   function Get_Items_Number (Item : Parameter_Profile)
      return Natural;
   function Get_Items_Number (Item : Singleton_Parameter)
      return Natural;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : At_Clause
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Attribute_Definition_Clause
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Object_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Entry_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Enumeration_Representation_Clause
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Exception_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Function_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Function_Instantiation
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Identifier_List
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Package_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Package_Instantiation
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Parameter_Profile
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Parameter_Specification
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Procedure_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Procedure_Instantiation
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Record_Representation_Clause
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Single_Protected_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Single_Task_Declaration
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Singleton_Parameter
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Variant_Part
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Variant_Part_Item
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Variant_Part_Item_Ptr_Array
             );

end Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;
