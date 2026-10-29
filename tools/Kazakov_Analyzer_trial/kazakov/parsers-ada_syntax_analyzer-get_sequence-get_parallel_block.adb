--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Sequence.Get_Parallel_Block          Spring, 2026       --
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
   function Get_Parallel_Block
            (  Parent        : Context_Location;
               Chunk         : Chunk_Specification_Ref;
               Aspects_Count : Natural
            )  return Node_Ptr is
   type Arena_Ptr is access Parallel_Block_Statement;
   for Arena_Ptr'Storage_Pool use Context.Pool.all;
   Ptr      : Arena_Ptr;
   Sequence : Statement_Sequence_Ref;
begin
   for Path in Positive'Range loop
      if Chunk /= null and then Chunk.Mode = Chunk_Parameter then
         Chunk.Name.Scope := Link (Code);
         Chunk.Name.File  := File;
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
      if Keyword = End_Word then
         if Path = 1 then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "The parallel block has only one sequence of  " &
               "statements as found at "                       &
               Image (Link (Code))
            );
         end if;
         if Chunk /= null and then Chunk.Mode = Chunk_Parameter then
            Add (Context, Chunk.Name, Before (Code), File);
         end if;
         if not Get ("do") then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'do' is expected after 'end' at " &
               Image (Link (Code))
            );
         end if;
         Ptr := new Parallel_Block_Statement
                    (  Labels_Count  => Labels_Count,
                       Paths_Count   => Path,
                       Aspects_Count => Aspects_Count
                    );
         exit;
      elsif Keyword /= And_Word then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'and' or 'end' is expected at " & Image (Link (Code))
         );
      end if;
   end loop;
   declare
      use Tokens.Arguments;
      This : Parallel_Block_Statement renames Ptr.all;
      List : Frame (1..1);
   begin
      if Chunk /= null then
         Chunk.Outer := This'Unchecked_Access;
         This.Chunk := Chunk.all'Unchecked_Access;
         if Chunk.Mode = Chunk_Parameter then
            Add (Context, Chunk.Name, Before (Code), File);
         end if;
      end if;
      for Index in reverse This.Paths'Range loop
         Pop (Context, List);
         This.Paths (Index) :=
            Statement_Sequence (List (1).Value.all)'Unchecked_Access;
         Statement_Sequence (Ref (List (1).Value).all).Outer :=
            This'Unchecked_Access;
      end loop;
      Pop (Context, This.Aspects);
      Pop (Context, Parent, File, This, This.Labels);
      return This'Unchecked_Access;
   end;
end Get_Parallel_Block;
