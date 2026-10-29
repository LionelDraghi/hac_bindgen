--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Sequence.Get_Select                  Spring, 2026       --
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
   function Get_Select return Node_Ptr is
   use Select_Alternative_Stack;

   Have_Delay     : Boolean := False;
   Have_Terminate : Boolean := False;
   Have_Accept    : Boolean := False;
   Delay_Until    : Boolean := False;
   Delay_At       : Location;
   Terminate_At   : Location;
   Accepted       : Statement_Sequence_Ref;
   Sequence       : Statement_Sequence_Ref;
   Keyword        : Reserved_Word;

   procedure Get_Select_Word is
   begin
      if not Get ("select") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'select' is expected after 'end' at " &
            Image (Link (Code))
         );
      end if;
   end Get_Select_Word;

   function Get_Asynchronous_Transfer_Control
            (  Statement : Trigger_Node_Ptr
            )  return Node_Ptr is
   begin
      if not Get ("abort") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'abort' is expected after 'then' at " &
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
            "'end select' is expected at " &
            Image (Link (Code))
         );
      end if;
      Get_Select_Word;
      declare
         type Arena_Ptr is access Asynchronous_Transfer_Control;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Result : constant Arena_Ptr :=
                  new Asynchronous_Transfer_Control
                      (  Labels_Count => Labels_Count,
                         Trigger      => Statement,
                         Abortable    => Statement_Sequence
                                         (  Sequence.all
                                         ) 'Unchecked_Access
                      );
         This   : Asynchronous_Transfer_Control renames Result.all;
      begin
         Sequence.Outer := This'Unchecked_Access;
         This.Triggered :=
            Statement_Sequence (Accepted.all)'Unchecked_Access;
         Pop (Context, Parent, File, This, This.Labels);
         return This'Unchecked_Access;
      end;
   end Get_Asynchronous_Transfer_Control;

   procedure Get_Selective_Alternative (Guarded : Boolean) is
      Guard : Tokens.Argument_Token;
      function Get_Guard return Optional is
      begin
         if Guarded then
            return (Present => True, Item => Guard);
         else
            return (Present => False);
         end if;
      end Get_Guard;
   begin
      if Guarded then
         Lexers.Parse (Context, Code, Guard);
         if not Get ("=>", False) then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'=>' is expected after the guard of select " &
               "alternative at "                             &
               Image (Link (Code))
            );
         end if;
         Get_Blank (Context, Code);
         Get_Reserved_Word (Code, Keyword);
      end if;
      case Keyword is
         when Accept_Word =>
            declare
               Statement : Accept_Statement_Ptr;
            begin
               Have_Accept := True;
               Statement   := Get_Accept;
               Get_Semicolon (Context, Code);
               Get_Blank (Context, Code);
               Get_Reserved_Word (Code, Keyword);
               case Keyword is
                  when Or_Word | Else_Word | End_Word | When_Word =>
                     Push
                     (  Context => Context,
                        Object  => (  Guarded => Guarded,
                                      Mode    => Accept_Alternative,
                                      Guard   => Get_Guard,
                                      Code    => null,
                                      Accept_Statement =>
                                         Statement.all'Unchecked_Access
                     )             );
                  when others =>
                     if Keyword /= No_Reserved_Word then
                        Reset_Pointer (Code);
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
                     (  Context => Context,
                        Object  => (  Guarded => Guarded,
                                      Mode    => Accept_Alternative,
                                      Guard   => Get_Guard,
                                      Code    => Statement_Sequence
                                                 (  Sequence.all
                                                 ) 'Unchecked_Access,
                                      Accept_Statement => Statement
                     )             );
               end case;
            end;
         when Delay_Word =>
            declare
               Statement : Delay_Statement_Ptr;
            begin
               if Have_Terminate then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Terminate alternative at "             &
                     Image (Terminate_At)                    &
                     " conflicts with delay alternative at " &
                     Image (Link (Code))
                  );
               end if;
               if Have_Delay then
                  declare
                     Other_At : constant Location := Delay_At;
                  begin
                     Delay_At  := Link (Code);
                     Statement := Get_Delay;
                     if Statement.Relative then
                        if Delay_Until then
                           Raise_Exception
                           (  Parsers.Syntax_Error'Identity,
                              "Absolute delay alternative at "      &
                              Image (Other_At)                      &
                              " conflicts with the relative delay " &
                              " alternative at "                    &
                              Image (Delay_At)
                           );
                        end if;
                     else
                        if not Delay_Until then
                           Raise_Exception
                           (  Parsers.Syntax_Error'Identity,
                              "Relative delay alternative at "      &
                              Image (Other_At)                      &
                              " conflicts with the absolute delay " &
                              " alternative at "                    &
                              Image (Delay_At)
                           );
                        end if;
                     end if;
                  end;
               else
                  Have_Delay  := True;
                  Delay_At    := Link (Code);
                  Statement   := Get_Delay;
                  Delay_Until := not Statement.Relative;
               end if;
               Get_Semicolon (Context, Code);
               Get_Blank (Context, Code);
               Get_Reserved_Word (Code, Keyword);
               case Keyword is
                  when Or_Word | Else_Word | End_Word | When_Word =>
                     Push
                     (  Context => Context,
                        Object  => (  Guarded => Guarded,
                                      Mode    => Delay_Alternative,
                                      Guard   => Get_Guard,
                                      Code    => null,
                                      Delay_Statement => Statement
                     )             );
                  when others =>
                     if Keyword /= No_Reserved_Word then
                        Reset_Pointer (Code);
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
                     (  Context => Context,
                        Object  => (  Guarded => Guarded,
                                      Mode    => Delay_Alternative,
                                      Guard   => Get_Guard,
                                      Code    => Statement_Sequence
                                                 (  Sequence.all
                                                 ) 'Unchecked_Access,
                                      Delay_Statement => Statement
                     )             );
               end case;
            end;
         when Terminate_Word =>
            if Have_Delay then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Delay alternative at "                     &
                  Image (Delay_At)                            &
                  " conflicts with terminate alternative at " &
                  Image (Link (Code))
               );
            end if;
            Have_Terminate := True;
            Terminate_At   := Link (Code);
            Push
            (  Context => Context,
               Object  => (  Guarded => Guarded,
                             Mode    => Terminate_Alternative,
                             Guard   => Get_Guard
            )             );
            Get_Semicolon (Context, Code);
            Get_Blank (Context, Code);
            Get_Reserved_Word (Code, Keyword);
         when others =>
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'accept', 'delay', or 'terminate' is expected at " &
               Image (Link (Code))
            );
      end case;
   end Get_Selective_Alternative;

   function Get_Selective_Accept (Guarded : Boolean) return Node_Ptr is
      type Arena_Ptr is access Selective_Accept;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Result  : Arena_Ptr;
      Default : Statement_Sequence_Ref;
   begin
      Get_Selective_Alternative (Guarded);
      for Count in Positive loop
         case Keyword is
            when Or_Word =>
               if Get ("when") then
                  Get_Selective_Alternative (True);
               else
                  Get_Blank (Context, Code);
                  Get_Reserved_Word (Code, Keyword);
                  Get_Selective_Alternative (False);
               end if;
            when Else_Word =>
               if Have_Terminate then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Terminate alternative at "     &
                     Image (Terminate_At)            &
                     " conflicts with else part at " &
                     Image (Link (Code))
                  );
               end if;
               if Have_Delay then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Delay alternative at "         &
                     Image (Delay_At)                &
                     " conflicts with else part at " &
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
                  Result    => Default
               );
               if Keyword /= End_Word then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'end select' is expected at " &
                     Image (Link (Code))
                  );
               end if;
               Result := new Selective_Accept
                             (  Labels_Count => Labels_Count,
                                Count        => Count
                             );
               exit;
            when End_Word =>
               Result := new Selective_Accept
                             (  Labels_Count => Labels_Count,
                                Count        => Count
                             );
               exit;
            when Terminate_Word =>
               Get_Selective_Alternative (False);
            when others =>
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'end select', 'else' or 'or' is " &
                  "expected at "                     &
                  Image (Link (Code))
               );
         end case;
      end loop;
      if not Have_Accept then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Selective accept must have at least one accept " &
            "alternative at "                                 &
            Image (Link (Code))
         );
      end if;
      Get_Select_Word;
      declare
         This : Selective_Accept renames Result.all;
      begin
         if Default /= null then
            Default.Outer := This'Unchecked_Access;
            This.Default :=
               Statement_Sequence (Default.all)'Unchecked_Access;
         end if;
         for Index in reverse This.Alternatives'Range loop
            Pop (Context, This.Alternatives (Index));
            declare
               Item : Select_Alternative renames
                      This.Alternatives (Index);
            begin
               if Item.Mode /= Terminate_Alternative and then
                  Item.Code /= null then
                  Ref (Item.Code).Outer := This'Unchecked_Access;
               end if;
            end;
         end loop;
         Pop (Context, Parent, File, This, This.Labels);
         return This'Unchecked_Access;
      end;
   end Get_Selective_Accept;
begin
   Get_Blank (Context, Code);
   Get_Reserved_Word (Code, Keyword);
   case Keyword is
      when When_Word =>
         return Get_Selective_Accept (True);
      when Accept_Word =>
         return Get_Selective_Accept (False);
      when Delay_Word =>
         declare
            Statement : constant Delay_Statement_Ptr := Get_Delay;
         begin
            Get_Semicolon (Context, Code);
            if Get ("then") then
               return Get_Asynchronous_Transfer_Control
                      (  Statement.all'Unchecked_Access
                      );
            else
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
               Accepted :=
                  Statement_Sequence (Sequence.all)'Unchecked_Access;
               if Keyword /= Then_Word then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'then abort' is expected at " &
                     Image (Link (Code))
                  );
               end if;
               return Get_Asynchronous_Transfer_Control
                      (  Statement.all'Unchecked_Access
                      );
            end if;
         end;
      when No_Reserved_Word =>
         declare
            Statement : Call_Statement_Ptr;

            function Get_Conditional_Entry_Call return Node_Ptr is
            begin
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
                     "'end select' is expected at " &
                     Image (Link (Code))
                  );
               end if;
               Get_Select_Word;
               declare
                  type Arena_Ptr is access Conditional_Entry_Call;
                  for Arena_Ptr'Storage_Pool use Context.Pool.all;
                  Result : constant Arena_Ptr :=
                           new Conditional_Entry_Call
                               (  Labels_Count  => Labels_Count,
                                  Entry_Call    => Statement,
                                  Rejected_Code => Statement_Sequence
                                                   (  Sequence.all
                                                   ) 'Unchecked_Access
                               );
                  This : Conditional_Entry_Call renames Result.all;
               begin
                  Sequence.Outer := This'Unchecked_Access;
                  if Accepted /= null then
                     Accepted.Outer := This'Unchecked_Access;
                     This.Accepted_Code :=
                        Statement_Sequence
                        (  Accepted.all
                        ) 'Unchecked_Access;
                  end if;
                  Pop (Context, Parent, File, This, This.Labels);
                  return This'Unchecked_Access;
               end;
            end Get_Conditional_Entry_Call;

            function Get_Timed_Entry_Call return Node_Ptr is
            begin
               if not Get ("delay") then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'delay' is expected at " & Image (Link (Code))
                  );
               end if;
               declare
                  Timer : constant Delay_Statement_Ptr := Get_Delay;
               begin
                  Get_Semicolon (Context, Code);
                  if not Get ("end") then
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
                           "'end select' is expected at " &
                           Image (Link (Code))
                        );
                     end if;
                  end if;
                  Get_Select_Word;
                  declare
                     type Arena_Ptr is access Timed_Entry_Call;
                     for Arena_Ptr'Storage_Pool use Context.Pool.all;
                     Result : constant Arena_Ptr :=
                              new Timed_Entry_Call
                                  (  Labels_Count => Labels_Count,
                                     Entry_Call   => Statement,
                                     Timer        => Timer
                                  );
                     This   : Timed_Entry_Call renames Result.all;
                  begin
                     if Accepted /= null then
                        Accepted.Outer := This'Unchecked_Access;
                        This.Accepted_Code :=
                           Statement_Sequence
                           (  Accepted.all
                           ) 'Unchecked_Access;
                     end if;
                     if Sequence /= null then
                        Sequence.Outer := This'Unchecked_Access;
                        This.Expired_Code := Statement_Sequence
                                             (  Sequence.all
                                             ) 'Unchecked_Access;
                     end if;
                     Pop (Context, Parent, File, This, This.Labels);
                     return This'Unchecked_Access;
                  end;
               end;
            end Get_Timed_Entry_Call;

            Expression : Tokens.Argument_Token;
         begin
            Lexers.Parse (Context, Code, Expression);
            Statement := Get_Call (Expression);
            Get_Semicolon (Context, Code);
            Get_Blank (Context, Code);
            Get_Reserved_Word (Code, Keyword);
            case Keyword is
               when Else_Word =>
                  return Get_Conditional_Entry_Call;
               when Or_Word =>
                  return Get_Timed_Entry_Call;
               when Then_Word =>
                  return Get_Asynchronous_Transfer_Control
                         (  Statement.all'Unchecked_Access
                         );
               when others =>
                  if Keyword /= No_Reserved_Word then
                     Reset_Pointer (Code);
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
                  Accepted :=
                     Statement_Sequence (Sequence.all)'Unchecked_Access;
                  case Keyword is
                     when Else_Word =>
                        return Get_Conditional_Entry_Call;
                     when Or_Word =>
                        return Get_Timed_Entry_Call;
                     when Then_Word =>
                        return Get_Asynchronous_Transfer_Control
                               (  Statement.all'Unchecked_Access
                               );
                     when others =>
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "'else', 'or' or 'then' is expected at " &
                           Image (Link (Code))
                        );
                  end case;
            end case;
         end;
      when others =>
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'" & Image (Keyword) & "' is unexpected after " &
            "'select' at "                                   &
            Image (Link (Code))
         );
   end case;
   Raise_Exception
   (  Parsers.Syntax_Error'Identity,
      "Unexpected state at " & Image (Link (Code))
   );
end Get_Select;
