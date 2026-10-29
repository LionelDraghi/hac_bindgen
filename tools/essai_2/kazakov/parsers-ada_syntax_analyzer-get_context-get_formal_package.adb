--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Context.Get_Formal_Package           Spring, 2026       --
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

with Parsers.Ada_Syntax_Analyzer.Declarations.Formal_Parameters;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Formal_Parameters;

separate (Parsers.Ada_Syntax_Analyzer.Get_Context)
   function Get_Formal_Package return Tokens.Argument_Token is

   Result : Tokens.Argument_Token;
   Name   : Tokens.Argument_Token;
   Target : Tokens.Argument_Token;
begin
   Result.Location := Before (Code);
   Get_Simple_Name (Context, Code, True, Name);
   if not Get ("is") then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'is' is expected at " & Image (Link (Code))
      );
   end if;
   if not Get ("new") then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'new' is expected after 'is' at " & Image (Link (Code))
      );
   end if;
   Lexers.Parse (Context, Code, Target);
   Check_Name (Target);
   declare
      type Arena_Ptr is access Formal_Package_Parameter;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Ptr  : constant Arena_Ptr :=
                  new Formal_Package_Parameter (Get_Aspects_Count);
      This : Formal_Package_Parameter renames Ptr.all;
   begin
      Set (Context, Name, Enclosing, File, This, This.Name'Access);
      This.Target := Target;
      Pop (Context, This.Aspects);
      Get_Semicolon (Context, Code);
      Result.Value    := This'Unchecked_Access;
      Result.Location := Result.Location & Link (Code);
      This.Location   := Result.Location;
   end;
   return Result;
end Get_Formal_Package;
