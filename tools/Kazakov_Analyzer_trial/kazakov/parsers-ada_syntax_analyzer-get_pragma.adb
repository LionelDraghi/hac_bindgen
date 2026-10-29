--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Pragma                               Spring, 2026       --
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
   procedure Get_Pragma
             (  Context : in out Ada_Program;
                Code    : in out Source'Class;
                Result  : out Tokens.Argument_Token
             )  is
   use Pragma_Argument_Association_Stack;
   type Arena_Ptr is access Pragma_Clause;
   for Arena_Ptr'Storage_Pool use Context.Pool.all;

   procedure Create (Argument, Value : Tokens.Argument_Token) is
   begin
      if Argument.Value.all in Expression then
         declare
            This : Expression renames Expression (Argument.Value.all);
         begin
            if This.Operation = Attribute then
               if not Is_Class (This.Operands (2)) then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'Class attribute is expected in the pragma " &
                     " argument aspect mark at "                   &
                     Image (This.Operands (2).Location)
                  );
               end if;
            else
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Identifier or aspect mark is expected as " &
                  "a pragma argument at "                     &
                  Image (Argument.Location)
               );
            end if;
         end;
      elsif Argument.Value.all not in Identifier then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Identifier or aspect mark is expected as " &
            "a pragma argument at "                     &
            Image (Argument.Location)
         );
      end if;
      Push
      (  Context,
         Pragma_Argument_Association'
         (  Named    => True,
            Argument => (Present => True, Item => Argument),
            Value    => Value
      )  );
   end Create;

   procedure Create (Value : Tokens.Argument_Token) is
   begin
      Push
      (  Context,
         Pragma_Argument_Association'
         (  Named    => False,
            Argument => (Present => False),
            Value    => Value
      )  );
   end Create;

   Start  : constant Location := Before (Code);
   Name   : Tokens.Argument_Token;
   Ptr    : Arena_Ptr;
   Got_It : Boolean;
begin
   Get_Blank (Context, Code);
   Get_Simple_Name (Context, Code, True, Name);
   Get_Blank (Context, Code);
   Get_Delimited (Code, "(", False, Got_It);
   if Got_It then
      declare
         Open_At  : constant Location := Link (Code);
         Count    : Positive := 1;
      begin
         --
         -- The syntax of pragma is
         --
         --    <pragma> ::= pragma <identifier> [{<list>)]
         --    <list>   ::= <pragma_argument_association> [,<list>]
         --
         -- This allows
         --
         --    pragma <identifier> (<expression>)
         --
         -- which in turn allows if-expressions et al. This why we parse
         -- with an left parenthesis taken. This will either  result  in
         -- an   expression   like  if-expression  or  into  a  list  of
         -- associations.
         --
         --    pragma Assert
         --       (for some X in 2..N when X * X <= N => N mod X = 0);
         --
         -- is legal.
         --
         Lexers.Parse
         (  Context => Context,
            Code    => Code,
            Left    => (Left_Bracket, Open_At),
            Result  => Result
         );
         if Result.Value.all in Expression then
            declare
               Associations : Expression renames
                              Expression (Result.Value.all);
               List : Argument_List renames Associations.Operands;
            begin
               case Associations.Operation is
                  when Left_Bracket =>
                     Count := Associations.Count;
                     for Index in List'Range loop
                        if List (Index).Value.all in Expression then
                           declare
                              Item : Expression renames
                                     Expression (List (Index).Value.all);
                           begin
                              if Item.Operation = Associate then
                                 Create
                                 (  Item.Operands (1),
                                    Item.Operands (2)
                                 );
                              else
                                 Create (List (Index));
                              end if;
                           end;
                        else
                           Create (List (Index));
                        end if;
                     end loop;
                  when others =>
                     Create (Result);
               end case;
            end;
         else
            Create (Result);
         end if;
         Get_Semicolon (Context, Code);
         Result.Location := Start & Link (Code);
         Ptr := new Pragma_Clause (Count);
         declare
            This  : Pragma_Clause renames Ptr.all;
         begin
            This.Location := Result.Location;
            This.Name     := Name;
            for Index in reverse This.Associations'Range loop
               Pop (Context, This.Associations (Index));
            end loop;
         end;
      end;
   else
      Get_Semicolon (Context, Code);
      Result.Location := Start & Link (Code);
      Ptr := new Pragma_Clause (0);
      Ptr.Name := Name;
      Ptr.Location := Result.Location;
   end if;
   Result.Value := Ptr.all'Unchecked_Access;
end Get_Pragma;
