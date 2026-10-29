--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Declarations                             Spring, 2026       --
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

package Parsers.Ada_Syntax_Analyzer.Declarations is
--
-- Declaration_Ptr_Array -- List of declarations
--
   type Declaration_Ptr_Array is
      array (Positive range <>) of Declaration_Ptr;
   type Declaration_Ptr_Array_Ptr is
      access constant Declaration_Ptr_Array;
--
-- Subtype_Mark_Array -- E.g. list of interfaces
--
   type Subtype_Mark_Array is
      array (Positive range <>) of Subtype_Mark;
--
-- General_Access_Modifier_Type ARM 3.10
--
   type General_Access_Modifier_Type is
        (  All_Access_Modifier,       -- all
           Constant_Access_Modifier,  -- constant
           No_Access_Modifier
        );
   function Image
            (  Item   : General_Access_Modifier_Type;
               Suffix : String := " "
            )  return String;
--
-- Compilation_Context_Type -- Types of contexts:
--
-- declare                        <Library_Unit_Context>
--    <Code_Block_Context>        generic
-- begin                             <Generic_Formal_Parameters_Context>
--    ...                         package P is
-- end;                              <Package_Interface_Context>
--                                private
--                                   <Package_Private_Context>
--                                end P;
--
-- protected type P is                 protected body P is
--    <Protected_Interface_Context>       <Protected_Body_Context>
-- private                             end P;
--    <Protected_Private_Context>
-- end P;                              task type T is
--                                        <Task_Interface_Context>
-- type T is record                    private
--    <Record_Component_Context>          <Task_Private_Context>
-- end record;                         end T;
--
   type Compilation_Context_Type is
        (  Code_Block_Context,
           Generic_Formal_Parameters_Context,
           Library_Unit_Context,
           Package_Interface_Context,
           Package_Private_Context,
           Protected_Interface_Context,
           Protected_Private_Context,
           Protected_Body_Context,
           Record_Component_Context,
           Task_Interface_Context,
           Task_Private_Context
        );
   function Image (Item : Compilation_Context_Type) return String;
--
-- Use_Clause -- Use clause ARM 8.4
--
   type Use_Clause;
   type Use_Clause_Ptr is access constant Use_Clause'Class;
--
-- Declaration_Context -- A declaration context
--
--    Declarations    - The items declared inside
--    Last_Use_Clause - The last use clause specified inside
--
   type Declaration_Context (Kind_Of : Compilation_Context_Type) is
      new Compilation_Context with
   record
      Declarations    : Declaration_Ptr_Array_Ptr;
      Last_Use_Clause : Use_Clause_Ptr;
   end record;
   function Is_Library_Unit (Item : Declaration_Context) return Boolean;
   type Declaration_Context_Ptr is access constant Declaration_Context;
   function Equal
            (  Left  : Declaration_Context_Ptr;
               Right : Declaration_Context_Ptr;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
--
-- Optional -- Optional item
--
   type Optional (Present : Boolean) is record
      case Present is
         when True =>
            Item : Tokens.Argument_Token;
         when False =>
            null;
      end case;
   end record;
   function Equal
            (  Left  : Optional;
               Right : Optional;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Prefix      : String;
                Item        : Optional;
                Suffix      : String
             );
--
-- Pragma_Argument_Association -- ARM 2.8
--
   type Pragma_Argument_Association (Named : Boolean := False) is record
      Argument : Optional (Named);
      Value    : Tokens.Argument_Token;
   end record;
   type Pragma_Argument_Association_Array is
      array (Positive range <>) of Pragma_Argument_Association;
--
-- Pragma_Clause -- Pragma ARM 2.8
--
   type Pragma_Clause (Count : Natural) is
      new Declaration_Node with
   record
      Name         : Tokens.Argument_Token;
      Associations : Pragma_Argument_Association_Array (1..Count);
   end record;
--
-- Parent_Unit -- Parent unit specification
--
--    Separate_Body - The unit is a separate unit
--    Parent        - The parent unit name
--
   type Parent_Unit (Separate_Body : Boolean) is record
      case Separate_Body is
         when True =>
            Parent : Tokens.Argument_Token;
         when False =>
            null;
      end case;
   end record;
   function Equal
            (  Left  : Parent_Unit;
               Right : Parent_Unit;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Parent_Unit
             );
--
-- Context_Clause -- A with or use clause
--
   type Context_Clause (Length : Positive) is
      abstract new Declaration_Node with
   record
      List : Argument_List (1..Length);
   end record;
--
-- Use_Clause -- Use package or use type base type
--
--    Enclosing - Location of the clause in the declaration context
--    Previous  - The previous use clause in the same context
--
-- All use of the same context clauses are linked:
--
--    declare
--       ...
--       use A; <---.
--       ...        |
--       use all type B; <--.
--       ...                |
--       use C; ------------.
--
   type Use_Clause is abstract new Context_Clause with record
      Enclosing : Context_Location;
      Previous  : Use_Clause_Ptr;
   end record;
--
-- Use_Package_Clause -- Use package(s) ARM 8.4
--
   type Use_Package_Clause is new Use_Clause with null record;
--
-- Use_Package_Clause -- Use type(s) ARM 8.4
--
   type Use_Type_Clause (All_Type : Boolean; Length : Positive) is
      new Use_Clause (Length) with null record;
--
-- With_Clause -- Context clause ARM 10.1.2
--
   type With_Clause
        (  Limited_With : Boolean;
           Private_With : Boolean;
           Length       : Positive
        )  is new Context_Clause (Length) with null record;

private
   function Get_Class (Item : Declaration_Context)
      return Program_Node_Class;
   function Get_Class (Item : Pragma_Clause)
      return Program_Node_Class;
   function Get_Class (Item : Use_Package_Clause)
      return Program_Node_Class;
   function Get_Class (Item : Use_Type_Clause)
      return Program_Node_Class;
   function Get_Class (Item : With_Clause)
      return Program_Node_Class;

   function Get_Item
            (  Context : Declaration_Context;
               Index   : Positive
            )  return Declaration_Ptr;
   function Get_Items_Number (Context : Declaration_Context)
      return Natural;

   function Equal
            (  Left  : Declaration_Context;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Pragma_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Subtype_Mark_Array;
               Right : Subtype_Mark_Array;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Use_Package_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Use_Type_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : With_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Declaration_Context
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Pragma_Clause
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Subtype_Mark_Array;
                Prefix      : String;
                Delimiter   : String;
                Suffix      : String
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Use_Package_Clause
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Use_Type_Clause
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : With_Clause
             );

end Parsers.Ada_Syntax_Analyzer.Declarations;
