--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer                 Luebeck            --
--        Text_IO                                  Summer, 2026       --
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

with Ada.Text_IO;  use Ada.Text_IO;

package Parsers.Ada_Syntax_Analyzer.Text_IO is
--
-- Put -- Write syntax tree into a file
--
--    Tree            - The syntax tree or aspect specification
--  [ Output / Name ] - The file or file name to write into
--    Prefix          - The prefix to decorate output
--
   procedure Put
             (  Tree   : Tokens.Argument_Token;
                Output : File_Type := Standard_Output;
                Prefix : String    := "";
                Nested : Nesting   := Top
             );
   procedure Put
             (  Tree   : Tokens.Argument_Token;
                Name   : String;
                Prefix : String  := "";
                Nested : Nesting := Top
             );
--
-- Put_Contexts -- Output cross-reference of contexts
--
-- [ File ] - The output file
--   Xref   - The cross-reference
--
   procedure Put_Contexts (File : File_Type; Xref : Cross_Reference);
   procedure Put_Contexts (Xref : Cross_Reference);
--
-- Put_Defining_Identifiers -- Output cross-reference of defining
--                             identifiers
-- [ File ] - The output file
--   Xref   - The cross-reference
--   Field  - The maximal length of identifier before truncation
--
   procedure Put_Defining_Identifiers
             (  File  : File_Type;
                Xref  : Cross_Reference;
                Field : Output_Length := 50
             );
   procedure Put_Defining_Identifiers
             (  Xref  : Cross_Reference;
                Field : Output_Length := 50
             );
private
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : String
             );
   function Image is new Generic_Image (String);

end Parsers.Ada_Syntax_Analyzer.Text_IO;
