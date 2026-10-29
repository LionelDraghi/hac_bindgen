--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Declarations.Renamings                   Spring, 2026       --
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

package Parsers.Ada_Syntax_Analyzer.Declarations.Renamings is
--
-- Abstract_Renaming -- The base type of renaming nodes
--
   type Abstract_Renaming
        (  Aspects_Count : Natural
        )  is abstract new Declaration_Node with
   record
      Name    : aliased Defining_Identifier;
      Target  : Tokens.Argument_Token;
      Aspects : Aspect_Items_Array (1..Aspects_Count);
   end record;
--
-- Exception_Renaming -- Renaming of an exception ARM 8.5.2
--
   type Exception_Renaming is new Abstract_Renaming with null record;
--
-- Object_Renaming -- Renaming of an object ARM 8.5.1
--
--    <Name> [: <Type_Of>] renames <Target>
--
   type Object_Renaming is new Abstract_Renaming with record
      Type_Of : Parameter_Type;
   end record;
--
-- Subprogram_Renaming -- The base type for subprogram renaming
--
   type Subprogram_Renaming
        (  Private_Unit  : Boolean;
           Generic_Unit  : Boolean;
           Overrides     : Overriding_Indicator_Type;
           Aspects_Count : Natural
        )  is abstract new Abstract_Renaming
                           (  Aspects_Count => Aspects_Count
                           )  with
   record
      Parent    : Context_Location;
      Full_Name : Tokens.Argument_Token;
      Profile   : Parameter_Profile_Ptr;
   end record;
--
-- Function_Renaming -- Remaning of a functopn ARM 8.5.4
--
   type Function_Renaming is new Subprogram_Renaming with record
      Result : Object_Specification_Ptr;
   end record;
--
-- Package_Renaming -- Renaming of a package ARM 8.5.3
--
   type Package_Renaming
        (  Aspects_Count : Natural;
           Generic_Unit  : Boolean
        )  is new Abstract_Renaming
                  (  Aspects_Count  => Aspects_Count
                  )  with
   record
      Parent    : Context_Location;
      Full_Name : Tokens.Argument_Token;
   end record;
--
-- Procedure_Renaming -- Renaming of a procedure ARM 8.5.4
--
   type Procedure_Renaming is new Subprogram_Renaming with null record;

private
   function Equal
            (  Left  : Exception_Renaming;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Function_Renaming;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Object_Renaming;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Package_Renaming;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Procedure_Renaming;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;

   function Get_Class (Item : Exception_Renaming)
      return Program_Node_Class;
   function Get_Class (Item : Function_Renaming)
      return Program_Node_Class;
   function Get_Class (Item : Object_Renaming)
      return Program_Node_Class;
   function Get_Class (Item : Package_Renaming)
      return Program_Node_Class;
   function Get_Class (Item : Procedure_Renaming)
       return Program_Node_Class;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Exception_Renaming
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Function_Renaming
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Object_Renaming
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Package_Renaming
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Procedure_Renaming
             );
end Parsers.Ada_Syntax_Analyzer.Declarations.Renamings;
