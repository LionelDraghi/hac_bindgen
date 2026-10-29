--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Declarations.Stubs                       Spring, 2026       --
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

package Parsers.Ada_Syntax_Analyzer.Declarations.Stubs is
--
-- Abstract_Stub -- The base type of all stub nodes
--
   type Abstract_Stub (Aspects_Count : Natural) is abstract
      new Declaration_Node with
   record
      Name    : aliased Defining_Identifier;
      Aspects : Aspect_Items_Array (1..Aspects_Count);
   end record;
--
-- Subprogram_Stub -- The base type of a function or procedure stub
--
   type Subprogram_Stub
        (  Aspects_Count    : Natural;
           Overrides        : Overriding_Indicator_Type
        )  is abstract new Abstract_Stub
                           (  Aspects_Count => Aspects_Count
                           )  with
   record
      Profile : Parameter_Profile_Ptr;
   end record;
--
-- Function_Stub -- Function body stub
--
   type Function_Stub is new Subprogram_Stub with record
      Result : Object_Specification_Ptr;
   end record;
--
-- Package_Stub -- Package body stub
--
   type Package_Stub is new Abstract_Stub with null record;
--
-- Procedure_Stub -- Procedure body stub
--
   type Procedure_Stub is new Subprogram_Stub with null record;
--
-- Protected_Stub -- Protected body stub
--
   type Protected_Stub is new Abstract_Stub with null record;
--
-- Task_Stub -- Task body stub
--
   type Task_Stub is new Abstract_Stub with null record;

private
   function Equal
            (  Left  : Function_Stub;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Package_Stub;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Procedure_Stub;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Protected_Stub;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Task_Stub;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;

   function Get_Class (Item : Function_Stub ) return Program_Node_Class;
   function Get_Class (Item : Procedure_Stub) return Program_Node_Class;
   function Get_Class (Item : Package_Stub  ) return Program_Node_Class;
   function Get_Class (Item : Protected_Stub) return Program_Node_Class;
   function Get_Class (Item : Task_Stub     ) return Program_Node_Class;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Function_Stub
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Package_Stub
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Procedure_Stub
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Protected_Stub
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Task_Stub
             );

end Parsers.Ada_Syntax_Analyzer.Declarations.Stubs;
