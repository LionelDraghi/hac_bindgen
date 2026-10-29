--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Use                                  Spring, 2026       --
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

separate (Parsers.Ada_Syntax_Analyzer.Get_Context)
   function Get_Use return Tokens.Argument_Token is
   Start        : constant Location := Before (Code);
   Length       : Positive := 1;
   Type_Use     : Boolean  := False;
   All_Type_Use : Boolean  := False;
   Result       : Tokens.Argument_Token;
   Ptr          : Use_Clause_Ref;
begin
   if Get ("all") then
      if not Get ("type") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'type' is expected after " &
            "'use all' at "             &
            Image (Link (Code))
         );
      end if;
      All_Type_Use := True;
      Type_Use     := True;
   elsif Get ("type") then
      Type_Use := True;
   end if;
   loop
      Get_Expanded_Name (Context, Code, True, Result);
      Push (Context, Result);
      exit when not Get (",", False);
      Length := Length + 1;
   end loop;
   if Type_Use then
      Ptr := new Use_Type_Clause (All_Type_Use, Length);
   else
      Ptr := new Use_Package_Clause (Length);
   end if;
   Pop (Context, Ptr.List);
   if Last_Use_Clause /= null then
      Ptr.Previous  := Last_Use_Clause.all'Unchecked_Access;
   end if;
   Ptr.Enclosing   := Enclosing;
   Last_Use_Clause := Ptr;
   Result.Value := Ptr.all'Unchecked_Access;
   Get_Semicolon (Context, Code);
   Result.Location := Start & Link (Code);
   Ptr.Location    := Result.Location;
   return Result;
end Get_Use;
