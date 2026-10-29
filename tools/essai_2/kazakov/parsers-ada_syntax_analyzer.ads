--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer                 Luebeck            --
--  Interface                                      Spring, 2026       --
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

with Ada.Finalization;
with Ada.Text_IO;

with System.Storage_Pools;      use System.Storage_Pools;
with Parsers.Multiline_Source;  use Parsers.Multiline_Source;

with Generic_Set;
with Parsers.Generic_Ada_Parser;
with Parsers.Generic_Arena_B_Tree;
with Strings_Edit.Lexicographical_Order;

package Parsers.Ada_Syntax_Analyzer is

   Cross_Reference_Bucket_Size : constant := 1024;
--
-- Precedes -- Order of location according to nesing
--
--    Left, Right - Location to compare
--
-- The  locations  are ordered  as following so that a location precedes
-- another if it indicates a source interval preceding than the later or
-- else contains it.
--
-- Returns :
--
--    The result
--
   function Precedes (Left, Right : Location) return Boolean;
--
-- Compilation_Context -- A declarative region
--
   type Compilation_Context;
   type Compilation_Context_Ptr is
      access constant Compilation_Context'Class;
--
-- Defining_Identifier -- ARM 3.1
--
   type Defining_Identifier;
   type Defining_Identifier_Ptr is access constant Defining_Identifier;
   function "<" (Left, Right : Defining_Identifier_Ptr) return Boolean;
--
-- Context_Location -- Location of a declaration item in a context
--
--    Context - The context
--    After   - The number of context item preceding this one
--
   type Context_Location is record
      Context : Compilation_Context_Ptr;
      After   : Natural := 0;
   end record;
   function "<" (Left, Right : Context_Location) return Boolean;
--
-- Context_Location_Sets -- Sets of context location
--
   package Context_Location_Sets is
      new Generic_Set (Defining_Identifier_Ptr, null);
--
-- Source_Description -- Source description base type
--
-- The object  is  attached  to  defining  identifiers  to  indicate the
-- location of the source, e.g. a file name.
--
   type Source_Description is abstract tagged null record;
   function Image (Source : Source_Description)
      return String is abstract;
--
-- File_Path -- Simple source description containing a file path
--
   type File_Path (Length : Natural) is
      new Source_Description with
   record
      Path : String (1..Length);
   end record;
   function Image (Source : File_Path) return String;

   type Source_Description_Ptr is
      access constant Source_Description'Class;
   function Compare (Left, Right : Source_Description_Ptr)
      return Strings_Edit.Lexicographical_Order.Precedence;
--
-- Cross_Reference -- The cross-reference of parsed syntax tree
--
--    Pool - The arena to allocate the cross-reference
--
   type Cross_Reference
        (  Pool : access Root_Storage_Pool'Class
        )  is new Ada.Finalization.Limited_Controlled with private;
   type Cross_Reference_Ptr is access all Cross_Reference'Class;
--
-- Find -- Possible interpretations of a name
--
--    Xref     - Cross-reference
--    Name     - The name
--    Location - The location of the name
--    File     - The source description (null for current file)
--
-- This function  walks up  the chain of contexts where Name is directly
-- visible.
--
-- Returns :
--
--    The set of defining identifier locations
--
   function Find
            (  Xref     : Cross_Reference;
               Name     : String;
               Location : Parsers.Multiline_Source.Location;
               File     : Source_Description_Ptr := null
            )  return Context_Location_Sets.Set;
------------------------------------------------------------------------
-- Identifier_Entry -- An entry in the cross-reference.  An entry in the
--                     cross-reference    corresponds   to   identifiers
-- declared in the source code sharing the same name. The member Next in
-- Defining_Identifier indicates the next instance in the same entry.
--
   type Identifier_Entry is private;
   No_Identifier : constant Identifier_Entry;
--
-- Get -- Cross-reference entry by name
--
--    Xref - cross-reference
--    Name - The name to look for
--
-- Returns :
--
--    The entry or No_Identifier
--
   function Get
            (  Xref : Cross_Reference;
               Name : String
            )  return Identifier_Entry;
--
-- Get_First -- The first cross-reference entry or context
--
--    Xref - Cross-reference
--
-- Returns :
--
--    The first entry or No_Identifier or first context or null
--
   function Get_First (Xref : Cross_Reference) return Identifier_Entry;
--
-- Get_First -- The first defining identifier in the entry
--
--    Item - Cross-reference entry
--
-- Returns :
--
--    The first defining identifier
--
-- Exceptions :
--
--    Constraint_Error - When Item is No_Identifier
--
   function Get_First (Item : Identifier_Entry)
      return Defining_Identifier_Ptr;
--
-- Get_Identifiers_Number -- The number  of defining  identifiers in the
--                           entry
--
--    Item - Cross-reference entry
--
-- Returns :
--
--    The number of identifiers
--
   function Get_Identifiers_Number (Item : Identifier_Entry)
      return Natural;
--
-- Get_Last -- The last cross-reference entry
--
--    Xref - Cross-reference
--
-- Returns :
--
--    The last entry or No_Identifier or last context or null
--
   function Get_Last (Xref : Cross_Reference) return Identifier_Entry;
--
-- Get_Last -- The last defining identifier in the entry
--
--    Item - Cross-reference entry
--
-- Returns :
--
--    The Last defining identifier
--
-- Exceptions :
--
--    Constraint_Error - When Item is No_Identifier
--
   function Get_Last (Item : Identifier_Entry)
      return Defining_Identifier_Ptr;
--
-- Get_Name -- The entry name
--
--    Item - Cross-reference entry
--
-- Returns :
--
--    The name of defining identifiers in the entry
--
-- Exceptions :
--
--    Constraint_Error - When Item is No_Identifier
--
   function Get_Name (Item : Identifier_Entry) return String;
--
-- Get_Next -- The next cross-reference entry
--
--    Item - The cross-reference or entry
--
-- Returns :
--
--    The next entry or No_Identifier, if none
--
   function Get_Next (Item : Identifier_Entry) return Identifier_Entry;
--
-- Get_Previous -- The previous cross-reference entry
--
--    Item - The entry
--
-- Returns :
--
--    The previous entry or No_Identifier if none
--
   function Get_Previous (Item : Identifier_Entry)
      return Identifier_Entry;
------------------------------------------------------------------------
-- Context_Entry -- An entry  in the cross-reference  corresponds  to  a
--                  declarative  region  and  its  scope.  Entries   are
-- ordered in the textual order of the scopes where context declarations
-- are directly visible. Note the difference  between  the  location  of
-- declarations and the scope where these become visible.
--
   type Context_Entry is private;
   No_Context : constant Context_Entry;
--
-- Get -- Context by location
--
--    Xref     - Cross-reference
--    Location - The source location
--    File     - The source file
--
-- Returns :
--
--    The most narrow context containing the location or No_Context
--
   function Get
            (  Xref     : Cross_Reference;
               Location : Parsers.Multiline_Source.Location;
               File     : Source_Description_Ptr := null
            )  return Context_Entry;
--
-- Get_Context -- Context corresponding to the entry
--
--    Item - The entry
--
-- Returns :
--
--    The context
--
-- Exceptions :
--
--    Constraint_Error - Item is No_Context
--
   function Get_Context (Item : Context_Entry)
      return Compilation_Context_Ptr;
--
-- Get_First -- The first cross-reference entry or context
--
--    Xref - Cross-reference
--
-- Returns :
--
--    The first entry or No_Context
--
   function Get_First (Xref : Cross_Reference) return Context_Entry;
--
-- Get_Last -- The last cross-reference entry
--
--    Xref - Cross-reference
--
-- Returns :
--
--    The last entry or No_Identifier or last context or null
--
   function Get_Last (Xref : Cross_Reference) return Context_Entry;
--
-- Get_Location -- Directly visibility area of the context
--
--    Item - The entry
--
-- Returns :
--
--    The location (for source file see Get_Scope)
--
-- Exceptions :
--
--    Constraint_Error - Item is No_Context
--
   function Get_Location (Item : Context_Entry) return Location;
--
-- Get_Next -- The next cross-reference entry
--
--    Item - The entry
--
-- Returns :
--
--    The next entry or No_Context
--
   function Get_Next (Item : Context_Entry) return Context_Entry;
--
-- Get_Previous -- The previous cross-reference entry
--
--    Item - The entry
--
-- Returns :
--
--    The previous entry or No_Context
--
   function Get_Previous (Item : Context_Entry) return Context_Entry;
--
-- Get_Scope -- Directly visibility area of the context
--
--    Item     - The entry
--    File     - The source file description
--    Location - The source location, null if the current file
--
-- Exceptions :
--
--    Constraint_Error - Item is No_Context
--
   procedure Get_Scope
             (  Item     : Context_Entry;
                File     : out Source_Description_Ptr;
                Location : out Parsers.Multiline_Source.Location
             );
------------------------------------------------------------------------
   package Ada_Expression_Parser is
      new Parsers.Generic_Ada_Parser
          (  Sources                     => Code,
             Argument_Frame_Segment_Size => 2048,
             Argument_Frame_Minimal_Size => 64,
             Argument_Frame_Increment    => 50,
             Argument_Stub_Minimal_Size  => 64,
             Argument_Stub_Increment     => 50,
             Operation_Segment_Size      => 2048,
             Operation_Minimal_Size      => 64,
             Operation_Increment         => 50
          );
   use Ada_Expression_Parser;
--
-- Ada_Program -- Parsed Ada program with a cross-reference
--
--    Pool - The arena to allocate the sybtax tree
--    Xref - The cross-reference for defining identifiers
--
-- The arena pools used for syntax tree and cross-reference can be same.
-- When Xref is null, no cross-reference is generated
--
   type Ada_Program
        (  Pool : access Root_Storage_Pool'Class;
           Xref : Cross_Reference_Ptr
        )  is new Ada_Expression with private;
--
-- Parse -- Ada source
--
--    Context - The parsing context
--    Code    - The source to parse
--    File    - The source file description
--
-- The File  parameter  is a desription  of a file  or equivalent of the
-- source.   Defining  identifier   locations  are   augmented  by  this
-- description (the Field member).
--
-- Returns :
--
--    Parsed compilation unit
--
-- Exceptions :
--
--    Syntax_Error - Compilation error
--
   function Parse
            (  Context : access Ada_Program;
               Code    : access Source'Class;
               File    : Source_Description_Ptr := null
            )  return Tokens.Argument_Token;
--
-- Get_Trace_File -- Get trace file
--
--    Context - The parsing context
--
-- Returns :
--
--    The trace file of null
--
   function Get_Trace_File (Context : Ada_Program)
      return Ada.Text_IO.File_Access;
--
-- Set_Trace_File -- Set trace file
--
--    Context - The parsing context
--  [ File ]  - The file to trace into
--
   procedure Set_Trace_File
             (  Context : in out Ada_Program;
                File    : Ada.Text_IO.File_Access := null
             );
--
-- Tree_Stub -- Arena stack pool stub. The object when created marks the
--              arena. The generated syntax tree  is allocated by a call
-- to Parse above the stub in the arena.  Upon finalization the arena is
-- cleaned by deallocating the mark.  When the cross  reference contains
-- nodes that refer to the removed nodes Program_Error is propagated.
--
   type Tree_Stub (Context : access Ada_Program'Class) is
      new Ada.Finalization.Limited_Controlled with private;

   subtype Lexer is Ada_Expression_Parser.Lexers.Lexer;
--
-- Program_Node_Class -- The classes  of nodes used  to avoid class-wide
--                       testing
--
   type Program_Node_Class is
        (  Abort_Statement_Node,
           Accept_Statement_Node,
           Access_Type_Declaration_Node,
           Array_Type_Declaration_Node,
           Assignment_Statement_Node,
           Asynchronous_Transfer_Control_Node,
           At_Clause_Node,
           Attribute_Definition_Clause_Node,

           Block_Statement_Node,

           Call_Statement_Node,
           Case_Statement_Node,
           Chunk_Specification_Node,
           Conditional_Entry_Call_Node,

           Decimal_Fixed_Point_Type_Declaration_Node,
           Declaration_Context_Node,
           Delay_Statement_Node,
           Derived_Type_Declaration_Node,

           Enumeration_Representation_Clause_Node,
           Enumeration_Type_Declaration_Node,
           Entry_Body_Node,
           Entry_Declaration_Node,
           Exception_Declaration_Node,
           Exception_Handler_Node,
           Exception_Renaming_Node,
           Exit_Statement_Node,
           Extended_Return_Statement_Node,

           Floating_Point_Type_Declaration_Node,
           For_Loop_Statement_Node,
           Formal_Access_Type_Parameter_Node,
           Formal_Array_Type_Parameter_Node,
           Formal_Derived_Type_Parameter_Node,
           Formal_Function_Parameter_Node,
           Formal_Incomplete_Type_Parameter_Node,
           Formal_Interface_Type_Parameter_Node,
           Formal_Package_Parameter_Node,
           Formal_Private_Type_Parameter_Node,
           Formal_Procedure_Parameter_Node,
           Formal_Scalar_Type_Parameter_Node,
           Function_Body_Node,
           Function_Declaration_Node,
           Function_Expression_Node,
           Function_Instantiation_Node,
           Function_Renaming_Node,
           Function_Stub_Node,

           Goto_Statement_Node,

           If_Statement_Node,
           Incomplete_Type_Declaration_Node,
           Identifier_List_Node,
           Interface_Type_Declaration_Node,

           Handled_Statement_Sequence_Node,

           Loop_Statement_Node,

           Modular_Type_Declaration_Node,

           Null_Procedure_Node,
           Null_Statement_Node,

           Object_Declaration_Node,
           Object_Renaming_Node,
           Ordinary_Fixed_Point_Type_Declaration_Node,

           Package_Body_Node,
           Package_Declaration_Node,
           Package_Renaming_Node,
           Package_Instantiation_Node,
           Package_Stub_Node,
           Parallel_Block_Node,
           Parameter_Profile_Node,
           Parameter_Specification_Node,
           Pragma_Clause_Node,
           Private_Type_Declaration_Node,
           Private_Extension_Type_Declaration_Node,
           Procedure_Body_Node,
           Procedure_Declaration_Node,
           Procedure_Instantiation_Node,
           Procedure_Renaming_Node,
           Procedure_Stub_Node,
           Protected_Body_Node,
           Protected_Stub_Node,
           Protected_Type_Declaration_Node,

           Raise_Statement_Node,
           Record_Representation_Clause_Node,
           Record_Type_Declaration_Node,
           Requeue_Statement_Node,

           Selective_Accept_Node,
           Signed_Integer_Type_Declaration_Node,
           Simple_Return_Statement_Node,
           Single_Protected_Declaration_Node,
           Single_Task_Declaration_Node,
           Singleton_Parameter_Node,
           Statement_Sequence_Node,
           Subtype_Declaration_Node,

           Task_Body_Node,
           Task_Stub_Node,
           Task_Type_Declaration_Node,
           Timed_Entry_Call_Node,

           Use_Package_Clause_Node,
           Use_Type_Clause_Node,

           Variant_Part_Node,
           Variant_Part_Item_Node,

           While_Loop_Statement_Node,
           With_Clause_Node
        );
--
-- Program_Node -- The nodes of Ada program
--
   type Program_Node is abstract new Node with null record;
   type Program_Node_Ptr is access constant Program_Node'Class;
   function Get_Class (Item : Program_Node) return Node_Class;
--
-- Get_Class -- The program node class
--
--    Item - The node
--
-- Returns :
--
--    The program node class
--
   function Get_Class (Item : Program_Node)
      return Program_Node_Class is abstract;
--
-- Declaration_Node -- An item in a declaration context
--
--    Location - The location of declaration
--
   type Declaration_Node is abstract new Program_Node with record
      Location : Parsers.Multiline_Source.Location := Empty_Location;
   end record;
   type Declaration_Ptr is access constant Declaration_Node'Class;
--
-- Get -- Get declaration item at the location specified
--
--    Context - The item location
--
-- Returns :
--
--    The item or null
--
   function Get (Context : Context_Location) return Declaration_Ptr;
--
-- = -- Validate location
--
--    Left  - Context location
--    Right - Declaration node
--
-- Returns :
--
--    True if Left points to Right
--
   function "="
            (  Left  : Context_Location;
               Right : Declaration_Node'Class
            )  return Boolean;

   type Overriding_Indicator_Type is
        (  No_Indicator,
           Overriding_Indicator,
           Not_Overriding_Indicator
        );
   function Image
            (  Indicator : Overriding_Indicator_Type;
               Suffix    : String := ""
            )  return String;
--
-- Is_Library_Unit -- The context is library level context
--
--    Item - The context location
--
-- Returns :
--
--    True if the context is a library level context
--
   function Is_Library_Unit (Item : Context_Location) return Boolean;
   function Image (Item : Context_Location) return String;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Context_Location
             );
--
-- Compilation_Context -- A compilation context
--
--    Parent - The enclosing context if any
--    Scope  - The  location  where  declarations  from  the context are
--             directly visible
--
-- Here is an example of the parameter profile of the procedure X:
--
-- package T is
--    I : Integer;                        \
--    A : Float;                           \
--    procedure X                           \
--              (  J : Integer; \            \
--                 P : Float;    > Location   \
--                 S : String   /              > Parent's location
--              )  is           \             /
--    begin                      > Scope     /
--       J := J + 1;            /           /
--       I := J;                           /
--    end X;                              /
-- end T;
--
   type Compilation_Context is abstract new Declaration_Node with record
      Parent   : Context_Location;
      File     : Source_Description_Ptr;
      Scope    : Parsers.Multiline_Source.Location := Empty_Location;
   end record;
--
-- Get_Items -- Get declaration
--
--    Context - The context
--    Index   - The index of 1..Get_Items_Number
--
-- Returns :
--
--    Declaration item
--
-- Exceptions :
--
--    Constraint_Error - Index is out of range
--
   function Get_Item
            (  Context : Compilation_Context;
               Index   : Positive
            )  return Declaration_Ptr is abstract;

--
-- Get_Items_Number -- Get declarations number
--
--    Context - The context
--
-- Returns :
--
--    Number of items declared
--
   function Get_Items_Number (Context : Compilation_Context)
      return Natural is abstract;
--
-- Defining_Identifier -- The name of symbol identifying something
--
--    Declared - The location of the identifier in the parent context
--    Outer    - The program node containing the identifier
--    Name     - A refernce to the name
--    Term     - The actual expression, e.g. Identifier, String_Literal
--    File     - The source file description, null is the currect source
--    Next     - The next identifier in the cross-ference entry
--
   type Named_Term_Ptr is access constant Named_Term'Class;
   type Defining_Identifier is record
      Declared : Context_Location;
      Outer    : Program_Node_Ptr;
      Name     : Named_Term_Ptr;
      Term     : Tokens.Argument_Token;
      File     : Source_Description_Ptr;
      Next     : Defining_Identifier_Ptr;
   end record;

   type Defining_Identifier_Array is
      array (Positive range <>) of aliased Defining_Identifier;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Defining_Identifier_Array;
                Prefix      : String;
                Delimiter   : String;
                Suffix      : String
             );
private
   pragma Inline (Precedes);

   Max_Name_Length : constant := 80; -- Truncated is longer

   subtype Source is Parsers.Multiline_Source.Source;
------------------------------------------------------------------------
-- Cross-reference of defining identifiers
--
   type Defining_Identifier_Ref is access all Defining_Identifier;
--
-- Equal, Less -- Comparisons by identifier
--
   function Equal (Left, Right : Named_Term_Ptr) return Boolean;
   function Less  (Left, Right : Named_Term_Ptr) return Boolean;

   type Defining_Identifier_List is record
      Count : Positive := 1;
      First : Defining_Identifier_Ref;
      Last  : Defining_Identifier_Ref;
   end record;
   type Defining_Identifier_List_Ref is
      access all Defining_Identifier_List;
   function Equal
            (  Left  : Defining_Identifier;
               Right : Defining_Identifier;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;
   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Defining_Identifier
             );

   package Cross_Reference_Tree is
      new Parsers.Generic_Arena_B_Tree
          (  Key_Type    => Named_Term_Ptr,
             Object_Type => Defining_Identifier_List_Ref,
             width       => Cross_Reference_Bucket_Size,
             "<"         => Less,
             "="         => Equal
          );
   type Identifier_Entry is record
      Item : Cross_Reference_Tree.Item_Ptr;
   end record;
   No_Identifier : constant Identifier_Entry :=
      (Item => Cross_Reference_Tree.No_Item);
------------------------------------------------------------------------
-- Cross-reference of contexts
--
   type File_Location is record
      File     : Source_Description_Ptr;
      Location : Parsers.Multiline_Source.Location;
   end record;
   function "=" (Left, Right : File_Location) return Boolean;
   function "<" (Left, Right : File_Location) return Boolean;
   function Image (Location : File_Location) return String;
   package Contexts_Reference is
      new Parsers.Generic_Arena_B_Tree
          (  Key_Type    => File_Location,
             Object_Type => Compilation_Context_Ptr,
             width       => Cross_Reference_Bucket_Size
          );
   type Context_Entry is record
      Item : Contexts_Reference.Item_Ptr;
   end record;
   No_Context : constant Context_Entry :=
      (Item => Contexts_Reference.No_Item);
------------------------------------------------------------------------
   type Cross_Reference
        (  Pool : access Root_Storage_Pool'Class
        )  is new Ada.Finalization.Limited_Controlled with
   record
      Identifiers : Cross_Reference_Tree.B_Tree (Pool);
      Contexts    : Contexts_Reference.B_Tree   (Pool);
   end record;

   type Tree_Stub_Ptr is access all Tree_Stub;
   type Ada_Program
        (  Pool : access Root_Storage_Pool'Class;
           Xref : Cross_Reference_Ptr
        )  is new Ada_Expression (Pool) with
   record
      Stubs : Tree_Stub_Ptr;
      Trace : Ada.Text_IO.File_Access;
   end record;

   procedure Add
             (  Context  : in out Ada_Program;
                Location : Context_Location;
                Name     : access Defining_Identifier
             );
   procedure Add
             (  Context  : in out Ada_Program;
                Item     : in out Compilation_Context'Class;
                Location : Parsers.Multiline_Source.Location;
                File     : Source_Description_Ptr
             );
   procedure Finalize (Context : in out Ada_Program);

   type Parameter_Part_Type is
        (  Parameter_Name,
           Parameter_Comma,
           Parameter_Colon
        );
   type Parameter_Part (Part : Parameter_Part_Type) is record
      case Part is
         when Parameter_Name =>
            null;
         when Parameter_Comma | Parameter_Colon =>
            Name : Tokens.Argument_Token;
      end case;
   end record;

   type Tree_Stub (Context : access Ada_Program'Class) is
      new Ada.Finalization.Limited_Controlled with
   record
      Previous    : Tree_Stub_Ptr;
      Next        : Tree_Stub_Ptr;
      Identifiers : Boolean := True; -- Items allocated after the mark
      Contexts    : Boolean := True; -- Items allocated after the mark
      Mark        : Node_Ptr;
   end record;
   procedure Finalize (Stub : in out Tree_Stub);
   procedure Initialize (Stub : in out Tree_Stub);

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Argument_List;
                Prefix      : String;
                Delimiter   : String;
                Suffix      : String
             );

   function Equal
            (  Left  : Context_Location;
               Right : Context_Location;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean;

   procedure Check (This : Defining_Identifier);

   Inequal : constant Boolean := False;
-- function Inequal return Boolean;

end Parsers.Ada_Syntax_Analyzer;
