--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Statements                               Spring, 2026       --
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

with Strings_Edit;  use Strings_Edit;

package body Parsers.Ada_Syntax_Analyzer.Statements is

   function Equal_Statements
            (  Left  : Abstract_Statement_Node'Class;
               Right : Abstract_Statement_Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
      procedure Check (This : Abstract_Statement_Node'Class) is
      begin
         if (  This.Path.Sequence /= null
            and then
               (  This.Path.Sequence.List (This.Path.Position)
               /= This'Unchecked_Access
            )  )
         then
            raise Constraint_Error;
         end if;
      end Check;
   begin
      Check (Left);
      Check (Right);
      if not Equal (Left.Path, Right.Path, Mode) then
         return Inequal;
      elsif Left.Labels_Count /= Right.Labels_Count then
         return Inequal;
      end if;
      for Index in Left.Labels'Range loop
         if not Equal
                (  Left.Labels (Index),
                   Right.Labels (Index),
                   Mode
                )  then
            return Inequal;
         end if;
      end loop;
      if 0 = (Location_Independent and Mode) then
         if Left.Location /= Right.Location then
            return Inequal;
         end if;
      end if;
      return True;
   end Equal_Statements;

   function Equal_Sequence
            (  Left  : Statement_Sequence'Class;
               Right : Statement_Sequence'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if not Equal (Left.Context, Right.Context, Mode) then
         return Inequal;
      elsif Left.Length /= Right.Length then
         return Inequal;
      elsif not Equal_Statements (Left, Right, Mode) then
         return Inequal;
      elsif (Left.Outer = null) /= (Right.Outer = null) then
         return Inequal;
      elsif Left.Outer /= null then
         if Program_Node_Class'(Get_Class (Left.Outer.all)) /=
            Program_Node_Class'(Get_Class (Right.Outer.all)) then
            return Inequal;
         end if;
      end if;
      for Index in Left.List'Range loop
         if not Equal
                (  Left.List (Index).all,
                   Right.List (Index).all,
                   Mode
                )  then
            return Inequal;
         end if;
      end loop;
      return True;
   end Equal_Sequence;

   function Equal
            (  Left  : Optional;
               Right : Optional;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Left.Present /= Right.Present then
         return Inequal;
      end if;
      return not Left.Present or else
             Equal (Left.Item, Right.Item, Mode);
   end Equal;

   function Equal_Loop
            (  Left  : Abstract_Loop_Statement'Class;
               Right : Abstract_Loop_Statement'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
       if not Equal (Left.Name, Right.Name, Mode) then
          return Inequal;
       elsif not Equal_Sequence
                 (  Left.Sequence.all,
                    Right.Sequence.all,
                    Mode
                 )  then
          return Inequal;
       end if;
       return Equal_Statements (Left, Right, Mode);
   end Equal_Loop;

   function Equal
            (  Left  : Abort_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Abort_Statement then
         return Inequal;
      else
         declare
            Other : Abort_Statement renames Abort_Statement (Right);
         begin
            if Equal (Left.Tasks, Other.Tasks, Mode) then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Accept_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Accept_Statement then
         return Inequal;
      else
         declare
            Other : Accept_Statement renames Accept_Statement (Right);
         begin
            if Left.Is_Family /= Other.Is_Family then
              return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Sequence, Other.Sequence, Mode) then
               return Inequal;
            elsif not Equal (Left.Profile, Other.Profile, Mode) then
               return Inequal;
            elsif not Equal (Left.Index, Other.Index, Mode) then
              return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Assignment_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Assignment_Statement then
         return Inequal;
      else
         declare
            Other : Assignment_Statement renames
                    Assignment_Statement (Right);
         begin
            if not Equal (Left.Variable, Other.Variable, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Expression,
                         Other.Expression,
                         Mode
                      )  then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Asynchronous_Transfer_Control;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Asynchronous_Transfer_Control then
         return Inequal;
      else
         declare
            Other : Asynchronous_Transfer_Control renames
                    Asynchronous_Transfer_Control (Right);
         begin
            if not Equal
                   (  Left.Trigger.all,
                      Other.Trigger.all,
                      Mode
                   )  then
               return Inequal;
            elsif not Equal
                      (  Left.Abortable.all,
                         Other.Abortable.all,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal (Left.Triggered, Other.Triggered, Mode) then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Block_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Block_Statement then
         return Inequal;
      else
         declare
            Other : Block_Statement renames Block_Statement (Right);
         begin
            if not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Sequence.all,
                         Other.Sequence.all,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Declarations,
                         Other.Declarations,
                         Mode
                      )  then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Call_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Call_Statement then
         return Inequal;
      else
         declare
            Other : Call_Statement renames Call_Statement (Right);
         begin
            if not Equal (Left.Target, Other.Target, Mode) then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Case_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
      function Equal (Left, Right : Choice_Alternative)
         return Boolean is
      begin
         if not Equal (Left.Choice.all, Right.Choice.all, Mode) then
            return Inequal;
         end if;
         return Equal (Left.Code, Right.Code, Mode);
      end Equal;
   begin
      if Right not in Case_Statement then
         return Inequal;
      else
         declare
            Other : Case_Statement renames Case_Statement (Right);
         begin
            if Left.Count /= Other.Count then
               return Inequal;
            end if;
            for Index in Left.Alternatives'Range loop
               if not Equal
                      (  Left.Alternatives (Index),
                         Other.Alternatives (Index)
                      )  then
                  return Inequal;
               end if;
            end loop;
            if not Equal (Left.Selector, Other.Selector, Mode) then
               return Inequal;
            elsif not Equal (Left.Default, Other.Default, Mode) then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Chunk_Specification;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Chunk_Specification then
         return Inequal;
      else
         declare
            Other : Chunk_Specification renames
                    Chunk_Specification (Right);
         begin
            if Left.Outer = null or else Other.Outer = null then
               raise Constraint_Error;
            end if;
            if Left.Mode /= Other.Mode then
               return Inequal;
            end if;
            case Left.Mode is
               when Chunk_Any =>
                  null;
               when Chunk_Parameter =>
                  return Equal (Left.Name, Other.Name, Mode);
               when Chunk_Expression =>
                  return Equal (Left.Value, Other.Value, Mode);
            end case;
            if Program_Node_Class'(Get_Class (Left.Outer.all)) /=
               Program_Node_Class'(Get_Class (Other.Outer.all)) then
               return Inequal;
            end if;
            return True;
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Conditional_Entry_Call;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Conditional_Entry_Call then
         return Inequal;
      else
         declare
            Other : Conditional_Entry_Call renames
                    Conditional_Entry_Call (Right);
         begin
            if not Equal
                   (  Left.Entry_Call.all,
                      Other.Entry_Call.all,
                      Mode
                   )  then
               return Inequal;
            elsif not Equal
                      (  Left.Rejected_Code.all,
                         Other.Rejected_Code.all,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Accepted_Code,
                         Other.Accepted_Code,
                         Mode
                      )  then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Delay_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Delay_Statement then
         return Inequal;
      else
         declare
            Other : Delay_Statement renames
                    Delay_Statement (Right);
         begin
            if Left.Relative /= Other.Relative then
               return Inequal;
            elsif not Equal (Left.Time, Other.Time, Mode) then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Exception_Handler;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
      procedure Check (This : Exception_Handler) is
      begin
         if This.Outer = null then
            raise Constraint_Error;
         end if;
         declare
            Outer : Handled_Statement_Sequence renames This.Outer.all;
         begin
            for Index in Outer.Handlers'Range loop
               if Outer.Handlers (Index) = This'Unchecked_Access then
                  return;
               end if;
            end loop;
            raise Constraint_Error;
         end;
      end;
   begin
      if Right not in Exception_Handler then
         return Inequal;
      else
         declare
            Other : Exception_Handler renames
                    Exception_Handler (Right);
         begin
            Check (Left);
            Check (Other);
            if Left.Has_Parameter /= Other.Has_Parameter then
               return Inequal;
            elsif Left.Has_Parameter and then
                  Equal (Left.Parameter, Other.Parameter, Mode) then
               return Inequal;
            elsif not Equal (Left.Sequence, Other.Sequence, Mode) then
               return Inequal;
            elsif not Equal (Left.Choices, Other.Choices, Mode) then
               return Inequal;
            elsif 0 = (Location_Independent and Mode) then
               if Left.Location /= Other.Location then
                  return Inequal;
               end if;
            end if;
            return True;
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Exit_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Exit_Statement then
         return Inequal;
      else
         declare
            Other : Exit_Statement renames Exit_Statement (Right);
         begin
            if Left.Loop_Of = null or else Other.Loop_Of = null then
               raise Constraint_Error;
            end if;
            if not Equal (Left.Loop_Name, Other.Loop_Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Condition, Other.Condition, Mode) then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Extended_Return_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Extended_Return_Statement then
         return Inequal;
      else
         declare
            Other : Extended_Return_Statement renames
                    Extended_Return_Statement (Right);
         begin
            if not Equal (Left.Result, Other.Result, Mode) then
               return Inequal;
            elsif not Equal (Left.Code, Other.Code, Mode) then
               return Inequal;
            elsif not Equal (Left.Initial, Other.Initial, Mode) then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : For_Loop_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
      procedure Check
                (  Parameter : Singleton_Parameter;
                   This      : For_Loop_Statement
                )  is
      begin
         if Parameter.Name.Outer /= This'Unchecked_Access then
            raise Constraint_Error;
         end if;
      end Check;

      procedure Check (Chunk : Chunk_Specification_Ptr) is
      begin
         if Chunk /= null and then Chunk.Mode = Chunk_Parameter then
            if Chunk.Name.Name.Outer /= Chunk.all'Unchecked_Access then
               raise Constraint_Error;
            end if;
         end if;
      end Check;
   begin
      if Right not in For_Loop_Statement then
         return Inequal;
      else
         declare
            Other : For_Loop_Statement renames
                    For_Loop_Statement (Right);
         begin
            if Left.Mode /= Other.Mode then
               return Inequal;
            end if;
            Check (Left.Chunk);
            Check (Other.Chunk);
            case Left.Mode is
               when In_Interation_Mode | Of_Interation_Mode =>
                  Check (Left.Parameter, Left);
                  Check (Other.Parameter, Other);
                  if Left.In_Reverse /= Other.In_Reverse then
                     return Inequal;
                  elsif not Equal
                            (  Left.Parameter,
                               Other.Parameter,
                               Mode
                            )  then
                     return Inequal;
                  elsif not Equal
                            (  Left.Iterator_Subtype,
                               Other.Iterator_Subtype,
                               Mode
                            )  then
                     return Inequal;
                  end if;
               when Formal_Part_Mode | List_Mode =>
                  if not Equal
                         (  Left.Iterator_Call,
                            Other.Iterator_Call,
                            Mode
                         )  then
                     return Inequal;
                  end if;
                  case Left.Mode is
                     when In_Interation_Mode | Of_Interation_Mode =>
                        null;
                     when Formal_Part_Mode =>
                        if not Equal
                               (  Left.Formal_Part,
                                  Other.Formal_Part,
                                  Mode
                               )  then
                           return Inequal;
                        end if;
                     when List_Mode =>
                        if not Equal
                               (  Left.Iterator.all,
                                  Other.Iterator.all,
                                  Mode
                               )  then
                           return Inequal;
                        end if;
                  end case;
            end case;
            if (Left.Chunk = null) /= (Other.Chunk = null) then
               return Inequal;
            elsif Left.Chunk /= null and then
                  not Equal (Left.Chunk.all, Other.Chunk.all, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Iterator_Filter,
                         Other.Iterator_Filter,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal_Loop (Left, Other, Mode) then
               return Inequal;
            end if;
            return True;
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Goto_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Goto_Statement then
         return Inequal;
      else
         declare
            Other : Goto_Statement renames Goto_Statement (Right);
         begin
            if not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Handled_Statement_Sequence_Ptr;
               Right : Handled_Statement_Sequence_Ptr;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if (Left = null) /= (Right = null) then
         return Inequal;
      elsif Left /= null then
         if not Equal (Left.all, Right.all, Mode) then
            return Inequal;
         end if;
      end if;
      return True;
   end Equal;

   function Equal
            (  Left  : Handled_Statement_Sequence;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Handled_Statement_Sequence then
         return Inequal;
      else
         declare
            Other : Handled_Statement_Sequence renames
                    Handled_Statement_Sequence (Right);
         begin
            if Left.Handlers_Count /= Other.Handlers_Count then
               return Inequal;
            elsif not Equal_Sequence (Left, Other, Mode) then
               return Inequal;
            end if;
            for Index in Left.Handlers'Range loop
               if not Equal
                      (  Left.Handlers (Index).all,
                         Other.Handlers (Index).all,
                         Mode
                      )  then
                  return Inequal;
               end if;
            end loop;
            return True;
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : If_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
      function Equal (Left, Right : Guarded_Alternative)
         return Boolean is
      begin
         return Equal (Left.Guard, Right.Guard, Mode) and then
                Equal (Left.Code,  Right.Code,  Mode);
      end Equal;
   begin
      if Right not in If_Statement then
         return Inequal;
      else
         declare
            Other : If_Statement renames If_Statement (Right);
         begin
            if Left.Count /= Other.Count then
               return Inequal;
            end if;
            for Index in Left.Alternatives'Range loop
               if not Equal
                      (  Left.Alternatives (Index),
                         Other.Alternatives (Index)
                      )  then
                  return Inequal;
               end if;
            end loop;
            if not Equal (Left.Default, Other.Default, Mode) then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Loop_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Loop_Statement then
         return Inequal;
      else
         declare
            Other : Loop_Statement renames
                    Loop_Statement (Right);
         begin
            return Equal_Loop (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Null_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Null_Statement then
         return Inequal;
      else
         declare
            Other : Null_Statement renames Null_Statement (Right);
         begin
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Parallel_Block_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Parallel_Block_Statement then
         return Inequal;
      else
         declare
            Other : Parallel_Block_Statement renames
                    Parallel_Block_Statement (Right);
         begin
            if Left.Paths_Count /= Other.Paths_Count then
               return Inequal;
            end if;
            for Index in Left.Paths'Range loop
               if not Equal
                      (  Left.Paths (Index).all,
                         Other.Paths (Index).all,
                         Mode
                      )  then
                  return Inequal;
               end if;
            end loop;
            if not Equal (Left.Chunk.all, Other.Chunk.all, Mode) then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Raise_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Raise_Statement then
         return Inequal;
      else
         declare
            Other : Raise_Statement renames
                    Raise_Statement (Right);
         begin
            if Left.Reraise /= Other.Reraise then
               return Inequal;
            elsif Left.Reraise then
               if not Equal (Left.Name, Other.Name, Mode) then
                  return Inequal;
               elsif not Equal (Left.Text, Other.Text, Mode) then
                  return Inequal;
               end if;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Requeue_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Requeue_Statement then
         return Inequal;
      else
         declare
            Other : Requeue_Statement renames
                    Requeue_Statement (Right);
         begin
            if Left.With_Abort /= Other.With_Abort then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Selective_Accept;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
      function Equal (Left, Right : Select_Alternative) return Boolean is
      begin
         if Left.Mode /= Right.Mode then
            return Inequal;
         end if;
         case Left.Mode is
            when Accept_Alternative =>
               if not Equal (Left.Code, Right.Code, Mode) then
                  return Inequal;
               elsif not Equal
                         (  Left.Accept_Statement.all,
                            Right.Accept_Statement.all,
                            Mode
                         )  then
                  return Inequal;
               end if;
            when Delay_Alternative =>
               if not Equal (Left.Code, Right.Code, Mode) then
                  return Inequal;
               elsif not Equal
                         (  Left.Delay_Statement.all,
                            Right.Delay_Statement.all,
                            Mode
                         )  then
                  return Inequal;
               end if;
            when Terminate_Alternative =>
               null;
         end case;
         return Equal (Left.Guard, Right.Guard, Mode);
      end Equal;
   begin
      if Right not in Selective_Accept then
         return Inequal;
      else
         declare
            Other : Selective_Accept renames
                    Selective_Accept (Right);
         begin
            if Left.Count /= Other.Count then
               return Inequal;
            end if;
            for Index in Left.Alternatives'Range loop
               if not Equal
                      (  Left.Alternatives (Index),
                         Other.Alternatives (Index)
                      )  then
                  return Inequal;
               end if;
            end loop;
            if not Equal (Left.Default, Other.Default, Mode) then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Simple_Return_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Simple_Return_Statement then
         return Inequal;
      else
         declare
            Other : Simple_Return_Statement renames
                    Simple_Return_Statement (Right);
         begin
            if Left.Has_Result /= Other.Has_Result then
               return Inequal;
            elsif Left.Has_Result and then
                  not Equal (Left.Result, Other.Result, Mode) then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Statement_Location;
               Right : Statement_Location;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if (Left.Sequence = null) /= (Right.Sequence = null) then
         return Inequal;
      elsif Left.Sequence = null then
         return True;
      elsif Left.Position /= Right.Position then
         return Inequal;
      elsif (Left.Sequence.Outer = null) /=
            (Right.Sequence.Outer = null) then
         return Inequal;
      elsif Left.Sequence.Labels_Count /=
            Right.Sequence.Labels_Count then
         return Inequal;
      elsif Left.Sequence.Length /= Right.Sequence.Length then
         return Inequal;
      elsif 0 = (Location_Independent and Mode) then
         if Program_Node_Class'(Get_Class (Left.Sequence.Outer.all)) /=
            Program_Node_Class'(Get_Class (Right.Sequence.Outer.all))
         then
            return Inequal;
         end if;
      end if;
      return True;
   end Equal;

   function Equal
            (  Left  : Statement_Sequence;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Statement_Sequence then
         return Inequal;
      else
         declare
            Other : Statement_Sequence renames
                    Statement_Sequence (Right);
         begin
            return Equal_Sequence (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Timed_Entry_Call;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Timed_Entry_Call then
         return Inequal;
      else
         declare
            Other : Timed_Entry_Call renames
                    Timed_Entry_Call (Right);
         begin
            if not Equal
                   (  Left.Entry_Call.all,
                      Other.Entry_Call.all,
                      Mode
                   )  then
               return Inequal;
            elsif not Equal (Left.Timer.all, Other.Timer.all, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Accepted_Code,
                         Other.Accepted_Code,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Expired_Code,
                         Other.Expired_Code,
                         Mode
                      )  then
               return Inequal;
            end if;
            return Equal_Statements (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Unhandled_Statement_Sequence_Ptr;
               Right : Unhandled_Statement_Sequence_Ptr;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if (Left = null) /= (Right = null) then
         return Inequal;
      end if;
      return Left = null or else Equal (Left.all, Right.all, Mode);
   end Equal;

   function Equal
            (  Left  : While_Loop_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in While_Loop_Statement then
         return Inequal;
      else
         declare
            Other : While_Loop_Statement renames
                    While_Loop_Statement (Right);
         begin
            if not Equal (Left.Condition, Other.Condition, Mode) then
               return Inequal;
            end if;
            return Equal_Loop (Left, Other, Mode);
         end;
      end if;
   end Equal;

   function Get_Class (Item : Abort_Statement)
      return Program_Node_Class is
   begin
      return Abort_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Accept_Statement)
      return Program_Node_Class is
   begin
      return Accept_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Assignment_Statement)
      return Program_Node_Class is
   begin
      return Assignment_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Asynchronous_Transfer_Control)
      return Program_Node_Class is
   begin
      return Asynchronous_Transfer_Control_Node;
   end Get_Class;

   function Get_Class (Item : Block_Statement)
      return Program_Node_Class is
   begin
      return Block_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Call_Statement)
      return Program_Node_Class is
   begin
      return Call_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Case_Statement)
      return Program_Node_Class is
   begin
      return Case_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Chunk_Specification)
      return Program_Node_Class is
   begin
      return Chunk_Specification_Node;
   end Get_Class;

   function Get_Class (Item : Conditional_Entry_Call)
      return Program_Node_Class is
   begin
      return Conditional_Entry_Call_Node;
   end Get_Class;

   function Get_Class (Item : Delay_Statement)
      return Program_Node_Class is
   begin
      return Delay_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Exit_Statement)
      return Program_Node_Class is
   begin
      return Exit_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Exception_Handler)
      return Program_Node_Class is
   begin
      return Exception_Handler_Node;
   end Get_Class;

   function Get_Class (Item : Extended_Return_Statement)
      return Program_Node_Class is
   begin
      return Extended_Return_Statement_Node;
   end Get_Class;

   function Get_Class (Item : For_Loop_Statement)
      return Program_Node_Class is
   begin
      return For_Loop_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Goto_Statement)
      return Program_Node_Class is
   begin
      return Goto_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Handled_Statement_Sequence)
      return Program_Node_Class is
   begin
      return Handled_Statement_Sequence_Node;
   end Get_Class;

   function Get_Class (Item : If_Statement)
      return Program_Node_Class is
   begin
      return If_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Loop_Statement)
      return Program_Node_Class is
   begin
      return Loop_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Null_Statement)
      return Program_Node_Class is
   begin
      return Null_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Parallel_Block_Statement)
      return Program_Node_Class is
   begin
      return Parallel_Block_Node;
   end Get_Class;

   function Get_Class (Item : Raise_Statement)
      return Program_Node_Class is
   begin
      return Raise_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Requeue_Statement)
      return Program_Node_Class is
   begin
      return Requeue_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Selective_Accept)
      return Program_Node_Class is
   begin
      return Selective_Accept_Node;
   end Get_Class;

   function Get_Class (Item : Simple_Return_Statement)
      return Program_Node_Class is
   begin
      return Simple_Return_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Statement_Sequence)
      return Program_Node_Class is
   begin
      return Statement_Sequence_Node;
   end Get_Class;

   function Get_Class (Item : Timed_Entry_Call)
      return Program_Node_Class is
   begin
      return Timed_Entry_Call_Node;
   end Get_Class;

   function Get_Class (Item : While_Loop_Statement)
      return Program_Node_Class is
   begin
      return While_Loop_Statement_Node;
   end Get_Class;

   procedure Put_Label
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Abstract_Statement_Node'Class;
                Prefix      : String := ""
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Labels_Count > 0 then
         Put (Destination, Index, Prefix);
         for Label in Item.Labels'Range loop
            Put (Destination, Index, "<<");
            Put (Destination, Index, Item.Labels (Label));
            Put (Destination, Index, ">> ");
         end loop;
         Pointer := Index;
      end if;
   end Put_Label;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Prefix      : String;
                Item        : Unhandled_Statement_Sequence_Ptr
             )  is
      Index : Integer := Pointer;
   begin
      if Item /= null then
         Put (Destination, Index, Prefix);
         Put (Destination, Index, Item.all);
         Pointer := Index;
      end if;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Abort_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put
      (  Destination => Destination,
         Pointer     => Index,
         List        => Item.Tasks,
         Prefix      => "abort ",
         Delimiter   => ", ",
         Suffix      => ";"
      );
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Accept_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "accept ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " (", Item.Index, ")");
      Put (Destination, Index, Item.Profile);
      if Item.Sequence /= null then
         Put (Destination, Index, " do ");
         Put (Destination, Index, Item.Sequence.all);
         Put (Destination, Index, "end ");
         Put (Destination, Index, Item.Name);
      end if;
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Assignment_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, Item.Variable);
      Put (Destination, Index, " := ");
      Put (Destination, Index, Item.Expression);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Asynchronous_Transfer_Control
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "select ");
      Put (Destination, Index, Item.Trigger.all);
      Put (Destination, Index, " ");
      Put (Destination, Index, "", Item.Triggered);
      Put (Destination, Index, "then abort ");
      Put (Destination, Index, Item.Abortable.all);
      Put (Destination, Index, "end select;");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Block_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "", Item.Name, " : ");
      if Item.Declarations /= null then
         Put (Destination, Index, "declare ");
         Put (Destination, Index, Item.Declarations.all);
      end if;
      Put (Destination, Index, "begin ");
      Put (Destination, Index, Item.Sequence.all);
      Put (Destination, Index, "end");
      Put (Destination, Index, " ", Item.Name, "");
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Call_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, Item.Target);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Case_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "case ");
      Put (Destination, Index, Item.Selector);
      Put (Destination, Index, " is ");
      Put
      (  Destination => Destination,
         Pointer     => Index,
         List        => Item.Alternatives,
         Prefix      => "when ",
         Delimiter   => "when ",
         Ligature    => " => "
      );
      if Item.Default /= null then
         Put (Destination, Index, "when others => ");
         Put (Destination, Index, Item.Default.all);
      end if;
      Put (Destination, Index, "end case;");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Choice_Alternatives_Array;
                Prefix      : String := "";
                Delimiter   : String := ", ";
                Ligature    : String := " => ";
                Suffix      : String := ""
             )  is
      Index : Integer := Pointer;
   begin
      if List'Length = 0 then
         return;
      end if;
      Put (Destination, Index, Prefix);
      for Item in List'Range loop
         declare
            This : Choice_Alternative renames List (Item);
         begin
            if Item > 1 then
               Put (Destination, Index, Delimiter);
            end if;
            for Item in This.Choice'Range loop
               if Item > This.Choice'First then
                  Put (Destination, Index, " | ");
               end if;
               Put (Destination, Index, This.Choice (Item));
            end loop;
            Put (Destination, Index, Ligature);
            Put (Destination, Index, This.Code.all);
         end;
      end loop;
      Put (Destination, Index, Suffix);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Chunk_Specification
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "parallel ");
      case Item.Mode is
         when Chunk_Any =>
            null;
         when Chunk_Parameter =>
            Put (Destination, Index, "(");
            Put (Destination, Index, Item.Name.Name);
            if Item.Name.Type_Of.Present then
               Put (Destination, Index, " in ");
               Put
               (  Destination,
                  Index,
                  Item.Name.Type_Of.Object_Parameter
               );
            end if;
            Put (Destination, Index,  ") ");
         when Chunk_Expression =>
            Put (Destination, Index, "(");
            Put (Destination, Index, Item.Value);
            Put (Destination, Index, ") ");
      end case;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Conditional_Entry_Call
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "select ");
      Put (Destination, Index, Item.Entry_Call.all);
      Put (Destination, Index, " ");
      if Item.Accepted_Code /= null then
         Put (Destination, Index, Item.Accepted_Code.all);
      end if;
      Put (Destination, Index, "else ");
      Put (Destination, Index, Item.Rejected_Code.all);
      Put (Destination, Index, "end select;");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Delay_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "delay ");
      if Item.Relative then
         Put (Destination, Index, "until ");
      end if;
      Put (Destination, Index, Item.Time);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Exception_Handler
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Has_Parameter then
         Put (Destination, Index, "when ");
         Put (Destination, Index, Item.Parameter);
         Put (Destination, Index, " : ");
      else
         Put (Destination, Index, "when ");
      end if;
      if Item.Choices_Count = 0 then
         Put (Destination, Index, "others => ");
         Put (Destination, Index, Item.Sequence.all);
      else
         Put
         (  Destination => Destination,
            Pointer     => Index,
            List        => Item.Choices,
            Prefix      => "",
            Delimiter   => " | ",
            Suffix      => " => "
         );
         Put (Destination, Index, Item.Sequence.all);
      end if;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Exception_Handler_Ptr_Array;
                Prefix      : String := "exception "
             )  is
      Index : Integer := Pointer;
   begin
      if List'Length > 0 then
         Put (Destination, Index, Prefix);
         for Item in List'Range loop
            Put (Destination, Index, List (Item).all);
         end loop;
         Pointer := Index;
      end if;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Exit_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "exit");
      Put (Destination, Index, " ", Item.Loop_Name, "");
      Put (Destination, Index, " when ", Item.Condition, "");
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Extended_Return_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "return ");
      Put (Destination, Index, Item.Result);
      Put (Destination, Index, " := ", Item.Initial, "");
      if Item.Code /= null then
         Put (Destination, Index, " do ");
         Put (Destination, Index, Item.Code.all);
         Put (Destination, Index, "end return");
      end if;
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : For_Loop_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "", Item.Name, " : ");
      if Item.Chunk /= null then
         Put (Destination, Index, Item.Chunk.all);
      end if;
      Put (Destination, Index, Item.Aspects, "with ");
      Put (Destination, Index, "for");
      case Item.Mode is
         when In_Interation_Mode | Of_Interation_Mode =>
            Put (Destination, Index, " ");
            Put (Destination, Index, Item.Parameter);
            case Item.Mode is
               when In_Interation_Mode =>
                  Put (Destination, Index, " in ");
               when Of_Interation_Mode =>
                  Put (Destination, Index, " of ");
               when others =>
                  null;
            end case;
            if Item.In_Reverse then
               Put (Destination, Index, "reverse ");
            end if;
            Put (Destination, Index, Item.Iterator_Subtype);
         when Formal_Part_Mode =>
            Put (Destination, Index, Item.Formal_Part);
            Put (Destination, Index, " of ");
            Put (Destination, Index, Item.Iterator_Call);
         when List_Mode =>
            Put (Destination, Index, " (");
            Put (Destination, Index, Item.Iterator.all);
            Put (Destination, Index, ") of ");
            Put (Destination, Index, Item.Iterator_Call);
      end case;
      Put (Destination, Index, " when ", Item.Iterator_Filter, "");
      Put (Destination, Index, " loop ");
      Put (Destination, Index, Item.Sequence.all);
      Put (Destination, Index, "end loop");
      Put (Destination, Index, " ", Item.Name, "");
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Goto_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "goto ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Guarded_Alternative;
                Prefix      : String := "when ";
                Delimiter   : String := " => "
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Prefix);
      Put (Destination, Index, Item.Guard);
      Put (Destination, Index, Delimiter);
      Put (Destination, Index, Item.Code.all);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Guarded_Alternatives_Array;
                Prefix      : String := "when ";
                Delimiter   : String := " => "
             )  is
      Index : Integer := Pointer;
   begin
      if List'Length > 0 then
         for Item in List'Range loop
            Put
            (  Destination => Destination,
               Pointer     => Index,
               Item        => List (Item),
               Prefix      => Prefix,
               Delimiter   => Delimiter
            );
         end loop;
         Pointer := Index;
      end if;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Handled_Statement_Sequence
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Statement_Sequence (Item));
      Put (Destination, Index, Item.Handlers);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : If_Statement
             )  is
      Index : Integer := Pointer;
      List : Guarded_Alternatives_Array renames Item.Alternatives;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, List (1), "if ", " then ");
      Put (Destination, Index, List (2..List'Last), "elsif ", " then ");
      Put (Destination, Index, "else ", Item.Default);
      Put (Destination, Index, "end if;");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Loop_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "", Item.Name, " : ");
      Put (Destination, Index, "loop ");
      Put (Destination, Index, Item.Sequence.all);
      Put (Destination, Index, "end loop");
      Put (Destination, Index, " ", Item.Name, "");
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Null_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "null;");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Parallel_Block_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, Item.Chunk.all);
      Put (Destination, Index, Item.Aspects, "with ");
      Put (Destination, Index, "do ");
      for Path in Item.Paths'Range loop
         if Path > Item.Paths'First then
            Put (Destination, Index, "and ");
         end if;
         Put (Destination, Index, Item.Paths (Path).all);
      end loop;
      Put (Destination, Index, "end do;");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Raise_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      if Item.Reraise then
         Put (Destination, Index, "raise;");
      else
         Put (Destination, Index, "raise ");
         Put (Destination, Index, Item.Name);
         Put (Destination, Index, " with ", Item.Text, "");
         Put (Destination, Index, ";");
      end if;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Requeue_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "requeue ");
      Put (Destination, Index, Item.Name);
      if Item.With_Abort then
         Put (Destination, Index, " with abort");
      end if;
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Select_Alternative
             )  is
      Index : Integer := Pointer;
   begin
      case Item.Mode is
         when Accept_Alternative =>
            Put (Destination, Index, "when ", Item.Guard, " => ");
            Put (Destination, Index, Item.Accept_Statement.all);
            Put (Destination, Index, " ");
            Put (Destination, Index, "", Item.Code);
         when Delay_Alternative =>
            Put (Destination, Index, "when ", Item.Guard, " => ");
            Put (Destination, Index, Item.Delay_Statement.all);
            Put (Destination, Index, " ");
            Put (Destination, Index, "", Item.Code);
         when Terminate_Alternative =>
            Put (Destination, Index, "terminate; ");
      end case;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Selective_Accept
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "select");
      Put (Destination, Index, Item.Alternatives);
      if Item.Default /= null then
         Put (Destination, Index, "else ");
         Put (Destination, Index, Item.Default.all);
      end if;
      Put (Destination, Index, "end select;");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Select_Alternative_Array
             )  is
      Index : Integer := Pointer;
   begin
      for Item in List'Range loop
         if Item > List'First then
            Put (Destination, Index, "or ");
         else
            Put (Destination, Index, " ");
         end if;
         Put (Destination, Index, List (Item));
      end loop;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Simple_Return_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      if Item.Has_Result then
         Put (Destination, Index, "return ");
         Put (Destination, Index, Item.Result.Item);
         Put (Destination, Index, ";");
      else
         Put (Destination, Index, "return;");
      end if;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Statement_Sequence
             )  is
      List  : Statement_Ptr_Array renames Item.List;
      Index : Integer := Pointer;
   begin
      for Item in List'Range loop
         Put (Destination, Index, List (Item).all);
         Put (Destination, Index, " ");
      end loop;
      Put_Label (Destination, Index, Item);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Timed_Entry_Call
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "select ");
      Put (Destination, Index, Item.Entry_Call.all);
      Put (Destination, Index, " ");
      Put (Destination, Index, "", Item.Accepted_Code);
      Put (Destination, Index, "or ");
      Put (Destination, Index, Item.Timer.all);
      Put (Destination, Index, " ");
      Put (Destination, Index, "", Item.Expired_Code);
      Put (Destination, Index, "end select;");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : While_Loop_Statement
             )  is
      Index : Integer := Pointer;
   begin
      Put_Label (Destination, Index, Item);
      Put (Destination, Index, "", Item.Name, " : ");
      Put (Destination, Index, "while ");
      Put (Destination, Index, Item.Condition);
      Put (Destination, Index, " loop ");
      Put (Destination, Index, Item.Sequence.all);
      Put (Destination, Index, "end loop");
      Put (Destination, Index, " ", Item.Name, "");
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

end Parsers.Ada_Syntax_Analyzer.Statements;
