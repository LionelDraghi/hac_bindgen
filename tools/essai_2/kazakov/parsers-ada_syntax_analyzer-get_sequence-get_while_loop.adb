--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Sequence.Get_While_Loop              Spring, 2026       --
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

separate (Parsers.Ada_Syntax_Analyzer.Get_Sequence)
   function Get_While_Loop return Node_Ptr is
   Condition : Tokens.Argument_Token;
begin
   Lexers.Parse (Context, Code, Condition);
   if not Get ("loop") then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'loop' is expected at " & Image (Link (Code))
      );
   end if;
   declare
      type Arena_Ptr is access While_Loop_Statement;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Result   : constant Arena_Ptr :=
                      new While_Loop_Statement
                          (  Labels_Count => Labels_Count,
                             Named        => Has_Identifier
                          );
      Sequence : Unhandled_Statement_Sequence_Ref;
      This     : While_Loop_Statement renames Result.all;
   begin
      if This.Named then
         This.Name.Item := Identifier;
      end if;
      Sequence := Get_Loop_Body (Parent, This'Unchecked_Access);
      Sequence.Outer := This'Unchecked_Access;
      This.Sequence  := Sequence.all'Unchecked_Access;
      This.Condition := Condition;
      Pop (Context, Parent, File, This, This.Labels);
      return This'Unchecked_Access;
   end;
end Get_While_Loop;
