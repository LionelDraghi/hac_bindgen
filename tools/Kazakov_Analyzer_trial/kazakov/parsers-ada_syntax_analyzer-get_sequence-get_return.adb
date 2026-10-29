--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Sequence.Get_Return                  Spring, 2026       --
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
   function Get_Return return Node_Ptr is
   Return_At : constant Location := Link (Code);
   Name      : Tokens.Argument_Token;
begin
   Get_Blank (Context, Code);
   if Has_Semicolon (Code) then
      if 0 = (Handled and Procedure_Sequence) then
         Raise_Exception
         (  Syntax_Error'Identity,
            "The return statement appears outside a procedure or " &
            "entry body "                                          &
            Image (Return_At)
         );
      end if;
      declare
         type Arena_Ptr is access Simple_Return_Statement;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Result : constant Arena_Ptr :=
                       new Simple_Return_Statement
                           (  Labels_Count,
                              False
                           );
         This   : Simple_Return_Statement renames Result.all;
      begin
         Pop (Context, Parent, File, This, This.Labels);
         return This'Unchecked_Access;
      end;
   else
      if 0 = (Handled and Function_Sequence) then
         Raise_Exception
         (  Syntax_Error'Identity,
            "The return statement appears outside a function body at " &
            Image (Return_At)
         );
      end if;
      Lexers.Parse (Context, Code, Name);
      if not Get (":=", False) and then Get (":", False) then
         Check_Identifier (Name);
         declare
            Keyword         : Reserved_Word;
            Aliased_Result  : constant Boolean := Get ("aliased");
            Constant_Result : constant Boolean := Get ("constant");
            Initialized     : Boolean;
            Initial         : Tokens.Argument_Token;
            Sequence        : Statement_Sequence_Ref;
            Type_Of         : Parameter_Type;
         begin
            Type_Of := Get_Parameter_Type
                       (  Context            => Context'Access,
                          Code               => Code'Access,
                          File               => File,
                          Parent             => Parent,
                          Composite          => True,
                          Aliased_Parameter  => Aliased_Result,
                          Constant_Parameter => Constant_Result
                       );
            Initialized := Get (":=", False);
            if Initialized then
               Lexers.Parse (Context, Code, Initial);
            end if;
            declare
               type Arena_Ptr is access Extended_Return_Statement;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Result : constant Arena_Ptr :=
                             new Extended_Return_Statement
                                 (  Labels_Count => Labels_Count,
                                    Initialized  => Initialized
                                 );
               This   : Extended_Return_Statement renames Result.all;
            begin
               if This.Initialized then
                  This.Initial.Item := Initial;
               end if;
               Set
               (  Context  => Context,
                  Name     => Name,
                  Location => Ref (This.Result'Access, False),
                  File     => File,
                  Node     => This,
                  Item     => This.Result.Name'Access
               );
               This.Result.Parent   := Parent;
               This.Result.Location := Name.Location;
               This.Result.Type_Of := Type_Of;
               if Get ("do") then
                  This.Result.Scope := Link (Code);
                  This.Result.File  := File;
                  Get_Sequence
                  (  Context   => Context,
                     Code      => Code,
                     File      => File,
                     Parent    => Ref (This.Result'Access),
                     Handled   => Handled or Handled_Sequence,
                     Enclosing => Enclosing,
                     Keyword   => Keyword,
                     Result    => Sequence
                  );
                  if Keyword /= End_Word then
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'end' is expected at " & Image (Link (Code))
                     );
                  end if;
                  Add (Context, This.Result, Before (Code), File);
                  if not Get ("return") then
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'return' is expected after 'end' at " &
                        Image (Link (Code))
                     );
                  end if;
                  if Sequence /= null then
                     Sequence.Outer := This'Unchecked_Access;
                     This.Code :=
                        Handled_Statement_Sequence
                        (  Sequence.all
                        ) 'Access;
                  end if;
               end if;
               Pop (Context, Parent, File, This, This.Labels);
               return This'Unchecked_Access;
            end;
         end;
      else
         declare
            type Arena_Ptr is access Simple_Return_Statement;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Result : constant Arena_Ptr :=
                          new Simple_Return_Statement
                              (  Labels_Count,
                                 True
                              );
            This   : Simple_Return_Statement renames Result.all;
         begin
            This.Result.Item := Name;
            Pop (Context, Parent, File, This, This.Labels);
            return This'Unchecked_Access;
         end;
      end if;
   end if;
end Get_Return;
