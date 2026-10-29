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
   Name   : Tokens.Argument_Token;
   Got_It : Boolean;
begin
   Length := 1;
   Get_Blank (Context, Code);
   Get_Delimited (Code, Prefix, True, Got_It);
   if Got_It then
      loop
         Get_Name (Context, Code, True, Name);
         Push (Context, Name);
         Get_Blank (Context, Code);
         Get_Delimited (Code, "and", True, Got_It);
         exit when not Got_It;
         Length := Length + 1;
      end loop;
      Get_Delimited (Code, "with", True, Got_It);
      if not Got_It then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'and' or 'with' is expected at " &
            Image (Link (Code))
         );
      end if;
   end if;
end Get_Interfaces_List;
