--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer                 Luebeck            --
--  Implementation                                 Spring, 2026       --
--                                                                    --
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

with Ada.Exceptions;     use Ada.Exceptions;
with Ada.IO_Exceptions;  use Ada.IO_Exceptions;
with Strings_Edit.UTF8;  use Strings_Edit.UTF8;

with Parsers.Ada_Syntax_Analyzer.Declarations;
use  Parsers.Ada_Syntax_Analyzer.Declarations;

with Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;

with Parsers.Ada_Syntax_Analyzer.Statements;
use  Parsers.Ada_Syntax_Analyzer.Statements;

with Strings_Edit.UTF8.Categorization;
use  Strings_Edit.UTF8.Categorization;

with Strings_Edit.Lexicographical_Order;
use  Strings_Edit.Lexicographical_Order;

with Ada.Unchecked_Conversion;
with System.Storage_Elements;
with Parsers.Multiline_Source.Location_Text_IO;

with Ada.Tags;

package body Parsers.Ada_Syntax_Analyzer is

   --  function Inequal return Boolean is
   --     procedure Call_Stack is
   --        use Ada.Text_IO, GNAT.Traceback, GNAT.Traceback.Symbolic;
   --        TB : Tracebacks_Array (1..1_000); Len : Natural;
   --     begin
   --        Call_Chain (TB, Len);
   --        Put_Line (Symbolic_Traceback (TB (1..Len)));
   --     end Call_Stack;
   --  begin
   --     Call_Stack;
   --     raise Constraint_Error;
   --     return False;
   --  end Inequal;

   type Chunk_Specification_Ref is access all Chunk_Specification;
   type Compilation_Context_Ref is access all Compilation_Context'Class;
   type Identifier_List_Ref     is access all Identifier_List;
   type Parameter_Profile_Ref   is access all Parameter_Profile;
   type Singleton_Parameter_Ref is access all Singleton_Parameter;

   type Singleton_Parameter_Ptr is access constant Singleton_Parameter;
--
-- Sequence_Type -- The statement sequence type
--
--    Handled_Sequence   - Has an exception handlers
--    Handler_Sequence   - Enclosed by a handler
--    Action_Sequence    - Enclosed by an entry or accept statement
--    Task_Sequence      - Enclosed by a task body
--    Function_Sequence  - Enclosed by a function body
--    Procedure_Sequence - Enclosed by a procedure body
--
   type Sequence_Type is mod 2**6;
   Handled_Sequence   : constant Sequence_Type := 2**0;
   Handler_Sequence   : constant Sequence_Type := 2**1;
   Action_Sequence    : constant Sequence_Type := 2**2;
   Task_Sequence      : constant Sequence_Type := 2**3;
   Function_Sequence  : constant Sequence_Type := 2**4;
   Procedure_Sequence : constant Sequence_Type := 2**5;
   package Case_Alternatives_Stack is
      new Generic_Stack_Object (Case_Alternative);
   package Object_Specification_Stack is
      new Generic_Stack_Access
          (  Object_Specification,
             Object_Specification_Ptr
          );
   package Pragma_Argument_Association_Stack is
      new Generic_Stack_Object (Pragma_Argument_Association);
   package Select_Alternative_Stack is
      new Generic_Stack_Object (Select_Alternative);
   package Subtype_Mark_Stack is
      new Generic_Stack_Object (Subtype_Mark);

   type Loop_Body;
   type Loop_Body_Ptr is access all Loop_Body;
   type Loop_Body is record
      Enclosing : Loop_Body_Ptr;
      Statement : Loop_Statement_Ptr;
   end record;

   function Compare (Left, Right : Source_Description_Ptr)
      return Strings_Edit.Lexicographical_Order.Precedence is
      use Ada.Tags;
   begin
      if Left = null then
         if Right = null then
            return Equal;
         else
            return Less;
         end if;
      elsif Right = null then
         return Greater;
      elsif Left.all'Tag = Right.all'Tag then
         return Compare_Lexicographically
                (  Image (Left.all),
                   Image (Right.all)
                );
      else
         return Compare_Lexicographically
                (  Expanded_Name (Left.all'Tag),
                   Expanded_Name (Right.all'Tag)
                );
      end if;
   end Compare;

   function "=" (Left, Right : File_Location) return Boolean is
   begin
      return Compare (Left.File, Right.File) = Equal and then
             Left.Location = Right.Location;
   end "=";

   function "<" (Left, Right : File_Location) return Boolean is
   begin
      case Compare (Left.File, Right.File) is
         when Less =>
            return True;
         when Equal =>
            return Precedes (Left.Location, Right.Location);
         when Greater =>
            return False;
      end case;
   end "<";

   function "<" (Left, Right : Context_Location) return Boolean is
   begin
      if Left.Context = Right.Context then
         return Left.After < Right.After;
      elsif Right.Context = null then
         return False;
      elsif Left.Context = null then
         return False;
      else
         return Precedes (Left.Context.Scope, Right.Context.Scope);
      end if;
   end "<";

   function "<" (Left, Right : Defining_Identifier_Ptr)
      return Boolean is
      use System.Storage_Elements;
   begin
      if Right = null then
         return False;
      elsif Left = null then
         return True;
      else
         return To_Integer (Left.all'Address)
              < To_Integer (Right.all'Address);
      end if;
   end "<";

   function To_Context (Parameter : access Singleton_Parameter)
      return Compilation_Context_Ref is
      pragma Inline (To_Context);
      function To_Ref is new Ada.Unchecked_Conversion
                             (  Singleton_Parameter_Ptr,
                                Singleton_Parameter_Ref
                             );
      This : constant Singleton_Parameter_Ptr :=
                      Parameter.all'Unchecked_Access;
   begin
      return To_Ref (This).all'Unchecked_Access;
   end To_Context;

   procedure Add
             (  Context  : in out Ada_Program;
                Location : Context_Location;
                Name     : access Defining_Identifier
             )  is
   begin
      if Context.Xref = null then
         return;
      end if;
      declare
         use Cross_Reference_Tree;
         Xref : B_Tree renames Context.Xref.Identifiers;
         Item : constant Item_Ptr := Find (Xref, Name.Name);
      begin
         if Item = No_Item then
            declare
               type Arena_Ptr is access Defining_Identifier_List;
               for Arena_Ptr'Storage_Pool use Xref.Pool.all;
               Item : constant Arena_Ptr :=
                           new Defining_Identifier_List'
                               (  Count => 1,
                                  First => Name.all'Unchecked_Access,
                                  Last  => Name.all'Unchecked_Access
                               );
            begin
               if Is_Empty (Xref) and then Context.Stubs /= null then
                  --
                  -- Notify all stubs of the context
                  --
                  declare
                     This : Tree_Stub_Ptr := Context.Stubs;
                  begin
                     loop
                        if This.Contexts    and then
                           This.Mark = null and then
                           Context.Pool /= Xref.Pool
                        then
                           This.Contexts := False;
                        end if;
                        This := This.Next;
                        exit when This = Context.Stubs;
                     end loop;
                  end;
               end if;
               Add (Xref, Name.Name, Item.all'Unchecked_Access);
            end;
         else
            declare
               List : Defining_Identifier_List renames
                      Get_Value (Item).all;
            begin
               List.Count     := List.Count + 1;
               List.Last.Next := Name.all'Unchecked_Access;
               List.Last      := Name.all'Unchecked_Access;
            end;
         end if;
      end;
   end Add;

   procedure Add
             (  Context  : in out Ada_Program;
                Item     : in out Compilation_Context'Class;
                Location : Parsers.Multiline_Source.Location;
                File     : Source_Description_Ptr
             )  is
   begin
      if Context.Xref = null then
         return;
      end if;
      declare
         use Contexts_Reference;
         Xref : B_Tree renames Context.Xref.Contexts;
      begin
         if Is_Empty (Xref) and then Context.Stubs /= null then
            --
            -- Notify all stubs of the context
            --
            declare
               This : Tree_Stub_Ptr := Context.Stubs;
            begin
               loop
                  if This.Identifiers and then
                     This.Mark = null and then
                     Context.Pool /= Xref.Pool
                  then
                     This.Identifiers := False;
                  end if;
                  This := This.Next;
                  exit when This = Context.Stubs;
               end loop;
            end;
         end if;
         Item.Scope := Item.Scope & Location;
         Add (Xref, (File, Item.Scope), Item'Unchecked_Access);
      end;
   end Add;

   function Before (Code : Source'Class) return Location is
      Result : constant Location := Link (Code);
   begin
      return (Result.First, Result.First);
   end Before;

   procedure Finalize (Context : in out Ada_Program) is
   begin
      if Context.Stubs /= null then
         Raise_Exception
         (  Program_Error'Identity,
            "Syntax tree stubs still exist when parser is being " &
            "finalized"
         );
      end if;
   end Finalize;

   procedure Finalize (Stub : in out Tree_Stub) is
      use Cross_Reference_Tree;
      use Contexts_Reference;
   begin
      if Stub.Previous = null then
         return;
      end if;
      Stub.Previous.Next := Stub.Next;
      Stub.Next.Previous := Stub.Previous;
      Stub.Previous := null;
      Stub.Next     := null;
      if Stub.Context.Stubs = Stub'Unchecked_Access then
         Stub.Context.Stubs := Stub.Next;
      end if;
      if Stub.Identifiers and then Stub.Contexts then
         Erase (Stub.Context.Xref.Identifiers);
         Erase (Stub.Context.Xref.Contexts);
      else
         Raise_Exception
         (  Program_Error'Identity,
            "Syntax tree nodes being deleted are still " &
            "referenced in the cross-reference"
         );
      end if;
      Free (Stub.Context.all, Stub.Mark);
   end Finalize;

   function Has_Semicolon (Code : Source'Class) return Boolean is
      Line    : Line_Ptr;
      Last    : Integer;
      Pointer : Integer;
   begin
      Get_Line (Code, Line, Pointer, Last);
      return Pointer <= Last and then Line (Pointer) = ';';
   end Has_Semicolon;
--
-- Get_Anonymous_Access_Definition -- Get access definition
--
--    Context   - The context
--    Code      - The code
--    File      - The file description
--    Not_Null  - Has not null specified upfront
--    Parent    - The location in the compilation context
--    To_Object - True if 'access all' is acceptable
--
-- Returns :
--
--    The result
--
   function Get_Anonymous_Access_Definition
            (  Context   : access Ada_Program;
               Code      : access Source'Class;
               File      : Source_Description_Ptr;
               Not_Null  : Boolean;
               Parent    : Context_Location;
               To_Object : Boolean
            )  return Anonymous_Access_Definition;
--
-- Get_Array_Type_Definition -- Get array definition
--
--    Context - The context
--    Code    - The code
--    File    - The file description
--    Parent  - The location in the compilation context
--
   function Get_Array_Type_Definition
            (  Context : access Ada_Program;
               Code    : access Source'Class;
               File    : Source_Description_Ptr;
               Parent  : Context_Location
            )  return Array_Type_Specification_Ptr;
--
-- Get_Context -- Get function declaration or body
--
--    Context      - The context
--    Code         - The code
--    File         - The file description
--    Kind_Of      - The context type
--    Parent       - The location in the compilation context
--    Private_Unit - The context ends with a private unit declaration
--    Keyword      - That ends the context declaration
--    Result       - The result
--
   type Declaration_Context_Ref is access all Declaration_Context;
   procedure Get_Context
             (  Context      : in out Ada_Program;
                Code         : in out Source'Class;
                File         : Source_Description_Ptr;
                Kind_Of      : Compilation_Context_Type;
                Parent       : Context_Location;
                Private_Unit : out Boolean;
                Keyword      : out Reserved_Word;
                Result       : out Declaration_Context_Ref
             );
--
-- Get_Function -- Get function declaration or body
--
--    Context      - The context
--    Code         - The code
--    File         - The source description
--    Parent       - The compilation context, what is visible there
--    Separated    - The parent unit if separate
--    Private_Unit - Private declaration
--    Generic_Unit - Generic declaration
--    Overrides    - Overriding
--    Result       - The result
--
   procedure Get_Function
             (  Context      : in out Ada_Program;
                Code         : in out Source'Class;
                File         : Source_Description_Ptr;
                Parent       : Context_Location;
                Separated    : Parent_Unit;
                Private_Unit : Boolean;
                Generic_Unit : Boolean;
                Overrides    : Overriding_Indicator_Type;
                Result       : out Tokens.Argument_Token
             );
--
-- Get_Function_Profile -- Get function parameters profile
--
--    Context - The context
--    Code    - The code
--    File    - The source description
--    Parent  - The compilation context, what is visible there
--
-- Returns :
--
--    The profile and the result on the argument stack
--
   function Get_Function_Profile
            (  Context : access Ada_Program;
               Code    : access Source'Class;
               File    : Source_Description_Ptr;
               Parent  : Context_Location
            )  return Parameter_Profile_Ref;
--
-- Get_Generic -- Get generic declaration
--
--    Context - The context
--    Code    - The code
--    File    - The source description
--    Parent  - The compilation context, what is visible there
--    Result  - The result
--
   procedure Get_Generic
             (  Context : in out Ada_Program;
                Code    : in out Source'Class;
                File    : Source_Description_Ptr;
                Parent  : Context_Location;
                Result  : out Tokens.Argument_Token
             );
--
-- Get_Interfaces_List -- Get list of interfaces
--
--    Context - The context
--    Code    - The code
--    Prefix  - The list prefix: new, and
--
-- Returns :
--
--    The number of parents (interfaces)
--
   function Get_Interfaces_List
            (  Context : access Ada_Program;
               Code    : access Source'Class;
               Prefix  : String
            )  return Natural;
--
-- Get_Package -- Get package declaration or body
--
--    Context      - The context
--    Code         - The code
--    File         - The source description
--    Parent       - The compilation context, what is visible there
--    Separated    - The parent unit if separate
--    Private_Unit - Private declaration
--    Generic_Unit - Generic declaration
--    Result       - The result
--
   procedure Get_Package
             (  Context      : in out Ada_Program;
                Code         : in out Source'Class;
                File         : Source_Description_Ptr;
                Parent       : Context_Location;
                Separated    : Parent_Unit;
                Private_Unit : Boolean;
                Generic_Unit : Boolean;
                Result       : out Tokens.Argument_Token
             );
--
-- Get_Pragma -- Get name dot separated
--
--    Context - The context
--    Code    - The code
--    Result  - The pragma expression (contains Pragma_Clause)
--
   procedure Get_Pragma
             (  Context : in out Ada_Program;
                Code    : in out Source'Class;
                Result  : out Tokens.Argument_Token
             );
--
-- Get_Procedure -- Get procedure declaration or body
--
--    Context      - The context
--    Code         - The code
--    File         - The source description
--    Parent       - The compilation context, what is visible there
--    Separated    - The parent unit if separate
--    Private_Unit - Private declaration
--    Generic_Unit - Generic declaration
--    Overrides    - Overriding
--    Result       - The result
--
-- When Parent is null a library unit is expected.
--
   procedure Get_Procedure
             (  Context      : in out Ada_Program;
                Code         : in out Source'Class;
                File         : Source_Description_Ptr;
                Parent       : Context_Location;
                Separated    : Parent_Unit;
                Private_Unit : Boolean;
                Generic_Unit : Boolean;
                Overrides    : Overriding_Indicator_Type;
                Result       : out Tokens.Argument_Token
             );
--
-- Get_Procedure_Profile -- Get procedure parameters profile
--
--    Context - The context
--    Code      - The code
--    File      - The source description
--    Parent    - The compilation context
--    Unknown   - (<>) is allowed
--    No_Access - No access parameters allowed
--    Profile   - in, out, inout modes are allowed
--    Start     - The part of first parameter already parsed
--
-- Returns :
--
--    The result
--
   function Get_Procedure_Profile
            (  Context   : access Ada_Program;
               Code      : access Source'Class;
               File      : Source_Description_Ptr;
               Parent    : Context_Location;
               Unknown   : Boolean;
               No_Access : Boolean;
               Profile   : Boolean;
               Start     : Parameter_Part := (Part => Parameter_Name)
            )  return Parameter_Profile_Ref;
--
-- Get_Protected -- Get protected object declaration or body
--
--    Context   - The context
--    Code      - The code
--    File      - The source description
--    Parent    - The compilation context, what is visible there
--    Separated - The parent unit if separate
--    Result    - The result
--
   procedure Get_Protected
             (  Context   : in out Ada_Program;
                Code      : in out Source'Class;
                File      : Source_Description_Ptr;
                Parent    : Context_Location;
                Separated : Parent_Unit;
                Result    : out Tokens.Argument_Token
             );
--
-- Get_Sequence -- Get sequence of statements
--
--    Context   - The context
--    Code      - The code
--    File      - The source description
--    Parent    - The compilation context, what is visible there
--    Handled   - A handled sequence is expected
--    Enclosing - The enclosing loop
--    Keyword   - Cause of return
--    Result    - The statements sequence
--
   type Statement_Sequence_Ref is access all Statement_Sequence'Class;
   procedure Get_Sequence
             (  Context   : in out Ada_Program;
                Code      : in out Source'Class;
                File      : Source_Description_Ptr;
                Parent    : Context_Location;
                Handled   : Sequence_Type;
                Enclosing : Loop_Body_Ptr;
                Keyword   : out Reserved_Word;
                Result    : out Statement_Sequence_Ref
             );
--
-- Get_Separate -- Get separate body
--
--    Context - The context
--    Code    - The code
--    File    - The source description
--    Parent  - The compilation context, what is visible there
--    Result  - The result
--
   procedure Get_Separate
             (  Context : in out Ada_Program;
                Code    : in out Source'Class;
                File    : Source_Description_Ptr;
                Parent  : Context_Location;
                Result  : out Tokens.Argument_Token
             );
--
-- Get_Task -- Get task declaration or body
--
--    Context   - The context
--    Code      - The code
--    File      - The source description
--    Parent    - The compilation context, what is visible there
--    Separated - The parent unit if separate
--    Result    - The result
--
   procedure Get_Task
             (  Context   : in out Ada_Program;
                Code      : in out Source'Class;
                File      : Source_Description_Ptr;
                Parent    : Context_Location;
                Separated : Parent_Unit;
                Result    : out Tokens.Argument_Token
             );

   procedure Get_Semicolon
             (  Context : in out Ada_Program;
                Code    : in out Source'Class
             )  is
      Line    : Line_Ptr;
      Last    : Integer;
      Pointer : Integer;
   begin
      Get_Blank (Context, Code);
      Get_Line (Code, Line, Pointer, Last);
      if Pointer <= Last and then Line (Pointer) = ';' then
         Set_Pointer (Code, Pointer + 1);
      else
         Raise_Exception
         (  Syntax_Error'Identity,
            "Semicolon is expected at " & Image (Link (Code))
         );
      end if;
   end Get_Semicolon;

   procedure Check
             (  Context : in out Ada_Program;
                Code    : in out Source'Class;
                Name    : Tokens.Argument_Token
             )  is
      function Image (Name : Tokens.Argument_Token) return String is
      begin
         return Image (Name.Value.all, 80);
      end Image;
      Item : Tokens.Argument_Token;
   begin
      Lexers.Parse (Context, Code, Item);
      if Name.Value.all in Expression then
         declare
            This : Expression renames Expression (Name.Value.all);
         begin
            if Item.Value.all in Expression then
               declare
                  That : Expression renames Expression (Item.Value.all);
               begin
                  for Index in This.Operands'Range loop
                     if Index > That.Operands'Length then
                        Raise_Exception
                        (  Syntax_Error'Identity,
                           Image (This.Operands (Index)) &
                           " is expected at "            &
                           Image (Link (Code))
                        );
                     elsif (  Equal
                           /= Compare
                              (  This.Operands (Index).Value.all,
                                 That.Operands (Index).Value.all
                           )  )
                     then
                        Raise_Exception
                        (  Syntax_Error'Identity,
                           "'"                                    &
                           Image (This.Operands (Index))          &
                           "' at "                                &
                           Image (This.Operands (Index).Location) &
                           " is not matched by '"                 &
                           Image (That.Operands (Index))          &
                           "' at "                                &
                           Image (That.Operands (Index).Location)
                        );
                     end if;
                  end loop;
                  if That.Operands'Length > This.Operands'Length then
                     declare
                        Extra : constant Tokens.Argument_Token :=
                           That.Operands (That.Operands'Length + 1);
                     begin
                        Raise_Exception
                        (  Syntax_Error'Identity,
                           "Unexpected " &
                           Image (Extra) &
                           " found at "  &
                           Image (Extra.Location)
                        );
                     end;
                  end if;
               end;
            else
               Raise_Exception
               (  Syntax_Error'Identity,
                  Image (This.Operands (1)) &
                  " is expected at "        &
                  Image (This.Operands (1).Location)
               );
            end if;
         end;
      else
         if Equal /= Compare (Name.Value.all, Item.Value.all) then
            Raise_Exception
            (  Syntax_Error'Identity,
               "'"                    &
               Image (Name.Value.all) &
               "' at "                &
               Image (Name.Location)  &
               " is not matched by '" &
               Image (Item.Value.all) &
               "' at "                &
               Image (Item.Location)
            );
         end if;
      end if;
   end Check;

   procedure Check (This : Defining_Identifier) is
      use type System.Address;
   begin
      if This.Term.Value.all in Expression then
         declare
            Full : Expression renames Expression (This.Term.Value.all);
         begin
            if This.Name /= Named_Term'Class
                            (  Full.Operands (Full.Count).Value.all
                            ) 'Access
            then
               raise Constraint_Error;
            end if;
         end;
      else
         if This.Name /= Named_Term'Class
                         (  This.Term.Value.all
                         ) 'Access
         then
            raise Constraint_Error;
         end if;
      end if;
      if This.Declared.Context = null then
         return;
      end if;
      declare
         Context : Compilation_Context'Class renames
                   This.Declared.Context.all;
      begin
         if Get_Items_Number (Context) = This.Declared.After then
            return;
         end if;
         declare
            Item : constant Declaration_Ptr := Get (This.Declared);
         begin
            if (  (  This.Outer.all in Declaration_Node'Class
                  and then
                     (  Item
                     =  Declaration_Node'Class
                        (  This.Outer.all
                        ) 'Unchecked_Access
                  )  )
               or else
                  (  Item.all in Singleton_Parameter
                  and then
                     (  Singleton_Parameter
                        (  Item.all
                        ) .Name'Address
                     =  This'Address
               )  )  )  then
               return;
            end if;
            raise Constraint_Error;
         end;
      end;
   end Check;

   procedure Check_Identifier (Name : Tokens.Argument_Token) is
   begin
      if Name.Value.all not in Identifier then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Identifier is expected at " &
            Image (Name.Location)
         );
      end if;
   end Check_Identifier;

   procedure Check_Name
             (  Item       : Tokens.Argument_Token;
                No_Strings : Boolean := True
             )  is
      This : Node'Class renames Item.Value.all;
   begin
      if This in Expression then
         case Expression (This).Operation is
            when Component | Attribute | Left_Index =>
               return;
            when others =>
               null;
         end case;
      elsif This in Identifier then
         if Equal /= Compare (Identifier (This).Value, "null") then
            return;
         end if;
      elsif This in Character_Literal then
         if No_Strings then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Character literal is unexpected at " &
               Image (Item.Location)
            );
         end if;
         return;
      elsif This in String_Literal then
         if No_Strings then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "String literal is unexpected at " &
               Image (Item.Location)
            );
         elsif Get_Operator (Item) = Reserved then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Invalid operator symbol '"  &
               String_Literal (This).Value  &
               "' at "                      &
               Image (Item.Location)
            );
         end if;
         return;
      end if;
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "A name is expected at " & Image (Item.Location)
      );
   end Check_Name;

   procedure Check_Object (Item : Tokens.Argument_Token) is
      This : Node'Class renames Item.Value.all;
   begin
      if This in Expression then
         case Expression (This).Operation is
            when Component | Attribute | Left_Index =>
               return;
            when others =>
               null;
         end case;
      elsif This in Identifier then
         if Equal /= Compare (Identifier (This).Value, "null") then
            return;
         end if;
      end if;
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "An object or named value is expected at " &
         Image (Item.Location)
      );
   end Check_Object;

   procedure Check_Body_Stub
             (  Code    : Source'Class;
                Context : Context_Location;
                Text    : String
             )  is
   begin
      if Context.Context = null then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            Text                                      &
            " stub is not allowed in a library unit " &
            " context as found at "                   &
            Image (Link (Code))
         );
      elsif Context.Context.all not in Declaration_Context then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            Text                                   &
            " stub is not allowed in a parameter " &
            " declaration context as found at "    &
            Image (Link (Code))
         );
      end if;
      declare
         This : Declaration_Context renames
                Declaration_Context (Context.Context.all);
      begin
         if This.Kind_Of /= Code_Block_Context then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               Text                       &
               " stub is not allowed in " &
               Image (This.Kind_Of)       &
               " as found at "            &
               Image (Link (Code))
            );
         elsif not Is_Library_Unit (This.Parent) then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               Text                                  &
               " stub is found outside the outmost " &
               "declarative part at "                &
               Image (Link (Code))
            );
         end if;
      end;
   end Check_Body_Stub;

   function Equal
            (  Left  : Context_Location;
               Right : Context_Location;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Left.After /= Right.After then
         return Inequal;
      elsif (Left.Context = null) /= (Right.Context = null) then
         return Inequal;
      end if;
      if Left.Context /= null then
         if 0 /= (Follow_Links and Mode) then
            return Equal
                   (  Left.Context.all,
                      Right.Context.all,
                      Mode and not Follow_Links
                   );
         end if;
      end if;
      return True;
   end Equal;

   function Equal
            (  Left  : Defining_Identifier;
               Right : Defining_Identifier;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      Check (Left);
      Check (Right);
      if Left.Outer = null or else Right.Outer = null then
         raise Constraint_Error;
      end if;
      if not Equal (Left.Term, Right.Term, Mode) then
         return Inequal;
      elsif Left.Declared.After /= Right.Declared.After then
         return Inequal;
      elsif Program_Node_Class'(Get_Class (Left.Outer.all)) /=
            Program_Node_Class'(Get_Class (Right.Outer.all)) then
         return Inequal;
      elsif 0 /= (Follow_Links and Mode) then
         if not Equal
                (  Left.Declared,
                   Right.Declared,
                   Mode and not Follow_Links
                )  then
            return Inequal;
         end if;
       end if;
       return True;
   end Equal;

   function Get (Context : Context_Location) return Declaration_Ptr is
   begin
      return Get_Item (Context.Context.all, Context.After + 1);
   end Get;

   function Get_Class  (Item : Program_Node) return Node_Class is
   begin
      return Term_Node;
   end Get_Class;

   procedure Get_Enumeration_Literal
             (  Context : in out Ada_Program;
                Code    : in out Source'Class;
                Result  : out Tokens.Argument_Token
             )  is
      Line    : Line_Ptr;
      Pointer : Integer;
      Last    : Integer;
   begin
      Get_Blank (Context, Code);
      Get_Line (Code, Line, Pointer, Last);
      if Pointer > Last then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Identifier or character literal is expected at " &
            Image (Link (Code))
         );
      end if;
      if Line (Pointer) = ''' then
         declare
            Symbol : UTF8_Code_Point;
            Start  : constant Integer := Pointer;
         begin
            Set_Pointer (Code, Pointer);
            Pointer := Pointer + 1;
            Get (Line (Pointer..Last), Pointer, Symbol);
            if Pointer > Last or else Line (Pointer) /= ''' then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Ampersand is expected at " & Image (Link (Code))
               );
            end if;
            Result.Value :=
               new Identifier'
                   (  Length    => 3,
                      Malformed => False,
                      Value     => Line (Start..Pointer)
                   );
            Pointer := Pointer + 1;
            Set_Pointer (Code, Pointer);
            Result.Location := Link (Code);
         exception
            when Data_Error =>
               Set_Pointer (Code, Pointer);
               Set_Pointer (Code, Pointer);
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  Encoding_Error & Image (Link (Code))
               );
         end;
      else
         declare
            Index  : Integer := Pointer;
            Symbol : UTF8_Code_Point;
         begin
            Get (Line (Pointer..Last), Index, Symbol);
            if not Is_Identifier_Start (Symbol) then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Identifier is expected at " &
                  Image (Link (Code))
               );
            end if;
         exception
            when Data_Error =>
               Set_Pointer (Code, Pointer);
               Set_Pointer (Code, Pointer);
               Raise_Exception
               (  Syntax_Error'Identity,
                  Encoding_Error & Image (Link (Code))
               );
         end;
         Get_Identifier
         (  Context,
            Code,
            Line (Pointer..Last),
            Pointer,
            Result
         );
      end if;
   end Get_Enumeration_Literal;

   function Get_Parameter_Type
            (  Context            : access Ada_Program;
               Code               : access Source'Class;
               File               : Source_Description_Ptr;
               Parent             : Context_Location;
               Composite          : Boolean := False;
               Aliased_Parameter  : Boolean := False;
               Constant_Parameter : Boolean := False
            )  return Parameter_Type is
      Got_It   : Boolean;
      Not_Null : Boolean := False;
   begin
      Get_Not_Null (Context.all, Code.all, Not_Null);
      Get_Blank (Context.all, Code.all);
      Get_Delimited (Code.all, "access", True, Got_It);
      if Got_It then
         declare
            Item : constant Anonymous_Access_Definition :=
                            Get_Anonymous_Access_Definition
                            (  Context   => Context,
                               Code      => Code,
                               File      => File,
                               Not_Null  => Not_Null,
                               Parent    => Parent,
                               To_Object => False
                            );
         begin
            case Item.Mode is
               when Access_To_All =>
                  return (  Present            => True,
                            Aliased_Parameter  => Aliased_Parameter,
                            Constant_Parameter => Constant_Parameter,
                            Mode               => Access_To_All,
                            Access_Parameter   => Item
                         );
               when Access_To_Constant =>
                  return (  Present            => True,
                            Aliased_Parameter  => Aliased_Parameter,
                            Constant_Parameter => Constant_Parameter,
                            Mode               => Access_To_Constant,
                            Access_Parameter   => Item
                         );
               when Access_To_Variable =>
                  return (  Present            => True,
                            Aliased_Parameter  => Aliased_Parameter,
                            Constant_Parameter => Constant_Parameter,
                            Mode               => Access_To_Variable,
                            Access_Parameter   => Item
                         );
               when Access_To_Procedure =>
                  return (  Present            => True,
                            Aliased_Parameter  => Aliased_Parameter,
                            Constant_Parameter => Constant_Parameter,
                            Mode               => Access_To_Procedure,
                            Access_Parameter   => Item
                         );
               when Access_To_Protected_Procedure =>
                  return (  Present            => True,
                            Aliased_Parameter  => Aliased_Parameter,
                            Constant_Parameter => Constant_Parameter,
                            Mode               =>
                               Access_To_Protected_Procedure,
                            Access_Parameter   => Item
                         );
               when Access_To_Function =>
                  return (  Present            => True,
                            Aliased_Parameter  => Aliased_Parameter,
                            Constant_Parameter => Constant_Parameter,
                            Mode               => Access_To_Function,
                            Access_Parameter   => Item
                         );
               when Access_To_Protected_Function =>
                  return (  Present            => True,
                            Aliased_Parameter  => Aliased_Parameter,
                            Constant_Parameter => Constant_Parameter,
                            Mode               =>
                               Access_To_Protected_Function,
                            Access_Parameter   => Item
                         );
            end case;
         end;
      else
         declare
            Item : Subtype_Indication;
         begin
            Get_Subtype_Indication
            (  Context   => Context.all,
               Code      => Code.all,
               Composite => Composite,
               Not_Null  => Not_Null,
               Argument  => Item
            );
            return (  Present            => True,
                      Aliased_Parameter  => Aliased_Parameter,
                      Constant_Parameter => Constant_Parameter,
                      Mode               => Object_Mode,
                      Object_Parameter   => Item
                  );
         end;
      end if;
   end Get_Parameter_Type;

   function Get_Trace_File (Context : Ada_Program)
      return Ada.Text_IO.File_Access is
   begin
      return Context.Trace;
   end Get_Trace_File;

   function Image (Item : Context_Location) return String is
   begin
      if Item.Context = null then
         return "";
      else
         return Image (Item.Context.all);
      end if;
   end Image;

   function Image (Location : File_Location) return String is
   begin
      if Location.File = null then
         return Image (Location.Location);
      else
         return Image (Location.File.all) &
                '#'                       &
                Image (Location.Location);
      end if;
   end Image;

   function Image (Source : File_Path) return String is
   begin
      return Source.Path;
   end Image;

   function Image
            (  Indicator : Overriding_Indicator_Type;
               Suffix    : String := ""
            )  return String is
   begin
      case Indicator is
         when No_Indicator =>
            return "";
         when Overriding_Indicator =>
            return "overriding" & Suffix;
         when Not_Overriding_Indicator =>
            return "not overriding" & Suffix;
      end case;
   end Image;

   procedure Initialize (Stub : in out Tree_Stub) is
   begin
      if Stub.Context.Stubs = null then
         Stub.Context.Stubs := Stub'Unchecked_Access;
         Stub.Previous      := Stub'Unchecked_Access;
         Stub.Next          := Stub'Unchecked_Access;
      else
         Stub.Next          := Stub.Context.Stubs.Previous;
         Stub.Previous      := Stub.Next.Previous;
         Stub.Next.Previous := Stub'Unchecked_Access;
         Stub.Previous.Next := Stub'Unchecked_Access;
      end if;
      Push_Stub (Stub.Context.all, Stub.Mark);
   end Initialize;

   function Get_Kind_Of
            (  Unit : Context_Location
            )  return Compilation_Context_Type is
   begin
      if Unit.Context = null then
         return Library_Unit_Context;
      elsif Unit.Context.all in Declaration_Context then
         return Declaration_Context (Unit.Context.all).Kind_Of;
      else
         return Library_Unit_Context;
      end if;
   end Get_Kind_Of;

   function Is_Formal_Generic (Unit : Context_Location)
      return Boolean is
   begin
      return Get_Kind_Of (Unit) = Generic_Formal_Parameters_Context;
   end Is_Formal_Generic;

   function Is_Library_Unit (Item : Context_Location)
      return Boolean is
   begin
      if Item.Context = null then
         return True;
      elsif Item.Context.all in Declaration_Context then
         return Is_Library_Unit
                (  Declaration_Context (Item.Context.all)
                );
      else
         return False;
      end if;
   end Is_Library_Unit;
--
-- Set -- Defining identifier
--
--    Context  - The context
--    Name     - The name
--    Location - The location of the defining identifier
--    File     - The source description
--    Node     - The parent declaration node
--    Item     - The result
--
   procedure Set
             (  Context  : in out Ada_Program;
                Name     : Tokens.Argument_Token;
                Location : Context_Location;
                File     : Source_Description_Ptr;
                Node     : Program_Node'Class;
                Item     : access Defining_Identifier
             )  is
   begin
      if Name.Value.all in Expression then -- Full name, take the last
         declare
            List : Argument_List renames
                   Expression (Name.Value.all).Operands;
         begin
            Item.Name := Named_Term (List (List'Last).Value.all)'Access;
         end;
      else
         Item.Name := Named_Term (Name.Value.all)'Access;
      end if;
      Item.Term     := Name;
      Item.Declared := Location;
      Item.File     := File;
      Item.Outer    := Node'Unchecked_Access;
      Add (Context, Location, Item);
   end Set;

   procedure Set_Trace_File
             (  Context : in out Ada_Program;
                File    : Ada.Text_IO.File_Access := null
             )  is
   begin
      Context.Trace := File;
   end Set_Trace_File;

   procedure Pop
             (  Context : in out Ada_Program;
                Parent  : Context_Location;
                File    : Source_Description_Ptr;
                Node    : Program_Node'Class;
                List    : out Defining_Identifier_Array
             )  is
      use Tokens.Arguments;
      Item : Frame (1..1);
   begin
      for Index in reverse List'Range loop
         Pop (Context, Item);
         Set
         (  Context,
            Item (1),
            Parent,
            File,
            Node, List (Index)'Access
         );
      end loop;
   end Pop;

   procedure Pop
             (  Context : in out Ada_Program;
                Aspect  : out Guarded_List
             )  is
      use Tokens.Arguments;
      List : Frame (1..2);
   begin
      for Index in reverse Aspect'Range loop
         Pop (Context, List);
         Aspect (Index) := (Guard => List (1), Value => List (2));
      end loop;
   end Pop;

   procedure Pop
             (  Context : in out Ada_Program;
                List    : out Subtype_Mark_Array
             )  is
      use Subtype_Mark_Stack;
   begin
      for Index in reverse List'Range loop
         Pop (Context, List (Index));
      end loop;
   end Pop;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Argument_List;
                Prefix      : String;
                Delimiter   : String;
                Suffix      : String
             )  is
      use Strings_Edit;
      Index : Integer := Pointer;
   begin
      if List'Length = 0 then
         return;
      else
         Put (Destination, Index, Prefix);
         for Item in List'Range loop
            if Item > List'First then
               Put (Destination, Index, Delimiter);
            end if;
            Put (Destination, Index, List (Item));
         end loop;
         Put (Destination, Index, Suffix);
         Pointer := Index;
      end if;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Context_Location
             )  is
   begin
      if Item.Context /= null then
         Put (Destination, Pointer, Item.Context.all);
      end if;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Defining_Identifier
             )  is
   begin
      Put (Destination, Pointer, Item.Name.all);
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Defining_Identifier_Array;
                Prefix      : String;
                Delimiter   : String;
                Suffix      : String
             )  is
      use Strings_Edit;
      Index : Integer := Pointer;
   begin
      if List'Length = 0 then
         return;
      else
         Put (Destination, Index, Prefix);
         for Item in List'Range loop
            if Item > List'First then
               Put (Destination, Index, Delimiter);
            end if;
            Put (Destination, Index, List (Item));
         end loop;
         Put (Destination, Index, Suffix);
         Pointer := Index;
      end if;
   end Put;

   function Ref
            (  Context : access constant Compilation_Context'Class;
               At_End  : Boolean := True
            )  return Context_Location is
   begin
      if At_End then
         return
         (  Context => Context.all'Unchecked_Access,
            After   => Get_Items_Number (Context.all)
         );
      else
         return
         (  Context => Context.all'Unchecked_Access,
            After   => 0
         );
      end if;
   end Ref;
------------------------------------------------------------------------
   function Get_Anonymous_Access_Definition
            (  Context   : access Ada_Program;
               Code      : access Source'Class;
               File      : Source_Description_Ptr;
               Not_Null  : Boolean;
               Parent    : Context_Location;
               To_Object : Boolean
            )  return Anonymous_Access_Definition is separate;
   function Get_Array_Type_Definition
            (  Context : access Ada_Program;
               Code    : access Source'Class;
               File    : Source_Description_Ptr;
               Parent  : Context_Location
            )  return Array_Type_Specification_Ptr is separate;
   procedure Get_Context
             (  Context      : in out Ada_Program;
                Code         : in out Source'Class;
                File         : Source_Description_Ptr;
                Kind_Of      : Compilation_Context_Type;
                Parent       : Context_Location;
                Private_Unit : out Boolean;
                Keyword      : out Reserved_Word;
                Result       : out Declaration_Context_Ref
             )  is separate;
   procedure Get_Function
             (  Context      : in out Ada_Program;
                Code         : in out Source'Class;
                File         : Source_Description_Ptr;
                Parent       : Context_Location;
                Separated    : Parent_Unit;
                Private_Unit : Boolean;
                Generic_Unit : Boolean;
                Overrides    : Overriding_Indicator_Type;
                Result       : out Tokens.Argument_Token
             )  is separate;
   function Get_Function_Profile
            (  Context : access Ada_Program;
               Code    : access Source'Class;
               File    : Source_Description_Ptr;
               Parent  : Context_Location
            )  return Parameter_Profile_Ref is separate;
   procedure Get_Generic
             (  Context : in out Ada_Program;
                Code    : in out Source'Class;
                File    : Source_Description_Ptr;
                Parent  : Context_Location;
                Result  : out Tokens.Argument_Token
             )  is separate;
   function Get_Interfaces_List
            (  Context : access Ada_Program;
               Code    : access Source'Class;
               Prefix  : String
            )  return Natural is separate;
   procedure Get_Package
             (  Context      : in out Ada_Program;
                Code         : in out Source'Class;
                File         : Source_Description_Ptr;
                Parent       : Context_Location;
                Separated    : Parent_Unit;
                Private_Unit : Boolean;
                Generic_Unit : Boolean;
                Result       : out Tokens.Argument_Token
             )  is separate;
   procedure Get_Procedure
             (  Context      : in out Ada_Program;
                Code         : in out Source'Class;
                File         : Source_Description_Ptr;
                Parent       : Context_Location;
                Separated    : Parent_Unit;
                Private_Unit : Boolean;
                Generic_Unit : Boolean;
                Overrides    : Overriding_Indicator_Type;
                Result       : out Tokens.Argument_Token
             )  is separate;
   function Get_Procedure_Profile
            (  Context   : access Ada_Program;
               Code      : access Source'Class;
               File      : Source_Description_Ptr;
               Parent    : Context_Location;
               Unknown   : Boolean;
               No_Access : Boolean;
               Profile   : Boolean;
               Start     : Parameter_Part := (Part => Parameter_Name)
            )  return Parameter_Profile_Ref is separate;
   procedure Get_Pragma
             (  Context : in out Ada_Program;
                Code    : in out Source'Class;
                Result  : out Tokens.Argument_Token
             )  is separate;
   procedure Get_Protected
             (  Context   : in out Ada_Program;
                Code      : in out Source'Class;
                File      : Source_Description_Ptr;
                Parent    : Context_Location;
                Separated : Parent_Unit;
                Result    : out Tokens.Argument_Token
             )  is separate;
   procedure Get_Separate
             (  Context : in out Ada_Program;
                Code    : in out Source'Class;
                File    : Source_Description_Ptr;
                Parent  : Context_Location;
                Result  : out Tokens.Argument_Token
             )  is separate;
   procedure Get_Sequence
             (  Context   : in out Ada_Program;
                Code      : in out Source'Class;
                File      : Source_Description_Ptr;
                Parent    : Context_Location;
                Handled   : Sequence_Type;
                Enclosing : Loop_Body_Ptr;
                Keyword   : out Reserved_Word;
                Result    : out Statement_Sequence_Ref
             )  is separate;
   procedure Get_Task
             (  Context   : in out Ada_Program;
                Code      : in out Source'Class;
                File      : Source_Description_Ptr;
                Parent    : Context_Location;
                Separated : Parent_Unit;
                Result    : out Tokens.Argument_Token
             )  is separate;
   function Parse
            (  Context : access Ada_Program;
               Code    : access Source'Class;
               File    : Source_Description_Ptr := null
            )  return Tokens.Argument_Token is separate;
------------------------------------------------------------------------
-- Cross-reference of contexts, operations
--
   function Find
            (  Xref     : Cross_Reference;
               Name     : String;
               Location : Parsers.Multiline_Source.Location;
               File     : Source_Description_Ptr := null
            )  return Context_Location_Sets.Set is
      use Context_Location_Sets;
      use Cross_Reference_Tree;
      Result : Context_Location_Sets.Set;
      Item   : constant Identifier_Entry := Get (Xref, Name);
      This   : Defining_Identifier_Ptr;
   begin
      if Item = No_Identifier then
         return Result;
      end if;
      This := Get_First (Item);
      loop
         declare
            Context : Compilation_Context'Class renames
                      This.Declared.Context.all;
         begin
            if Contains (Context.Scope, Location) then
               if Context in Declaration_Context then
                  declare
                     Parent   : Declaration_Context renames
                                Declaration_Context (Context);
                     Position : constant Positive :=
                                         This.Declared.After + 1;
                  begin
                     if Get_Items_Number (Parent) < Position or else
                        (  Get_Item (Parent, Position).Location.Next
                        <= Location.First
                        )
                     then
                        Add (Result, This);
                     end if;
                  end;
               else
                  Add (Result, This);
               end if;
            end if;
         end;
         This := This.Next;
         exit when This = null;
      end loop;
      return Result;
   end Find;

   function Get
            (  Xref     : Cross_Reference;
               Location : Parsers.Multiline_Source.Location;
               File     : Source_Description_Ptr := null
            )  return Context_Entry is
      use Contexts_Reference;
      Result : constant Item_Ptr :=
                        Inf (Xref.Contexts, (File, Location));
   begin
      if Result = No_Item then
         return (Item => No_Item);
      elsif Contains (Get_Value (Result).Scope, Location) then
         return (Item => Result);
      else
         return (Item => No_Item);
      end if;
   end Get;

   function Get_Context (Item : Context_Entry)
      return Compilation_Context_Ptr is
      use Contexts_Reference;
   begin
      if Item.Item = No_Item then
         return null;
      else
         return Get_Value (Item.Item).all'Unchecked_Access;
      end if;
   end Get_Context;

   function Get_First (Xref : Cross_Reference) return Context_Entry is
      use Contexts_Reference;
   begin
      return (Item => Get_First (Xref.Contexts));
   end Get_First;

   function Get_Last (Xref : Cross_Reference) return Context_Entry is
      use Contexts_Reference;
   begin
      return (Item => Get_Last (Xref.Contexts));
   end Get_Last;

   function Get_Location (Item : Context_Entry) return Location is
      use Contexts_Reference;
   begin
      if Item.Item = No_Item then
         raise Constraint_Error;
      else
         return Get_Key (Item.Item).Location;
      end if;
   end Get_Location;

   function Get_Next (Item : Context_Entry) return Context_Entry is
      use Contexts_Reference;
   begin
      return (Item => Get_Next (Item.Item));
   end Get_Next;

   function Get_Previous (Item : Context_Entry) return Context_Entry is
      use Contexts_Reference;
   begin
      return (Item => Get_Previous (Item.Item));
   end Get_Previous;

   procedure Get_Scope
             (  Item     : Context_Entry;
                File     : out Source_Description_Ptr;
                Location : out Parsers.Multiline_Source.Location
             )  is
      use Contexts_Reference;
   begin
      if Item.Item = No_Item then
         raise Constraint_Error;
      else
         declare
            Result : constant File_Location := Get_Key (Item.Item);
         begin
            File     := Result.File;
            Location := Result.Location;
         end;
      end if;
   end Get_Scope;

   function Precedes (Left, Right : Location) return Boolean is
   begin
      if Left.First < Right.First then
         return True;
      elsif Left.First = Right.First then
         return Left.Next > Right.Next;
      else
         return False;
      end if;
   end Precedes;
------------------------------------------------------------------------
-- Cross-reference of defining identifiers, operations
--
   function Equal (Left, Right : Named_Term_Ptr) return Boolean is
   begin
      if Left = Right then
         return True;
      elsif Left = null or Right = null then
         return False;
      else
         return Compare (Left.Value, Right.Value) = Equal;
      end if;
   end Equal;

   function Get
            (  Xref : Cross_Reference;
               Name : String
            )  return Identifier_Entry is
      use Cross_Reference_Tree;
      Term : aliased String_Literal (Name'Length);
      Item : Item_Ptr;
   begin
      Term.Value := Name;
      Item := Find (Xref.Identifiers, Term'Unchecked_Access);
      if Item = No_Item then
         return No_Identifier;
      else
         return (Item => Item);
      end if;
   end Get;

   function Get_First (Xref : Cross_Reference)
      return Identifier_Entry is
      use Cross_Reference_Tree;
   begin
      return (Item => Get_First (Xref.Identifiers));
   end Get_First;

   function Get_First (Item : Identifier_Entry)
      return Defining_Identifier_Ptr is
      use Cross_Reference_Tree;
   begin
      if Item = No_Identifier then
         raise Constraint_Error;
      else
         return Get_Value (Item.Item).First.all'Unchecked_Access;
      end if;
   end Get_First;

   function Get_Identifiers_Number (Item : Identifier_Entry)
      return Natural is
      use Cross_Reference_Tree;
   begin
      if Item = No_Identifier then
         return 0;
      else
         return Get_Value (Item.Item).Count;
      end if;
   end Get_Identifiers_Number;

   function Get_Last (Xref : Cross_Reference)
      return Identifier_Entry is
      use Cross_Reference_Tree;
   begin
      return (Item => Get_Last (Xref.Identifiers));
   end Get_Last;

   function Get_Last (Item : Identifier_Entry)
      return Defining_Identifier_Ptr is
      use Cross_Reference_Tree;
   begin
      if Item = No_Identifier then
         raise Constraint_Error;
      else
         return Get_Value (Item.Item).Last.all'Unchecked_Access;
      end if;
   end Get_Last;

   function Get_Name (Item : Identifier_Entry) return String is
      use Cross_Reference_Tree;
   begin
      if Item = No_Identifier then
         raise Constraint_Error;
      else
         return Get_Key (Item.Item).Value;
      end if;
   end Get_Name;

   function Get_Next (Item : Identifier_Entry)
      return Identifier_Entry is
      use Cross_Reference_Tree;
   begin
      return (Item => Get_Next (Item.Item));
   end Get_Next;

   function Get_Previous (Item : Identifier_Entry)
      return Identifier_Entry is
      use Cross_Reference_Tree;
   begin
      return (Item => Get_Previous (Item.Item));
   end Get_Previous;

   function Less (Left, Right : Named_Term_Ptr)
      return Boolean is
   begin
      if Left = Right or else Right = null then
         return False;
      elsif Left = null then
         return True;
      else
         return Compare (Left.Value, Right.Value) = Less;
      end if;
   end Less;

   function "="
            (  Left  : Context_Location;
               Right : Declaration_Node'Class
            )  return Boolean is
   begin
      if Left.Context = null then
         return False;
      end if;
      declare
         Context : Compilation_Context'Class renames Left.Context.all;
         Length  : constant Natural := Get_Items_Number (Context);
      begin
         if Left.After < Length then
            return Get_Item (Context, Left.After + 1)
                 = Right'Unchecked_Access;
         elsif Left.After = Length then
            return True;
         else
            return False;
         end if;
      end;
   end "=";

end Parsers.Ada_Syntax_Analyzer;
