--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Sequence.Get_Case                    Spring, 2026       --
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
   function Get_Case return Node_Ptr is
   use Case_Alternatives_Stack;

   Default  : Statement_Sequence_Ref;
   Sequence : Statement_Sequence_Ref;
   Selector : Tokens.Argument_Token;
   Pair     : Case_Alternative;
   Count    : Natural := 0;
begin
   Lexers.Parse (Context, Code, Selector);
   if not Get ("is") then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'is' is expected at " & Image (Link (Code))
      );
   end if;
   if not Get ("when") then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'when' is expected at " & Image (Link (Code))
      );
   end if;
   loop
      if Get ("others") then
         if not Get ("=>", False) then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'=>' is expected after 'others' at " &
               Image (Link (Code))
            );
         end if;
         Get_Sequence
         (  Context   => Context,
            Code      => Code,
            File      => File,
            Parent    => Parent,
            Handled   => Handled and not Handled_Sequence,
            Enclosing => Enclosing,
            Keyword   => Keyword,
            Result    => Sequence
         );
         if Keyword /= End_Word then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'end case' is expected at " & Image (Link (Code))
            );
         end if;
         Default := Sequence;
         exit;
      end if;
      Get_Discrete_Choice_List (Context, Code, Pair.Choice);
      Pair.Value.Location := Link (Code);
      Get_Sequence
      (  Context   => Context,
         Code      => Code,
         File      => File,
         Parent    => Parent,
         Handled   => Handled and not Handled_Sequence,
         Enclosing => Enclosing,
         Keyword   => Keyword,
         Result    => Sequence
      );
      Pair.Value.Value    := Sequence.all'Unchecked_Access;
      Pair.Value.Location := Pair.Value.Location & Link (Code);
      Push (Context, Pair);
      Count := Count + 1;
      exit when Keyword = End_Word;
      if Keyword /= When_Word then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'end' or 'when' is expected at " & Image (Link (Code))
         );
      end if;
   end loop;
   if not Get ("case") then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'case' is expected after 'end' at " & Image (Link (Code))
      );
   end if;
   declare
      type Arena_Ptr is access Case_Statement;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Ptr  : constant Arena_Ptr :=
                  new Case_Statement
                      (  Labels_Count => Labels_Count,
                         Count        => Count
                      );
      This : Case_Statement renames Ptr.all;
   begin
      This.Selector := Selector;
      if Default /= null then
         This.Default :=
            Statement_Sequence (Default.all)'Unchecked_Access;
         Ref (This.Default).Outer := This'Unchecked_Access;
      end if;
      for Index in reverse This.Alternatives'Range loop
         Pop (Context, Pair);
         This.Alternatives (Index).Choice := Pair.Choice;
         This.Alternatives (Index).Code :=
            Statement_Sequence (Pair.Value.Value.all)'Unchecked_Access;
         Ref (This.Alternatives (Index).Code).Outer :=
            This'Unchecked_Access;
      end loop;
      Pop (Context, Parent, File, This, This.Labels);
      return This'Unchecked_Access;
   end;
end Get_Case;
