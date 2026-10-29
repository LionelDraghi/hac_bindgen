--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Sequence                             Spring, 2026       --
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
   procedure Get_Sequence
             (  Context   : in out Ada_Program;
                Code      : in out Source'Class;
                File      : Source_Description_Ptr;
                Parent    : Context_Location;
                Handled   : Sequence_Type;
                Enclosing : Loop_Body_Ptr;
                Keyword   : out Reserved_Word;
                Result    : out Statement_Sequence_Ref
             )  is
   use type Ada.Text_IO.File_Access;

   type Node_Ref is access Node'Class;
   function Ref is new Ada.Unchecked_Conversion (Node_Ptr, Node_Ref);

   type Unhandled_Statement_Sequence_Ref is
      access all Statement_Sequence;
   function Ref is new Ada.Unchecked_Conversion
                       (  Unhandled_Statement_Sequence_Ptr,
                          Unhandled_Statement_Sequence_Ref
                       );

   type Call_Statement_Ptr is access constant Call_Statement;
   type Trigger_Node_Ptr   is access constant Trigger_Node'Class;

   function Get (Text : String; Delimited : Boolean := True)
      return Boolean is
      pragma Inline (Get);
      Got_It : Boolean;
   begin
      Get_Blank (Context, Code);
      Get_Delimited (Code, Text, Delimited, Got_It);
      return Got_It;
   end Get;

   function Get_Aspects_Count return Natural is
      Count  : Natural := 0;
   begin
      if Get ("with") then
         Get_Blank (Context, Code);
         Get_Aspect (Context, Code, Count);
      end if;
      return Count;
   end Get_Aspects_Count;

   Has_Identifier : Boolean;
   Labels_Count   : Natural;
   Identifier     : Tokens.Argument_Token;
   Start          : Location;

   function Get_Loop_Body
            (  Parent    : Context_Location;
               Statement : Loop_Statement_Ptr;
               Chunk     : Chunk_Specification_Ref := null;
               For_Loop  : Compilation_Context_Ref := null
            )  return Unhandled_Statement_Sequence_Ref is
      Keyword   : Reserved_Word;
      Sequence  : Statement_Sequence_Ref;
      Loop_Data : aliased Loop_Body :=
                          (  Enclosing  => Enclosing,
                             Statement  => Statement
                          );
   begin
      if For_Loop /= null then
         For_Loop.Scope := Link (Code);
         For_Loop.File  := File;
      end if;
      Get_Sequence
      (  Context   => Context,
         Code      => Code,
         File      => File,
         Parent    => Parent,
         Handled   => Handled and not Handled_Sequence,
         Enclosing => Loop_Data'Unchecked_Access,
         Keyword   => Keyword,
         Result    => Sequence
      );
      if Keyword /= End_Word then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'end loop' is expected at " & Image (Link (Code))
         );
      end if;
      if For_Loop /= null then
         declare
            Ends : constant Location := Before (Code);
         begin
            if Chunk /= null and then Chunk.Mode = Chunk_Parameter then
               Add (Context, Chunk.Name, Ends, File);
            end if;
            Add (Context, For_Loop.all, Ends, File);
         end;
      end if;
      if not Get ("loop") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'loop' is expected after 'end' at " & Image (Link (Code))
         );
      end if;
      if Has_Identifier then
         if Has_Semicolon (Code) then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Loop label '"               &
               Image (Identifier.Value.all) &
               "' is expected at "          &
               Image (Link (Code))
            );
         end if;
         Check (Context, Code, Identifier);
      end if;
      return Statement_Sequence (Sequence.all)'Unchecked_Access;
   end Get_Loop_Body;

   procedure Get_Parallel_Chunk
             (  Parent : in out Context_Location;
                Chunk  : out Chunk_Specification_Ref
             )  is separate;

   function Get_Accept return Accept_Statement_Ptr     is separate;
   function Get_Parallel_Block
            (  Parent        : Context_Location;
               Chunk         : Chunk_Specification_Ref;
               Aspects_Count : Natural
            )  return Node_Ptr                         is separate;
   function Get_Call
            (  Expression : Tokens.Argument_Token
            )   return Call_Statement_Ptr              is separate;
   function Get_Case        return Node_Ptr            is separate;
   function Get_Declare
            (  No_Declarations : Boolean
            )  return Node_Ptr                         is separate;
   function Get_Delay       return Delay_Statement_Ptr is separate;
   function Get_Exception   return Positive is separate;
   function Get_For_Loop
            (  Parent        : Context_Location;
               Chunk         : Chunk_Specification_Ref := null;
               Aspects_Count : Natural                 := 0
            )  return Node_Ptr                         is separate;
   function Get_Exit        return Node_Ptr            is separate;
   function Get_If          return Node_Ptr            is separate;
   function Get_Loop        return Node_Ptr            is separate;
   function Get_Return      return Node_Ptr            is separate;
   function Get_Select      return Node_Ptr            is separate;
   function Get_While_Loop  return Node_Ptr            is separate;

   Where          : constant Location := Link (Code);
   Handlers_Count : Natural := 0;
   Length         : Natural := 0;
   Statement      : Node_Ptr;
begin
   loop
      Labels_Count := 0;
      while Get ("<<", False) loop
         Get_Simple_Name (Context, Code, True, Identifier);
         if not Get (">>", False) then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'>>' is expected at " & Image (Link (Code))
            );
         end if;
         Push (Context, Identifier);
         Labels_Count := Labels_Count + 1;
         Get_Blank (Context, Code);
      end loop;
      Start := Link (Code);
      Get_Reserved_Word (Code, Keyword);
      if Context.Trace /= null then
         Parsers.Multiline_Source.Location_Text_IO.Put_Line
         (  Code    => Code,
            File    => Context.Trace.all,
            Message => " ---sequence---------------" &
                       Reserved_Word'Image (Keyword) &
                       Natural'Image (Get_Arguments_Count (Context))
         );
      end if;
      case Keyword is
         when Abort_Word =>
            declare
               Count : Positive := 1;
               Name  : Tokens.Argument_Token;
            begin
               loop
                  Get_Expanded_Name (Context, Code, True, Name);
                  Push (Context, Name);
                  exit when not Get (",");
                  Count := Count + 1;
               end loop;
               declare
                  type Arena_Ptr is access Abort_Statement;
                  for Arena_Ptr'Storage_Pool use Context.Pool.all;
                  Ptr  : constant Arena_Ptr :=
                              new Abort_Statement (Labels_Count, Count);
                  This : Abort_Statement renames Ptr.all;
               begin
                  Pop (Context, This.Tasks);
                  Pop (Context, Parent, File, This, This.Labels);
                  Statement := This'Unchecked_Access;
               end;
            end;
         when Accept_Word =>
            Statement := Get_Accept.all'Unchecked_Access;
         when And_Word | Else_Word | Elsif_Word |
              Or_Word  | Then_Word | When_Word  =>
            if 0 /= (Handled and Handled_Sequence) then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'"                   &
                  Image (Keyword)       &
                  "' is unexpected at " &
                  Image (Link (Code))
               );
            end if;
            exit when Length > 0;
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "A statement is expected before '" &
               Image (Keyword)                    &
               "' at "                            &
               Image (Link (Code))
            );
         when Begin_Word =>
            Has_Identifier := False;
            Statement := Get_Declare (True);
         when Case_Word =>
            Statement := Get_Case;
         when Declare_Word =>
            Has_Identifier := False;
            Statement := Get_Declare (False);
         when Delay_Word =>
            Statement := Get_Delay.all'Unchecked_Access;
         when End_Word =>
            exit when Length > 0;
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "A statement is expected before 'end' at " &
               Image (Link (Code))
            );
         when Exception_Word =>
            if 0 = (Handled and Handled_Sequence) or else
               Handlers_Count > 0
            then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'exception' is unexpected at " & Image (Link (Code))
               );
            elsif not Get ("when") then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'when' is expected after 'exception' at " &
                  Image (Link (Code))
               );
            end if;
            Handlers_Count := Get_Exception;
            exit;
         when Exit_Word =>
            Statement := Get_Exit;
         when For_Word =>
            Has_Identifier := False;
            Statement := Get_For_Loop (Parent);
         when Goto_Word =>
            declare
               Name : Tokens.Argument_Token;
            begin
               Get_Simple_Name (Context, Code, False, Name);
               declare
                  type Arena_Ptr is access Goto_Statement;
                  for Arena_Ptr'Storage_Pool use Context.Pool.all;
                  Ptr  : constant Arena_Ptr :=
                              new Goto_Statement (Labels_Count);
                  This : Goto_Statement renames Ptr.all;
               begin
                  This.Name := Name;
                  Pop (Context, Parent, File, This, This.Labels);
                  Statement := This'Unchecked_Access;
               end;
            end;
         when If_Word =>
            Statement := Get_If;
         when Loop_Word =>
            Has_Identifier  := False;
            Statement := Get_Loop;
         when No_Reserved_Word => -- Assignment, code, call, identifier
            Lexers.Parse (Context, Code, Identifier);
            if Get (":=", False) then
               declare
                  Left : Node'Class renames Identifier.Value.all;
               begin
                  if Left in Expression then
                     declare
                        This : Expression renames Expression (Left);
                     begin
                        case This.Operation is
                           when Left_Index | Component =>
                              null;
                           when Attribute =>
                              Raise_Exception
                              (  Parsers.Syntax_Error'Identity,
                                 "Left part of assignment cannot be " &
                                 "an attribute as found at "          &
                                 Image (This.Location)
                              );
                           when others =>
                              Raise_Exception
                              (  Parsers.Syntax_Error'Identity,
                                 "Left part of assignment cannot be " &
                                 "an expression as found at "         &
                                 Image (Identifier.Location)
                              );
                        end case;
                     end;
                  elsif Left in Ada_Expression_Parser.Identifier then
                     null;
                  else
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "A variable name is expected at " &
                        Image (Identifier.Location)
                     );
                  end if;
               end;
               declare
                  Expression : Tokens.Argument_Token;
               begin
                  Lexers.Parse (Context, Code, Expression);
                  declare
                     type Arena_Ptr is access Assignment_Statement;
                     for Arena_Ptr'Storage_Pool
                        use Context.Pool.all;
                     Ptr  : constant Arena_Ptr :=
                                 new Assignment_Statement
                                     (  Labels_Count
                                     );
                     This : Assignment_Statement renames Ptr.all;
                  begin
                     This.Variable   := Identifier;
                     This.Expression := Expression;
                     Pop (Context, Parent, File, This, This.Labels);
                     Statement := This'Unchecked_Access;
                  end;
               end;
            elsif Get (":", False) then
               Check_Identifier (Identifier);
               Get_Blank (Context, Code);
               Get_Reserved_Word (Code, Keyword);
               Has_Identifier := True;
               case Keyword is
                  when Declare_Word =>
                     Statement := Get_Declare (False);
                  when Begin_Word =>
                     Statement := Get_Declare (True);
                  when For_Word =>
                     Statement := Get_For_Loop (Parent);
                  when Loop_Word =>
                     Statement := Get_Loop;
                  when Parallel_Word =>
                     declare
                        Enclosing     : Context_Location := Parent;
                        Aspects_Count : Natural;
                        Chunk         : Chunk_Specification_Ref;
                     begin
                        Get_Parallel_Chunk (Enclosing, Chunk);
                        Aspects_Count := Get_Aspects_Count;
                        Get_Blank (Context, Code);
                        Get_Reserved_Word (Code, Keyword);
                        case Keyword is
                           when For_Word =>
                              Statement :=
                                 Get_For_Loop
                                 (  Parent        => Enclosing,
                                    Chunk         => Chunk,
                                    Aspects_Count => Aspects_Count
                                 );
                           when Do_Word =>
                              Statement :=
                                 Get_Parallel_Block
                                 (  Parent        => Enclosing,
                                    Chunk         => Chunk,
                                    Aspects_Count => Aspects_Count
                                 );
                           when others =>
                              Raise_Exception
                              (  Parsers.Syntax_Error'Identity,
                                 "'for' or 'do' is expected after " &
                                 "'parallel' at "                   &
                                 Image (Link (Code))
                              );
                        end case;
                     end;
                  when While_Word =>
                     Statement := Get_While_Loop;
                  when No_Reserved_Word =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'declare', 'begin', 'loop', 'parallel' or " &
                        "'while' is expected at "                    &
                        Image (Link (Code))
                     );
                  when others =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "Unexpected '"                    &
                        Image (Keyword)                   &
                        "' is found after identifier at " &
                        Image (Link (Code))
                     );
               end case;
            elsif Has_Semicolon (Code) then
               Statement := Get_Call (Identifier).all'Unchecked_Access;
            elsif Identifier.Value.all in Literal'Class then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "A statement is expected yet a literal is found at " &
                  Image (Identifier.Location)
               );
            else
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "';', ':' or ':=' is expected at " &
                  Image (Link (Code))
               );
            end if;
         when Null_Word =>
            declare
               type Arena_Ptr is access Null_Statement;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr  : constant Arena_Ptr :=
                           new Null_Statement (Labels_Count);
               This : Null_Statement renames Ptr.all;
            begin
               Pop (Context, Parent, File, This, This.Labels);
               Statement := This'Unchecked_Access;
            end;
         when Parallel_Word =>
            Has_Identifier := False;
            declare
               Enclosing     : Context_Location := Parent;
               Aspects_Count : Natural;
               Chunk         : Chunk_Specification_Ref;
            begin
               Get_Parallel_Chunk (Enclosing, Chunk);
               Aspects_Count := Get_Aspects_Count;
               Get_Blank (Context, Code);
               Get_Reserved_Word (Code, Keyword);
               case Keyword is
                  when For_Word =>
                     Statement :=
                        Get_For_Loop
                        (  Parent        => Enclosing,
                           Chunk         => Chunk,
                           Aspects_Count => Aspects_Count
                        );
                  when Do_Word =>
                     Statement :=
                        Get_Parallel_Block
                        (  Parent        => Enclosing,
                           Chunk         => Chunk,
                           Aspects_Count => Aspects_Count
                        );
                  when others =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'for' or 'do' is expected after " &
                        "'parallel' at "                   &
                        Image (Link (Code))
                     );
               end case;
            end;
         when Raise_Word =>
            declare
               Name     : Tokens.Argument_Token;
               Raise_At : constant Location := Link (Code);
            begin
               Get_Blank (Context, Code);
               if Has_Semicolon (Code) then
                  if 0 = (Handled and Handler_Sequence) then
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "Re-raise statement is specified outside an " &
                        "exception handler at "                       &
                        Image (Raise_At)
                     );
                  end if;
                  declare
                     type Arena_Ptr is access Raise_Statement;
                     for Arena_Ptr'Storage_Pool use Context.Pool.all;
                     Ptr  : constant Arena_Ptr :=
                                 new Raise_Statement
                                     (  Labels_Count,
                                        True,
                                        False
                                    );
                     This : Raise_Statement renames Ptr.all;
                  begin
                     Pop (Context, Parent, File, This, This.Labels);
                     Statement := This'Unchecked_Access;
                  end;
               else
                  Get_Expanded_Name (Context, Code, True, Name);
                  declare
                     type Arena_Ptr is access Raise_Statement;
                     for Arena_Ptr'Storage_Pool use Context.Pool.all;
                     Ptr  : constant Arena_Ptr :=
                                 new Raise_Statement
                                     (  Labels_Count,
                                        False,
                                        Get ("with")
                                    );
                     This : Raise_Statement renames Ptr.all;
                  begin
                     if This.Has_Text then
                        Lexers.Parse (Context, Code, This.Text.Item);
                     end if;
                     This.Name := Name;
                     Pop (Context, Parent, File, This, This.Labels);
                     Statement := This'Unchecked_Access;
                  end;
               end if;
            end;
         when Requeue_Word =>
            declare
               Name : Tokens.Argument_Token;
            begin
               if 0 = (Handled and Action_Sequence) then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Requeue statement is specified in a body " &
                     "that is neither an entry or an accept "    &
                     "statement  at "                            &
                     Image (Link (Code))
                  );
               end if;
               Lexers.Parse (Context, Code, Name);
               declare
                  type Arena_Ptr is access Requeue_Statement;
                  for Arena_Ptr'Storage_Pool use Context.Pool.all;
                  Ptr  : constant Arena_Ptr :=
                              new Requeue_Statement
                                  (  Labels_Count,
                                     Get ("with")
                                  );
                  This : Requeue_Statement renames Ptr.all;
               begin
                  if This.With_Abort and then not Get ("abort") then
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'abort' is expected after 'with' at " &
                        Image (Link (Code))
                     );
                  end if;
                  This.Name := Name;
                  Pop (Context, Parent, File, This, This.Labels);
                  Statement := This'Unchecked_Access;
               end;
            end;
         when Return_Word =>
            Statement := Get_Return;
         when Select_Word =>
            Statement := Get_Select;
         when While_Word =>
            Has_Identifier := False;
            Statement := Get_While_Loop;
         when others =>
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "A statement is expected, '" &
               Image (Keyword)              &
               "' is found instead at "     &
               Image (Link (Code))
            );
      end case;
      Get_Semicolon (Context, Code);
      Push
      (  Context,
         Tokens.Argument_Token'(Statement, Start & Link (Code))
      );
      Length := Length + 1;
   end loop;
   if 0 /= (Handled and Handled_Sequence) then
      declare
         use Tokens.Arguments;

         type Arena_Ptr is access Handled_Statement_Sequence;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Ptr  : constant Arena_Ptr :=
                     new Handled_Statement_Sequence
                         (  Labels_Count   => Labels_Count,
                            Length         => Length,
                            Handlers_Count => Handlers_Count
                         );
         This : Handled_Statement_Sequence renames Ptr.all;
         List : Frame (1..1);
      begin
         for Index in reverse This.Handlers'Range loop
            Pop (Context, List);
            declare
               Handler : Exception_Handler renames
                         Exception_Handler (Ref (List (1).Value).all);
            begin
               This.Handlers (Index) := Handler'Unchecked_Access;
               Handler.Outer := This'Unchecked_Access;
            end;
         end loop;
         This.Context := Parent;
         Pop (Context, Parent, File, This, This.Labels);
         for Index in reverse This.List'Range loop
            Pop (Context, List);
            declare
               Item : Abstract_Statement_Node'Class renames
                      Abstract_Statement_Node'Class
                      (  Ref (List (1).Value).all
                      );
            begin
               Item.Location      := List (1).Location;
               Item.Path.Sequence := This'Unchecked_Access;
               Item.Path.Position := Index;
               This.List (Index)  := Item'Unchecked_Access;
            end;
         end loop;
         This.Location := Where & Link (Code);
         Result := This'Unchecked_Access;
      end;
   else
      declare
         use Tokens.Arguments;
         type Arena_Ptr is access Statement_Sequence;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Ptr   : constant Arena_Ptr :=
                      new Statement_Sequence
                          (  Labels_Count => Labels_Count,
                             Length       => Length
                          );
         This : Statement_Sequence renames Ptr.all;
         List : Frame (1..1);
      begin
         This.Context := Parent;
         Pop (Context, Parent, File, This, This.Labels);
         for Index in reverse This.List'Range loop
            Pop (Context, List);
            declare
               Item : Abstract_Statement_Node'Class renames
                      Abstract_Statement_Node'Class
                      (  Ref (List (1).Value).all
                      );
            begin
               Item.Location      := List (1).Location;
               Item.Path.Sequence := This'Unchecked_Access;
               Item.Path.Position := Index;
               This.List (Index)  := Item'Unchecked_Access;
            end;
         end loop;
         This.Location := Where & Link (Code);
         Result := This'Unchecked_Access;
      end;
   end if;
end Get_Sequence;
