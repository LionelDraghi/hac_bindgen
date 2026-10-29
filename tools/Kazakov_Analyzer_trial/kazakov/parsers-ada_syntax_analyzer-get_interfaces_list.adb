--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Interfaces_List                      Spring, 2026       --
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

separate (Parsers.Ada_Syntax_Analyzer)
   function Get_Interfaces_List
            (  Context : access Ada_Program;
               Code    : access Source'Class;
               Prefix  : String
            )  return Natural is
   use Subtype_Mark_Stack;

   Program : Ada_Program  renames Context.all;
   Input   : Source'Class renames Code.all;
   Name    : Subtype_Mark;
   Length  : Positive := 1;
   Got_It  : Boolean;
begin
   if Prefix'Length /= 0 then
      Get_Blank (Program, Input);
      Get_Delimited (Input, Prefix, True, Got_It);
      if not Got_It then
         return 0;
      end if;
   end if;
   loop
      Get_Subtype_Mark (Program, Input, True, False, Name);
      Push (Program, Name);
      Get_Blank (Program, Input);
      Get_Delimited (Input, "and", True, Got_It);
      exit when not Got_It;
      Length := Length + 1;
   end loop;
   return Length;
end Get_Interfaces_List;
