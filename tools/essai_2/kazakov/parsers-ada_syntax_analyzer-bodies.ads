--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Bodies                                   Spring, 2026       --
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

with Parsers.Ada_Syntax_Analyzer.Declarations;
use  Parsers.Ada_Syntax_Analyzer.Declarations;

with Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;

with Parsers.Ada_Syntax_Analyzer.Statements;
use  Parsers.Ada_Syntax_Analyzer.Statements;

package Parsers.Ada_Syntax_Analyzer.Bodies is
--
-- Abstract_Body -- The base type. It has name, declarations and aspects
--
   type Abstract_Body
        (  Declarations  : access constant Declaration_Context;
           Aspects_Count : Natural
        )  is abstract new Declaration_Node with
   record
      Name    : aliased Defining_Identifier;
      Aspects : Aspect_Items_Array (1..Aspects_Count);
   end record;
--
-- Executable_Body -- The base for bodies having executable code
--
   type Executable_Body
        (  Declarations  : access constant Declaration_Context;
           Code          : access constant Handled_Statement_Sequence;
           Overrides     : Overriding_Indicator_Type;
           Aspects_Count : Natural
        )  is abstract new Abstract_Body
                           (  Declarations  => Declarations,
                              Aspects_Count => Aspects_Count
                           )  with null record;
--
-- Subroutine_Body -- The base for procedure and function bodies
--
   type Subroutine_Body
        (  Declarations  : access constant Declaration_Context;
           Code          : access constant Handled_Statement_Sequence;
           Overrides     : Overriding_Indicator_Type;
           Separate_Body : Boolean;
           Aspects_Count : Natural
        )  is abstract new Executable_Body
                           (  Declarations  => Declarations,
                              Code          => Code,
                              Overrides     => Overrides,
                              Aspects_Count => Aspects_Count
                           )  with
   record
      Full_Name : Tokens.Argument_Token; -- Different if library unit
      Profile   : Parameter_Profile_Ptr;
      Parent    : Parent_Unit (Separate_Body);
   end record;
--
-- Entry_Body -- A body of an entry
--
   type Entry_Body
        (  Has_Index     : Boolean;
           Declarations  : access constant Declaration_Context;
           Code          : access constant Handled_Statement_Sequence;
           Overrides     : Overriding_Indicator_Type;
           Aspects_Count : Natural
        )  is new Executable_Body
                  (  Declarations  => Declarations,
                     Code          => Code,
                     Overrides     => Overrides,
                     Aspects_Count => Aspects_Count
                  )  with
   record
      Profile : Parameter_Profile_Ptr;
      Barrier : Tokens.Argument_Token;
      Index   : Optional (Has_Index);
   end record;
--
-- Function_Body -- The body of a function
--
   type Function_Body is new Subroutine_Body with record
      Result : Object_Specification_Ptr;
   end record;
--
-- Function_Expression -- A function expression. It is both a body and a
--                        declaration
--
   type Function_Expression
        (  Aspects_Count : Natural;
           Overrides     : Overriding_Indicator_Type
        )  is new Declaration_Node with
   record
      Name       : aliased Defining_Identifier;
      Result     : Object_Specification_Ptr;
      Expression : Tokens.Argument_Token;
      Profile    : Parameter_Profile_Ptr;
      Aspects    : Aspect_Items_Array (1..Aspects_Count);
   end record;
--
-- Null_Procedure -- Null procedure ARM 6.7
--
   type Null_Procedure is
      new Procedure_Declaration with null record;
--
-- Package_Body -- The body of a package
--
   type Package_Body
        (  Declarations  : access constant Declaration_Context;
           Separate_Body : Boolean;
           Aspects_Count : Natural
        )  is new Abstract_Body
                           (  Declarations  => Declarations,
                              Aspects_Count => Aspects_Count
                           )  with
    record
      Full_Name : Tokens.Argument_Token; -- Different if library unit
      Parent    : Parent_Unit (Separate_Body);
      Code      : Handled_Statement_Sequence_Ptr;
   end record;
--
-- Procedure_Body -- The body of a procedure
--
   type Procedure_Body is new Subroutine_Body with null record;
--
-- Protected_Body -- The body of a protected type
--
   type Protected_Body
        (  Declarations  : access constant Declaration_Context;
           Aspects_Count : Natural;
           Separate_Body : Boolean
        )  is new Abstract_Body
                  (  Declarations  => Declarations,
                     Aspects_Count => Aspects_Count
                  )  with
   record
      Parent : Parent_Unit (Separate_Body);
   end record;
--
-- Task_Body -- The body of a protected type
--
   type Task_Body
        (  Declarations  : access constant Declaration_Context;
           Code          : access constant Handled_Statement_Sequence;
           Separate_Body : Boolean;
           Aspects_Count : Natural
        )  is new Executable_Body
                  (  Declarations  => Declarations,
                     Code          => Code,
                     Overrides     => No_Indicator,
                     Aspects_Count => Aspects_Count
                  )  with
   record
      Parent : Parent_Unit (Separate_Body);
   end record;

private
   function Equal
            (  Left  : Entry_Body;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Function_Expression;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Function_Body;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Null_Procedure;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Package_Body;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Procedure_Body;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Protected_Body;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Task_Body;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;

   function Get_Class (Item : Entry_Body    ) return Program_Node_Class;
   function Get_Class (Item : Function_Expression)
      return Program_Node_Class;
   function Get_Class (Item : Function_Body ) return Program_Node_Class;
   function Get_Class (Item : Null_Procedure) return Program_Node_Class;
   function Get_Class (Item : Package_Body  ) return Program_Node_Class;
   function Get_Class (Item : Procedure_Body)
      return Program_Node_Class;
   function Get_Class (Item : Protected_Body) return Program_Node_Class;
   function Get_Class (Item : Task_Body     ) return Program_Node_Class;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Entry_Body
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Function_Expression
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Function_Body
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Null_Procedure
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Package_Body
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Procedure_Body
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Protected_Body
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Task_Body
             );

end Parsers.Ada_Syntax_Analyzer.Bodies;
