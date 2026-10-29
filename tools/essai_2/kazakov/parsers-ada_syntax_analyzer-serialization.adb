--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Serialization                            Summer, 2026       --
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

with Ada.Exceptions;       use Ada.Exceptions;
with Unbounded_Integers;   use Unbounded_Integers;
with Unbounded_Rationals;  use Unbounded_Rationals;
with Unbounded_Unsigneds;  use Unbounded_Unsigneds;

with Parsers.Ada_Syntax_Analyzer.Bodies;
use  Parsers.Ada_Syntax_Analyzer.Bodies;

with Parsers.Ada_Syntax_Analyzer.Declarations;
use  Parsers.Ada_Syntax_Analyzer.Declarations;

with Parsers.Ada_Syntax_Analyzer.Declarations.Formal_Parameters;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Formal_Parameters;

with Parsers.Ada_Syntax_Analyzer.Declarations.Renamings;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Renamings;

with Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;

with Parsers.Ada_Syntax_Analyzer.Declarations.Stubs;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Stubs;

with Parsers.Ada_Syntax_Analyzer.Declarations.Types;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Types;

with Parsers.Ada_Syntax_Analyzer.Statements;
use  Parsers.Ada_Syntax_Analyzer.Statements;

with Strings_Edit.Integer_Edit;
with Strings_Edit.Integers;

with Ada.Tags;

package body Parsers.Ada_Syntax_Analyzer.Serialization is

   Aspect_Designator_Type_Mod : constant :=
      Aspect_Designator_Type'Pos (Aspect_Designator_Type'Last) + 1;

   Basic_Global_Mode_Mod : constant :=
      Basic_Global_Mode'Pos (Basic_Global_Mode'Last) + 1;

   Chunk_Specification_Type_Mod : constant := -- +1 for no chunk
      Chunk_Specification_Type'Pos (Chunk_Specification_Type'Last) + 2;

   Compilation_Context_Type_Mod : constant :=
      Compilation_Context_Type'Pos (Compilation_Context_Type'Last) + 1;

   Derived_Interface_Type_Mod : constant :=
      Derived_Interface_Type'Pos (Derived_Interface_Type'Last) + 1;

   For_Qualifier_Mod : constant :=
      For_Qualifier'Pos (For_Qualifier'Last) + 1;

   Formal_Scalar_Type_Mod : constant :=
      Formal_Scalar_Type'Pos (Formal_Scalar_Type'Last) + 1;

   Formal_Subprogram_Default_Type_Mod : constant :=
      (  Formal_Subprogram_Default_Type'Pos
         (  Formal_Subprogram_Default_Type'Last
         )
      +  1
      );

   Global_Designator_Mode_Mod : constant :=
      Global_Designator_Mode'Pos (Global_Designator_Mode'Last) + 1;

   Interface_Type_Mod : constant :=
      Interface_Type'Pos (Interface_Type'Last) + 1;

   Iterator_Mode_Mod : constant :=
      Iterator_Mode'Pos (Iterator_Mode'Last) + 1;

   Mode_Type_Mod : constant :=  Mode_Type'Pos (Mode_Type'Last) + 1;

   Overriding_Indicator_Type_Mod : constant :=
      (  Overriding_Indicator_Type'Pos
         (  Overriding_Indicator_Type'Last
         )
      +  1
      );

   Stubtype_Indication_Mode_Mod : constant :=
      Stubtype_Indication_Mode'Pos (Stubtype_Indication_Mode'Last) + 1;

   type Term_Class is
        (  Box_Choice_Term,
           Integer_Literal_Term,
           Real_Literal_Term,
           String_Literal_Term,
           Character_Literal_Term,
           Identifier_Term,
           Null_Aggregate_Term,
           Target_Name_Term,
           Universal_Boolean_Term,
           Universal_Integer_Term,
           Universal_Real_Term,
           Expression_Node_Term,
           If_Node_Term,
           Case_Node_Term,
           Declare_Node_Term,
           Declare_Renaming_Item_Term,
           Declare_Object_Item_Term,
           For_Node_Term,
           Raise_Node_Term
        );

   Term_Class_Mod : constant := Term_Class'Pos (Term_Class'Last) + 1;

   package Stream_Element_Offset_Edit is
      new Strings_Edit.Integer_Edit (Stream_Element_Offset);

   function Image (Offset : Stream_Element_Offset) return String is
      Buffer  : String (1..6);
      Pointer : Integer := 1;
   begin
      Stream_Element_Offset_Edit.Put
      (  Destination => Buffer,
         Pointer     => Pointer,
         Value       => Offset,
         Fill        => ' ',
         Justify     => Strings_Edit.Right,
         Field       => 6
      );
      return Buffer & "| ";
   end Image;

   generic
      type Number is range <>;
   package Generic_Unsigned_Serialization is
      procedure Get
                (  Stream : in out Root_Stream_Type'Class;
                   Offset : in out Stream_Element_Offset;
                   Value  : out Number
                );
      procedure Put
                (  Stream : in out Root_Stream_Type'Class;
                   Offset : in out Stream_Element_Offset;
                   Value  : Number
                );
   end Generic_Unsigned_Serialization;

   package body Generic_Unsigned_Serialization is
      procedure Get
                (  Stream : in out Root_Stream_Type'Class;
                   Offset : in out Stream_Element_Offset;
                   Value  : out Number
                )  is
         Last   : Stream_Element_Offset;
         Power  : Natural := 0;
         Buffer : Stream_Element_Array (1..1);
      begin
         Value := 0;
         loop
            Read (Stream, Buffer, Last);
            if Last /= 1 then
               raise End_Error;
            end if;
            Offset := Offset + 1;
            begin
               Value :=
                  Value + 2**Power * Number (Buffer (1) and 16#7F#);
            exception
               when Constraint_Error =>
                  Raise_Exception
                  (  Data_Error'Identity,
                     "Number is too large"
                  );
            end;
            if 0 = (Buffer (1) and 16#80#) then
               return;
            end if;
            Power := Power + 7;
         end loop;
      end Get;

      procedure Put
                (  Stream : in out Root_Stream_Type'Class;
                   Offset : in out Stream_Element_Offset;
                   Value  : Number
                )  is
         Item   : Number := Value;
         Buffer : Stream_Element_Array (1..1);
      begin
         if Item < 0 then
            Raise_Exception
            (  Constraint_Error'Identity,
               "Negative value"
            );
         end if;
         loop
            Buffer (1) := Stream_Element (Item mod 16#80#) or 16#80#;
            Item := Item / 16#80#;
            if Item = 0 then
               Buffer (1) := Buffer (1) and 16#7F#;
               Write (Stream, Buffer);
               Offset := Offset + 1;
               return;
            end if;
            Write (Stream, Buffer);
            Offset := Offset + 1;
         end loop;
      end Put;
   end Generic_Unsigned_Serialization;

   package Integer_Number_Serialization is
      new Generic_Unsigned_Serialization (Integer);

   package Line_Number_Serialization is
      new Generic_Unsigned_Serialization (Line_Number);

   function Image (Location : Context_Location) return String is
   begin
      if Location.Context = null then
         if Location.After /= 0 then
            raise Constraint_Error;
         end if;
         return "on top";
      else
         declare
            use Strings_Edit.Integers;
            This : Compilation_Context'Class renames
                   Location.Context.all;
         begin
            if This in Declaration_Context then
               return
               (  "in "
               &  Image (Declaration_Context (This).Kind_Of)
               &  " "
               &  Image (This.Location)
               &  " after "
               &  Image (Location.After)
               );
            else
               return
               (  "in "
               &  Ada.Tags.Expanded_Name (This'Tag)
               &  " "
               &  Image (This.Location)
               &  " after "
               &  Image (Location.After)
               );
            end if;
         end;
      end if;
   end Image;

   procedure Restore
             (  Stream  : in out Root_Stream_Type'Class;
                Pool    : in out Root_Storage_Pool'Class;
                Offset  : in out Stream_Element_Offset;
                Parent  : Context_Location;
                Loop_Of : Loop_Statement_Ptr;
                Result  : out Tokens.Argument_Token;
                Xref    : Cross_Reference_Ptr;
                File    : Source_Description_Ptr;
                Trace   : File_Access;
                Prefix  : String
             )  is separate;

   procedure Restore
             (  Stream : in out Root_Stream_Type'Class;
                Pool   : in out Root_Storage_Pool'Class;
                Offset : in out Stream_Element_Offset;
                Result : out Tokens.Argument_Token;
                Xref   : Cross_Reference_Ptr    := null;
                File   : Source_Description_Ptr := null;
                Trace  : File_Access            := null;
                Prefix : String                 := ""
             )  is
   begin
      Restore
      (  Stream  => Stream,
         Pool    => Pool,
         Offset  => Offset,
         Parent  => (null, 0),
         Loop_Of => null,
         Result  => Result,
         Xref    => Xref,
         File    => File,
         Trace   => Trace,
         Prefix  => Prefix
      );
   end Restore;

   function Restore
            (  Stream : access Root_Stream_Type'Class;
               Pool   : access Root_Storage_Pool'Class;
               Xref   : Cross_Reference_Ptr    := null;
               File   : Source_Description_Ptr := null;
               Trace  : File_Access            := null;
               Prefix : String                 := ""
            )  return Tokens.Argument_Token is
      Result : Tokens.Argument_Token;
      Offset : Stream_Element_Offset := 0;
   begin
      Restore
      (  Stream => Stream.all,
         Pool   => Pool.all,
         Offset => Offset,
         Result => Result,
         Xref   => Xref,
         File   => File,
         Trace  => Trace,
         Prefix => Prefix
      );
      return Result;
   end Restore;

   procedure Store
             (  Stream : in out Root_Stream_Type'Class;
                Tree   : Tokens.Argument_Token;
                Offset : in out Stream_Element_Offset;
                Trace  : File_Access := null;
                Prefix : String      := ""
             )  is separate;

   procedure Store
             (  Stream : in out Root_Stream_Type'Class;
                Tree   : Tokens.Argument_Token;
                Trace  : File_Access := null;
                Prefix : String      := ""
             )  is
      Offset : Stream_Element_Offset := 0;
   begin
      Store
      (  Stream => Stream,
         Tree   => Tree,
         Offset => Offset,
         Trace  => Trace,
         Prefix => Prefix
      );
   end Store;

end Parsers.Ada_Syntax_Analyzer.Serialization;
