--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Statements                               Spring, 2026       --
--  Interface                                                         --
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

with Parsers.Ada_Syntax_Analyzer.Declarations;
use  Parsers.Ada_Syntax_Analyzer.Declarations;

with Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;

package Parsers.Ada_Syntax_Analyzer.Statements is
--
-- Statement_Sequence -- A sequence of statements
--
   type Statement_Sequence;
   type Statement_Sequence_Ptr is
      access constant Statement_Sequence'Class;
   type Unhandled_Statement_Sequence_Ptr is
      access constant Statement_Sequence;
   type Statement_Location is record
      Sequence : Statement_Sequence_Ptr;
      Position : Positive;
   end record;
--
-- Abstract_Statement_Node -- The base type of all statement nodes
--
--    Labels_Count - The number of statement labels
--    Location     - The statement source location
--    Parh         - The statement position in the sequence of
--    Labels       - The statement labels
--
   type Abstract_Statement_Node (Labels_Count : Natural) is abstract
      new Program_Node with
   record
      Location : Parsers.Multiline_Source.Location;
      Path     : Statement_Location;
      Labels   : Defining_Identifier_Array (1..Labels_Count);
   end record;
   type Statement_Ptr is access constant Abstract_Statement_Node'Class;
   type Statement_Ptr_Array is
      array (Positive range <>) of Statement_Ptr;
--
-- Abstract_Loop_Statement -- The base type for loop statements
--
   type Abstract_Loop_Statement
        (  Labels_Count : Natural;
           Named        : Boolean
        )  is abstract new Abstract_Statement_Node (Labels_Count) with
   record
      Name     : Optional (Named);
      Sequence : Unhandled_Statement_Sequence_Ptr;
   end record;
   type Loop_Statement_Ptr is
      access constant Abstract_Loop_Statement'Class;
--
-- Trigger_Node -- The base type for the asynchronous  transfer  control
--                 trigger.  That is  either  a call  or  else  a  delay
--                 statement
--
   type Trigger_Node is
      abstract new Abstract_Statement_Node with null record;
--
-- Statement_Sequence -- Statement sequence
--
--    Context - The declaration context immediately visble
--    Outer   - The node containing the sequence
--    List    - The sequence of statements
--
   type Statement_Sequence
        (  Labels_Count : Natural;
           Length       : Positive
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Context : Context_Location;
      Outer   : Program_Node_Ptr;
      List    : Statement_Ptr_Array (1..Length);
   end record;
   function Equal
            (  Left  : Statement_Sequence;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Get_Class (Item : Statement_Sequence)
      return Program_Node_Class;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Statement_Sequence
             );

   type Unhandled_Statement_Sequence_Ptr_Array is
      array (Positive range <>) of Unhandled_Statement_Sequence_Ptr;

   type Handled_Statement_Sequence;
   type Handled_Statement_Sequence_Ptr is
      access constant Handled_Statement_Sequence;
--
-- Exception_Handler -- Exception handler ARM 11.2
--
--    when <Choices> [: <Parameter>] => <Sequence>
--
   type Exception_Handler
        (  Has_Parameter : Boolean;
           Choices_Count : Natural
        )  is new Declaration_Node with
   record
      Outer    : Handled_Statement_Sequence_Ptr;
      Sequence : Unhandled_Statement_Sequence_Ptr;
      Choices  : Argument_List (1..Choices_Count);
      case Has_Parameter is
         when True =>
            Parameter : aliased Singleton_Parameter;
         when False =>
            null;
      end case;
   end record;
   type Exception_Handler_Ptr is access constant Exception_Handler;
   type Exception_Handler_Ptr_Array is
      array (Positive range <>) of Exception_Handler_Ptr;
--
-- Handled_Statement_Sequence -- Handled sequence of statements ARM 11.2
--
--       <List>
--  [ exception
--       <Handlers> ]
--
   type Handled_Statement_Sequence
        (  Labels_Count   : Natural;
           Length         : Positive;
           Handlers_Count : Natural
        )  is new Statement_Sequence
                  (  Labels_Count => Labels_Count,
                     Length       => Length
                  )  with
   record
      Handlers : Exception_Handler_Ptr_Array (1..Handlers_Count);
   end record;
   function Equal
            (  Left  : Handled_Statement_Sequence;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Handled_Statement_Sequence_Ptr;
               Right : Handled_Statement_Sequence_Ptr;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
--
-- Abort_Statement -- Abort statement ARM 9.8
--
   type Abort_Statement
        (  Labels_Count : Natural;
           Tasks_Count  : Positive
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Tasks : Argument_List (1..Tasks_Count);
   end record;
--
-- Accept_Statement -- Accept statement ARM 9.5.2
--
   type Accept_Statement
        (  Labels_Count : Natural;
           Is_Family    : Boolean
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Name     : aliased Defining_Identifier;
      Sequence : Handled_Statement_Sequence_Ptr;
      Profile  : Parameter_Profile_Ptr;
      Index    : Optional (Is_Family);
   end record;
   type Accept_Statement_Ptr is access constant Accept_Statement;
--
-- Assignment_Statement -- Assignment statement ARM 5.2
--
   type Assignment_Statement is new Abstract_Statement_Node with record
      Variable   : Tokens.Argument_Token;
      Expression : Tokens.Argument_Token;
   end record;
--
-- Asynchronous_Transfer_Control -- Asynchronous  transfer  control  ARM
--                                  9.7.4
--
   type Asynchronous_Transfer_Control
        (  Labels_Count : Natural;
           Trigger      : access constant Trigger_Node'Class;
           Abortable    : access constant Statement_Sequence
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Triggered : Unhandled_Statement_Sequence_Ptr;
   end record;
--
-- Block_Statement -- Block statement ARM 5.6
--
   type Block_Statement
        (  Labels_Count : Natural;
           Named        : Boolean;
           Sequence     : access constant Handled_Statement_Sequence
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Declarations : Declaration_Context_Ptr;
      Name         : Optional (Named);
   end record;
--
-- Call_Statement -- Call statement ARM 6.4 and 9.5.3
--
   type Call_Statement is new Trigger_Node with record
      Target : Tokens.Argument_Token;
   end record;
--
-- Conditional_Entry_Call -- Conditional entry call ARM 9.7.3
--
   type Conditional_Entry_Call
        (  Labels_Count  : Natural;
           Entry_Call    : access constant Call_Statement;
           Rejected_Code : access constant Statement_Sequence
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Accepted_Code : Unhandled_Statement_Sequence_Ptr;
   end record;
--
-- Choice_Alternative -- A code  sequence  guarded  by a discrete choice
--                       list
--
   type Choice_Alternative is record
      Choice : Subtype_Indication_Array_Ptr;
      Code   : Unhandled_Statement_Sequence_Ptr;
   end record;
   type Choice_Alternatives_Array is
      array (Positive range <>) of Choice_Alternative;
--
-- Case_Statement -- Case statement ARM 5.4
--
   type Case_Statement
        (  Labels_Count : Natural;
           Count        : Natural
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Selector     : Tokens.Argument_Token;
      Default      : Unhandled_Statement_Sequence_Ptr;
      Alternatives : Choice_Alternatives_Array (1..Count);
   end record;
--
-- Delay_Statement -- Delay statement ARM 6.9
--
   type Delay_Statement
        (  Labels_Count : Natural;
           Relative     : Boolean
        )  is new Trigger_Node (Labels_Count) with
   record
      Time : Tokens.Argument_Token;
   end record;
   type Delay_Statement_Ptr is access constant Delay_Statement;
--
-- Exit_Statement -- Loop exist statement ARM 5.7
--
   type Exit_Statement
        (  Labels_Count : Natural;
           Named        : Boolean;
           Conditional  : Boolean
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Loop_Of   : Loop_Statement_Ptr; -- The loop to exist
      Loop_Name : Optional (Named);
      Condition : Optional (Conditional);
   end record;
--
-- Extended_Return_Statement -- An extended return statement ARM 6.5
--
--    return <Result> [:= <Initial>] do
--       <Code>
--    end do;
--
   type Extended_Return_Statement
        (  Labels_Count : Natural;
           Initialized  : Boolean
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Result  : aliased Singleton_Parameter;
      Code    : Handled_Statement_Sequence_Ptr;
      Initial : Optional (Initialized);
   end record;
--
-- Iterator_Mode -- Loop iterator mode
--
   type Iterator_Mode is
        (  In_Interation_Mode,  -- for I in ...
           Of_Interation_Mode,  -- for I of ..
           Formal_Part_Mode,    -- for (I : T) of ...
           List_Mode            -- for (I, J, K) of ..
        );
   subtype Procedural_Iterator_Mode is
      Iterator_Mode range Formal_Part_Mode..List_Mode;
--
-- Chunk_Specification_Type -- Parallel loop chunk type
--
   type Chunk_Specification_Type is
        (  Chunk_Any,       -- No chunk specification
           Chunk_Parameter, -- <identifier> in <subtype>
           Chunk_Expression -- <expression>
        );
   type Chunk_Specification (Mode : Chunk_Specification_Type) is
      new Declaration_Node with
   record
      Outer : Program_Node_Ptr;
      case Mode is
         when Chunk_Any =>
            null;
         when Chunk_Parameter =>
            Name  : aliased Singleton_Parameter;
         when Chunk_Expression =>
            Value : Tokens.Argument_Token;
      end case;
   end record;
   type Chunk_Specification_Ptr is access constant Chunk_Specification;
--
-- For_Loop_Statement -- For loop statement ARM 5.5
--
   type For_Loop_Statement
        (  Labels_Count        : Natural;
           Named               : Boolean;
           Has_Iterator_Filter : Boolean;
           Mode                : Iterator_Mode;
           Aspects_Count       : Natural
        )  is new Abstract_Loop_Statement (Labels_Count, Named) with
   record
      Chunk           : Chunk_Specification_Ptr;
      Iterator_Filter : Optional (Has_Iterator_Filter);
      Aspects         : Aspect_Items_Array (1..Aspects_Count);
      case Mode is
         when In_Interation_Mode | Of_Interation_Mode =>
            In_Reverse       : Boolean;
            Parameter        : aliased Singleton_Parameter;
            Iterator_Subtype : Subtype_Indication;
         when Formal_Part_Mode | List_Mode =>
            Iterator_Call : Tokens.Argument_Token;
            case Mode is
               when In_Interation_Mode | Of_Interation_Mode =>
                  null;
               when Formal_Part_Mode =>
                  Formal_Part : Parameter_Profile_Ptr;
               when List_Mode =>
                  Iterator    : Identifier_List_Ptr;
            end case;
      end case;
   end record;
--
-- Goto_Statement -- Goto ARM 5.8
--
   type Goto_Statement is new Abstract_Statement_Node with record
      Name : Tokens.Argument_Token;
   end record;
--
-- Guarded_Alternative -- A code sequence guarded by an expression
--
   type Guarded_Alternative is record
      Guard : Tokens.Argument_Token;
      Code  : Unhandled_Statement_Sequence_Ptr;
   end record;
   type Guarded_Alternatives_Array is
      array (Positive range <>) of Guarded_Alternative;
--
-- If_Statement -- If statement ARM 5.3
--
   type If_Statement
        (  Labels_Count : Natural;
           Count        : Positive
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Default      : Unhandled_Statement_Sequence_Ptr;
      Alternatives : Guarded_Alternatives_Array (1..Count);
   end record;
--
-- Loop_Statement -- Loop statement ARM 5.5
--
--    loop
--       <Sequence>
--    end loop;
--
   type Loop_Statement is new Abstract_Loop_Statement with null record;
--
-- Null_Statement -- Null statement
--
   type Null_Statement is new Abstract_Statement_Node with null record;
--
-- Parallel_Block_Statement -- Parallel block statement ARM 5.6
--
   type Parallel_Block_Statement
        (  Labels_Count  : Natural;
           Paths_Count   : Positive;
           Aspects_Count : Natural
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Chunk   : Chunk_Specification_Ptr;
      Paths   : Unhandled_Statement_Sequence_Ptr_Array (1..Paths_Count);
      Aspects : Aspect_Items_Array (1..Aspects_Count);
   end record;
--
-- Raise_Statement -- Raise statement ARM 11.3
--
   type Raise_Statement
        (  Labels_Count : Natural;
           Reraise      : Boolean;
           Has_Text     : Boolean
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      case Reraise is
         when True =>
            null;
         when False =>
            Name : Tokens.Argument_Token;
            Text : Optional (Has_Text);
      end case;
   end record;
--
-- Requeue_Statement -- Requeue statement 9.5.4
--
   type Requeue_Statement
        (  Labels_Count : Natural;
           With_Abort   : Boolean
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Name : Tokens.Argument_Token;
   end record;
--
-- Select_Alternative_Type -- The type of a selective accept alternative
--
   type Select_Alternative_Type is
        (  Accept_Alternative,
           Delay_Alternative,
           Terminate_Alternative
        );
--
-- Select_Alternative -- A selective accept alternative
--
   type Select_Alternative
        (  Guarded : Boolean := False;
           Mode    : Select_Alternative_Type := Terminate_Alternative
        )  is
   record
      Guard : Optional (Guarded);
      case Mode is
         when Accept_Alternative | Delay_Alternative =>
            Code : Unhandled_Statement_Sequence_Ptr;
            case Mode is
               when Accept_Alternative =>
                  Accept_Statement : Accept_Statement_Ptr;
               when Delay_Alternative =>
                  Delay_Statement  : Delay_Statement_Ptr;
               when Terminate_Alternative =>
                  null;
            end case;
         when Terminate_Alternative =>
            null;
      end case;
   end record;
   type Select_Alternative_Array is
      array (Positive range <>) of Select_Alternative;
--
-- Selective_Accept -- A selective accept statement ARM 9.7.1
--
   type Selective_Accept
        (  Labels_Count : Natural;
           Count        : Positive
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Default      : Unhandled_Statement_Sequence_Ptr;
      Alternatives : Select_Alternative_Array (1..Count);
   end record;
--
-- Simple_Return_Statement -- A simple return statement 6.5
--
--    return [<Result>]
--
   type Simple_Return_Statement
        (  Labels_Count : Natural;
           Has_Result   : Boolean
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Result : Optional (Has_Result);
   end record;
--
-- Timed_Entry_Call -- A timed entry call ARM 9.7.2
--
   type Timed_Entry_Call
        (  Labels_Count : Natural;
           Entry_Call   : access constant Call_Statement;
           Timer        : access constant Delay_Statement
        )  is new Abstract_Statement_Node (Labels_Count) with
   record
      Accepted_Code : Unhandled_Statement_Sequence_Ptr;
      Expired_Code  : Unhandled_Statement_Sequence_Ptr;
   end record;
--
-- While_Loop_Statement -- While loop ARM 5.5
--
   type While_Loop_Statement is new Abstract_Loop_Statement with record
      Condition : Tokens.Argument_Token;
   end record;

private
   function Equal
            (  Left  : Abort_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Accept_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Assignment_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Asynchronous_Transfer_Control;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Block_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Call_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Case_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Chunk_Specification;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Conditional_Entry_Call;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Delay_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Exception_Handler;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Exit_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Extended_Return_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : For_Loop_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Goto_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : If_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Loop_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Null_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Parallel_Block_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Raise_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Requeue_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Selective_Accept;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Simple_Return_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Statement_Location;
               Right : Statement_Location;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Timed_Entry_Call;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : Unhandled_Statement_Sequence_Ptr;
               Right : Unhandled_Statement_Sequence_Ptr;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   function Equal
            (  Left  : While_Loop_Statement;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;

   function Get_Class (Item : Abort_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Accept_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Assignment_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Asynchronous_Transfer_Control)
      return Program_Node_Class;
   function Get_Class (Item : Block_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Call_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Case_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Chunk_Specification)
      return Program_Node_Class;
   function Get_Class (Item : Conditional_Entry_Call)
      return Program_Node_Class;
   function Get_Class (Item : Delay_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Exception_Handler)
      return Program_Node_Class;
   function Get_Class (Item : Exit_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Extended_Return_Statement)
      return Program_Node_Class;
   function Get_Class (Item : For_Loop_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Goto_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Handled_Statement_Sequence)
      return Program_Node_Class;
   function Get_Class (Item : If_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Loop_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Null_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Parallel_Block_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Raise_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Requeue_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Selective_Accept)
      return Program_Node_Class;
   function Get_Class (Item : Simple_Return_Statement)
      return Program_Node_Class;
   function Get_Class (Item : Timed_Entry_Call)
      return Program_Node_Class;
   function Get_Class (Item : While_Loop_Statement)
      return Program_Node_Class;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Abort_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Accept_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Assignment_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Asynchronous_Transfer_Control
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Block_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Call_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Case_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Choice_Alternatives_Array;
                Prefix      : String := "";
                Delimiter   : String := ", ";
                Ligature    : String := " => ";
                Suffix      : String := ""
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Chunk_Specification
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Conditional_Entry_Call
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Delay_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Exception_Handler
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Exit_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Extended_Return_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : For_Loop_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Goto_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Guarded_Alternative;
                Prefix      : String := "when ";
                Delimiter   : String := " => "
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Guarded_Alternatives_Array;
                Prefix      : String := "when ";
                Delimiter   : String := " => "
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Handled_Statement_Sequence
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : If_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Loop_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Null_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Parallel_Block_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item : Raise_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Requeue_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Select_Alternative_Array
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Selective_Accept
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Simple_Return_Statement
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Timed_Entry_Call
             );
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : While_Loop_Statement
             );

end Parsers.Ada_Syntax_Analyzer.Statements;
