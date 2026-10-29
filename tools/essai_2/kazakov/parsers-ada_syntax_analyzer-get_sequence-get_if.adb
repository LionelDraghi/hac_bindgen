--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Sequence.Get_If                      Spring, 2026       --
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
   function Get_If return Node_Ptr is
   Sequence  : Statement_Sequence_Ref;
   Condition : Tokens.Argument_Token;
   Count     : Positive := 1;
   Keyword   : Reserved_Word;
begin
   loop
      Lexers.Parse (Context, Code, Condition);
      Push (Context, Condition);
      if not Get ("then") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'then' is expected at " & Image (Link (Code))
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
      Push
      (  Context,
         Tokens.Argument_Token'
         (  Sequence.all'Unchecked_Access,
            Link (Code)
      )  );
      case Keyword is
         when Else_Word =>
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
            exit when Keyword = End_Word;
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'end if' is expected at " & Image (Link (Code))
            );
         when Elsif_Word =>
            Count := Count + 1;
         when End_Word =>
            Sequence := null;
            exit;
         when others =>
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'else', 'elsif' or 'end if' is expected at " &
               Image (Link (Code))
            );
      end case;
   end loop;
   if not Get ("if") then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'if' is expected after 'end' at " & Image (Link (Code))
      );
   end if;
   declare
      use Tokens.Arguments;
      type Arena_Ptr is access If_Statement;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Ptr  : constant Arena_Ptr :=
                  new If_Statement (Labels_Count, Count);
      This : If_Statement renames Ptr.all;
      List : Frame (1..2);
   begin
      if Sequence /= null then
         Sequence.Outer := This'Unchecked_Access;
         This.Default :=
            Statement_Sequence (Sequence.all)'Unchecked_Access;
      end if;
      for Index in reverse This.Alternatives'Range loop
         Pop (Context, List);
         This.Alternatives (Index).Guard := List (1);
         Statement_Sequence (Ref (List (2).Value).all).Outer :=
            This'Unchecked_Access;
         This.Alternatives (Index).Code :=
            Statement_Sequence (List (2).Value.all)'Access;
      end loop;
      Pop (Context, Parent, File, This, This.Labels);
      return This'Unchecked_Access;
   end;
end Get_If;
