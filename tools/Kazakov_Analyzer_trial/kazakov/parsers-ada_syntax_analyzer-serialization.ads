--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Serialization                            Summer, 2026       --
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

with Ada.Streams;  use Ada.Streams;
with Ada.Text_IO;  use Ada.Text_IO;

package Parsers.Ada_Syntax_Analyzer.Serialization is
--
-- Restore -- Tree from a stream
--
--    Stream - The stream to read from
--    Pool   - The storage pool to allocate the tree
--    Offset - The offset incremented by the numer of read elements
--    Result - The result
--    Xref   - The cross reference to update
--    File   - The source descriptor
--    Trace  - The trace file
--    Prefix - The trace file prefix
--
-- Exceptions :
--
--    Constraint_Error - Invalid data
--
   procedure Restore
             (  Stream : in out Root_Stream_Type'Class;
                Pool   : in out Root_Storage_Pool'Class;
                Offset : in out Stream_Element_Offset;
                Result : out Tokens.Argument_Token;
                Xref   : Cross_Reference_Ptr    := null;
                File   : Source_Description_Ptr := null;
                Trace  : File_Access            := null;
                Prefix : String                 := ""
             );
--
-- Restore -- Tree from a stream
--
--    Stream - The stream to read from
--    Pool   - The storage pool to allocate the tree
--    Xref   - The cross reference to update
--    File   - The source descriptor
--    Trace  - The trace file
--    Prefix - The trace file prefix
--
-- Returns :
--
--    The result
--
-- Exceptions :
--
--    Constraint_Error - Invalid data
--
   function Restore
            (  Stream : access Root_Stream_Type'Class;
               Pool   : access Root_Storage_Pool'Class;
               Xref   : Cross_Reference_Ptr    := null;
               File   : Source_Description_Ptr := null;
               Trace  : File_Access            := null;
               Prefix : String                 := ""
            )  return Tokens.Argument_Token;
--
-- Store -- Tree into a stream
--
--    Stream - The stream to write to
--    Tree   - The tree to write
--    Offset - The offset incremented by the numer of written elements
--    Trace  - The trace file
--    Prefix - The trace file prefix
--
-- Exceptions :
--
--    Constraint_Error - Invalid data
--
   procedure Store
             (  Stream : in out Root_Stream_Type'Class;
                Tree   : Tokens.Argument_Token;
                Offset : in out Stream_Element_Offset;
                Trace  : File_Access := null;
                Prefix : String      := ""
             );
--
-- Store -- Tree into a stream
--
--    Stream - The stream to write to
--    Tree   - The tree to write
--    Trace  - The trace file
--    Prefix - The trace file prefix
--
-- Exceptions :
--
--    Constraint_Error - Invalid data
--
   procedure Store
             (  Stream : in out Root_Stream_Type'Class;
                Tree   : Tokens.Argument_Token;
                Trace  : File_Access := null;
                Prefix : String      := ""
             );
end Parsers.Ada_Syntax_Analyzer.Serialization;
