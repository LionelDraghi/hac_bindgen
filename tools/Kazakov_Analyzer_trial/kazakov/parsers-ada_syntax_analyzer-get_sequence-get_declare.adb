--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Sequence.Get_Declare                 Spring, 2026       --
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
   function Get_Declare (No_Declarations : Boolean) return Node_Ptr is
   Declarations : Declaration_Context_Ref;
   Private_Unit : Boolean;
   Keyword      : Reserved_Word;
   Sequence     : Statement_Sequence_Ref;
begin
   if not No_Declarations then
      Get_Context
      (  Context      => Context,
         Code         => Code,
         File         => File,
         Kind_Of      => Code_Block_Context,
         Parent       => Parent,
         Private_Unit => Private_Unit,
         Keyword      => Keyword,
         Result       => Declarations
      );
      if Keyword /= Begin_Word then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'begin' is expected at " & Image (Link (Code))
         );
      end if;
      Get_Sequence
      (  Context => Context,
         Code    => Code,
         File    => File,
         Parent  => Ref (Declarations),
         Handled => Handled or Handled_Sequence,
         Enclosing => Enclosing,
         Keyword => Keyword,
         Result  => Sequence
      );
      Add (Context, Declarations.all, Before (Code), File);
   else
      Get_Sequence
      (  Context   => Context,
         Code      => Code,
         File      => File,
         Parent    => Parent,
         Handled   => Handled or Handled_Sequence,
         Enclosing => Enclosing,
         Keyword   => Keyword,
         Result    => Sequence
      );
   end if;
   if Keyword /= End_Word then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'end' is expected at " & Image (Link (Code))
      );
   end if;
   Get_Blank (Context, Code);
   if Has_Identifier then
      if Has_Semicolon (Code) then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'"                            &
            Image (Identifier.Value.all)   &
            " is expected after 'end' at " &
            Image (Link (Code))
         );
      end if;
      Check (Context, Code, Identifier);
   end if;
   declare
      type Arena_Ptr is access Block_Statement;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Ptr  : constant Arena_Ptr :=
                  new Block_Statement
                      (  Labels_Count => Labels_Count,
                         Named        => Has_Identifier,
                         Sequence     => Handled_Statement_Sequence
                                         (  Sequence.all
                                         ) 'Access
                      );
      This : Block_Statement renames Ptr.all;
   begin
      Sequence.Outer := This'Unchecked_Access;
      if Has_Identifier then
         This.Name.Item := Identifier;
      end if;
      if Declarations /= null then
         This.Declarations := Declarations.all'Unchecked_Access;
      end if;
      Pop (Context, Parent, File, This, This.Labels);
      return This'Unchecked_Access;
   end;
end Get_Declare;
