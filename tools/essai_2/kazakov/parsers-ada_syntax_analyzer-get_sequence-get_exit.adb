--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Sequence.Get_Exit                    Spring, 2026       --
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
   function Get_Exit return Node_Ptr is
   type Arena_Ptr is access Exit_Statement;
   for Arena_Ptr'Storage_Pool use Context.Pool.all;
   Result    : Arena_Ptr;
   Condition : Tokens.Argument_Token;
   Name      : Tokens.Argument_Token;
begin
   if Enclosing = null then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'exit' ouside any loop is found at " &
         Image (Link (Code))
      );
   end if;
   if Get ("when") then
      Lexers.Parse (Context, Code, Condition);
      Result :=
         new Exit_Statement
             (  Labels_Count => Labels_Count,
                Named        => False,
                Conditional  => True
             );
   elsif Has_Semicolon (Code) then
      Result :=
         new Exit_Statement
             (  Labels_Count => Labels_Count,
                Named        => False,
                Conditional  => False
             );
   else
      Get_Simple_Name (Context, Code, True, Name);
      if Get ("when") then
         Lexers.Parse (Context, Code, Condition);
         Result :=
            new Exit_Statement
                (  Labels_Count => Labels_Count,
                   Named        => True,
                   Conditional  => True
                );
      else
         Result :=
            new Exit_Statement
                (  Labels_Count => Labels_Count,
                   Named        => True,
                   Conditional  => False
                );
      end if;
   end if;
   declare
      This : Exit_Statement renames Result.all;
   begin
      if This.Named then
         This.Loop_Name.Item := Name;
         declare
            That  : Loop_Body_Ptr := Enclosing;
            Value : String renames
                      Named_Term'Class (Name.Value.all).Value;
         begin
            loop
               if That = null then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "There is no loop with the label '"  &
                     Value                                &
                     "' enclosing the exit statement at " &
                     Image (Start & Link (Code))
                  );
               end if;
               if That.Statement.Named and then
                  (  Equal
                  =  Compare
                     (  Named_Term'Class
                        (  That.Statement.Name.Item.Value.all
                        ) .Value,
                        Value
                  )  )
               then
                  This.Loop_Of := That.Statement;
                  exit;
               end if;
               That := That.Enclosing;
            end loop;
         end;
      else
         This.Loop_Of := Enclosing.Statement;
      end if;
      if This.Conditional then
         This.Condition.Item := Condition;
      end if;
      Pop (Context, Parent, File, This, This.Labels);
      return This'Unchecked_Access;
   end;
end Get_Exit;
