--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Serialization.Restore                    Summer, 2026       --
--  Separate body                                                     --
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

with Ada.Unchecked_Conversion;

separate (Parsers.Ada_Syntax_Analyzer.Serialization)
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
             )  is

   type Handled_Statement_Sequence_Ref is
      access Handled_Statement_Sequence;
   for Handled_Statement_Sequence_Ref'Storage_Pool use Pool;

   type Node_Ref is access Node'Class;
   for Node_Ref'Storage_Pool use Pool;

   type Statement_Sequence_Ref is access Statement_Sequence;
   for Statement_Sequence_Ref'Storage_Pool use Pool;

   function Get return Natural;
   function Get (Parent : Context_Location)
      return Subtype_Mark;
   procedure Get
             (  List   : out Subtype_Mark_Array;
                Parent : Context_Location
             );
   function Get
            (  Parent : Context_Location
            )  return Subtype_Indication;
   procedure Get
             (  List   : out Subtype_Indication_Array;
                Parent : Context_Location
             );

   function "or"
             (  Declarations : Declaration_Context_Ptr;
                Parent       : Context_Location
             )  return Context_Location is
   begin
      if Declarations = null then
         return Parent;
      else
         return
         (  Context => Declarations.all'Unchecked_Access,
            After   => Get_Items_Number (Declarations.all)
         );
      end if;
   end "or";

   function "or"
             (  Profile : Parameter_Profile_Ptr;
                Parent  : Context_Location
             )  return Context_Location is
   begin
      if Profile = null then
         return Parent;
      else
         return
         (  Context => Profile.all'Unchecked_Access,
            After   => Get_Items_Number (Profile.all)
         );
      end if;
   end "or";

   function "or"
             (  Chunk  : Chunk_Specification_Ptr;
                Parent : Context_Location
             )  return Context_Location is
   begin
      if Chunk = null or else Chunk.Mode /= Chunk_Parameter then
         return Parent;
      else
         return
         (  Context => Chunk.Name'Unchecked_Access,
            After   => Get_Items_Number (Chunk.Name)
         );
      end if;
   end "or";

   function Get
            (  Parent : Context_Location
            )  return Tokens.Argument_Token is
      Result : Tokens.Argument_Token;
   begin
      Restore
      (  Stream  => Stream,
         Pool    => Pool,
         Offset  => Offset,
         Parent  => Parent,
         Loop_Of => Loop_Of,
         Result  => Result,
         Xref    => Xref,
         File    => File,
         Trace   => Trace,
         Prefix  => Prefix & "   "
      );
      return Result;
   end Get;

   procedure Get
             (  List   : out Argument_List;
                Parent : Context_Location
             )  is
   begin
      for Index in List'Range loop
         List (Index) := Get (Parent);
      end loop;
   end Get;

   function Get (Parent : Context_Location)
      return Array_Type_Definition_Ptr is

      type Array_Type_Definition_Ref is
         access Array_Type_Definition;
      for Array_Type_Definition_Ref'Storage_Pool use Pool;
      Tag  : constant Natural := Get;
      Ptr  : constant Array_Type_Definition_Ref :=
                new Array_Type_Definition
                    (  Aliased_Component => Tag mod 2 /= 0,
                       Dimension         => Tag / 2
                    );
      This : Array_Type_Definition renames Ptr.all;
   begin
      This.Component := Get (Parent);
      for Index in This.Indices'Range loop
         This.Indices (Index) := Get (Parent);
      end loop;
      return This'Unchecked_Access;
   end Get;

   procedure Get (List : out Aspect_Items_Array) is
      function Get return Global_Aspect_Element_Ptr is
         type Global_Aspect_Element_Ptr is
            access Global_Aspect_Element;
         for Global_Aspect_Element_Ptr'Storage_Pool use Pool;
         Ptr         : Global_Aspect_Element_Ptr;
         Kind_Of     : Global_Designator_Mode;
         Mode        : Basic_Global_Mode;
         Extended    : Boolean;
         Names_Count : Natural := Get;
      begin
         Extended    := 0 /= (Names_Count mod 2);
         Names_Count := Names_Count / 2;
         Kind_Of     := Global_Designator_Mode'Val
                        (  Names_Count mod Global_Designator_Mode_Mod
                        );
         Names_Count := Names_Count / Global_Designator_Mode_Mod;
         Mode        := Basic_Global_Mode'Val
                        (  Names_Count mod Basic_Global_Mode_Mod
                        );
         Names_Count := Names_Count / Basic_Global_Mode_Mod;
         Ptr := new Global_Aspect_Element
                    (  Kind_Of     => Kind_Of,
                       Mode        => Mode,
                       Extended    => Extended,
                       Names_Count => Names_Count
                    );
         declare
            This : Global_Aspect_Element renames Ptr.all;
         begin
            case This.Kind_Of is
               when All_Designator_Mode          |
                    Synchronized_Designator_Mode =>
                  null;
               when Global_Name_Designator_Mode =>
                  Get (This.List, Parent);
            end case;
            return This'Unchecked_Access;
         end;
      end Get;

      procedure Get (List : out Global_Aspect_Element_Ptr_Array) is
      begin
         for Index in List'Range loop
            List (Index) := Get;
         end loop;
      end Get;

      function Get
               (  Parent : Context_Location
               )  return Aspect_Specification_Item_Ptr is
         type Aspect_Specification_Item_Ptr is
            access Aspect_Specification_Item;
         for Aspect_Specification_Item_Ptr'Storage_Pool use Pool;
         Ptr : Aspect_Specification_Item_Ptr;
         Tag : constant Natural := Get;
      begin
         Ptr := new Aspect_Specification_Item
                    (  Mode =>
                          Aspect_Designator_Type'Val
                          (  Tag mod Aspect_Designator_Type_Mod
                          ),
                       Elements_Count =>
                          Tag / Aspect_Designator_Type_Mod
                    );
         declare
            This : Aspect_Specification_Item renames Ptr.all;
         begin
            This.Mark := Get (Parent);
            case This.Mode is
               when Value_Designator =>
                  This.Value := Get (Parent);
               when No_Designator          |
                    Null_Designator        |
                    Unspecified_Designator =>
                  null;
               when Global_Designator =>
                  This.Designator := Get;
               when Global_Aspect_Elements_List_Designator =>
                  Get (This.List);
            end case;
            return This'Unchecked_Access;
         end;
      end Get;
   begin
      for Index in List'Range loop
         List (Index) := Get (Parent);
      end loop;
   end Get;

   procedure Get
             (  Name   : access Defining_Identifier;
                Outer  : Program_Node_Ptr;
                Parent : Context_Location
             )  is
      use Cross_Reference_Tree;
      Result : Defining_Identifier renames Name.all;
   begin
      Result.Outer    := Outer;
      Result.Term     := Get (Parent);
      Result.Declared := Parent;
      Result.File     := File;
      if Result.Term.Value.all in Expression then -- Full name,
         declare                                  -- take the last
            List : Argument_List renames
                   Expression (Result.Term.Value.all).Operands;
         begin
            Result.Name :=
               Named_Term (List (List'Last).Value.all)'Access;
         end;
      else
         Result.Name := Named_Term (Result.Term.Value.all)'Access;
      end if;
      if Trace /= null then
         Put_Line
         (  Trace.all,
            Prefix & "   " & Image (Offset) &
            "Declared "    & Image (Name.Declared)
         );
      end if;
      if Xref = null then
         return;
      end if;
      declare
         Tree : B_Tree renames Xref.Identifiers;
         Item : constant Item_Ptr := Find (Tree, Name.Name);
      begin
         if Item = No_Item then
            declare
               type Arena_Ptr is access Defining_Identifier_List;
               for Arena_Ptr'Storage_Pool use Pool;
               Item : constant Arena_Ptr :=
                           new Defining_Identifier_List'
                               (  Count => 1,
                                  First => Name.all'Unchecked_Access,
                                  Last  => Name.all'Unchecked_Access
                               );
            begin
               Add (Tree, Name.Name, Item.all'Unchecked_Access);
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
   end Get;

   procedure Get (List : out Guarded_List; Parent : Context_Location) is
   begin
      for Index in List'Range loop
         List (Index).Guard := Get (Parent);
         List (Index).Value := Get (Parent);
      end loop;
   end Get;

   procedure Get (Item : out Location) is
      use Line_Number_Serialization;
   begin
      Get (Stream, Offset, Item.First.Line);
      Item.First.Column := Get;
      Get (Stream, Offset, Item.Next.Line);
      Item.Next.Column := Get;
   end Get;

   function Get return Natural is
      use Integer_Number_Serialization;
      Result : Natural;
   begin
      Get (Stream, Offset, Result);
      return Result;
   end Get;

   function Get return Operations is
   begin
      return Operations'Val (Get);
   end Get;

   function Get (Parent : Context_Location) return Subtype_Indication is
      Value      : Integer := Get;
      Mark       : Subtype_Mark;
      Not_Null   : Boolean;
      Mode       : Stubtype_Indication_Mode;
      Constraint : Subtype_Constraint;
   begin
      Mark     := Get (Parent);
      Not_Null := (Value mod 2) /= 0;
      Value    := Value / 2;
      Mode     := Stubtype_Indication_Mode'Val
                  (  Value
                  mod
                     Stubtype_Indication_Mode_Mod
                  );
      Value    := Value / Stubtype_Indication_Mode_Mod;
      case Subtype_Constraint_Mode'Val (Value) is
         when No_Constraint =>
            Constraint := (Mode => No_Constraint);
         when Fixed_Point_Constraint =>
            Constraint :=
               (  Mode             => Fixed_Point_Constraint,
                  Delta_Constraint => Get (Parent)
               );
         when Floating_Point_Constraint =>
            Constraint :=
               (  Mode              => Floating_Point_Constraint,
                  Digits_Constraint => Get (Parent)
               );
         when Index_Constraint =>
            Constraint :=
               (  Mode       => Index_Constraint,
                  Constraint => Get (Parent)
               );
         when Discriminant_Constraint =>
            Constraint :=
               (  Mode       => Discriminant_Constraint,
                  Constraint => Get (Parent)
               );
      end case;
      case Mode is
         when Subtype_Range_Mode =>
            return
            (  Mode             => Subtype_Range_Mode,
               Mark             => Mark,
               Not_Null         => Not_Null,
               Constraint       => Constraint,
               Range_Constraint => Get (Parent)
            );
         when Range_Mode =>
            return
            (  Mode       => Range_Mode,
               Mark       => Mark,
               Not_Null   => Not_Null,
               Constraint => Constraint
            );
         when Subtype_Mode =>
            return
            (  Mode       => Subtype_Mode,
               Mark       => Mark,
               Not_Null   => Not_Null,
               Constraint => Constraint
            );
         when Unconstrained_Mode =>
            return
            (  Mode       => Unconstrained_Mode,
               Mark       => Mark,
               Not_Null   => Not_Null,
               Constraint => Constraint
            );
      end case;
   end Get;

   procedure Get
             (  List   : out Subtype_Indication_Array;
                Parent : Context_Location
             )  is
   begin
      for Index in List'Range loop
         List (Index) := Get (Parent);
      end loop;
   end Get;

   function Get (Parent : Context_Location) return Subtype_Mark is
      Attribute : Constraint_Attribute;
      Name      : Tokens.Argument_Token;
   begin
      Attribute := Constraint_Attribute'Val (Get);
      Name := Get (Parent);
      case Attribute is
         when Class_Attribute =>
            return
            (  Attribute => Class_Attribute,
               Name      => Name
            );
         when No_Attribute =>
            return
            (  Attribute => No_Attribute,
               Name      => Name
            );
         when Base_Attribute =>
            return
            (  Attribute => Base_Attribute,
               Name      => Name
            );
         when Dimension_Range_Attribute =>
            return
            (  Attribute => Dimension_Range_Attribute,
               Name      => Name,
               Dimension => Get (Parent)
            );
         when Base_Range_Attribute =>
            return
            (  Attribute => Base_Range_Attribute,
               Name      => Name
            );
         when Range_Attribute =>
            return
            (  Attribute => Range_Attribute,
               Name      => Name
            );
      end case;
   end Get;

   function Get (Parent : Context_Location)
      return Subtype_Indication_Array_Ptr is
      type Subtype_Indication_Array_Ref is
         access Subtype_Indication_Array;
      for Subtype_Indication_Array_Ref'Storage_Pool use Pool;
      Ptr : Subtype_Indication_Array_Ref;
   begin
      Ptr := new Subtype_Indication_Array (1..Get);
      Get (Ptr.all, Parent);
      return Ptr.all'Unchecked_Access;
   end Get;

   procedure Get
             (  List   : out Subtype_Mark_Array;
                Parent : Context_Location
             )  is
   begin
      for Index in List'Range loop
         List (Index) := Get (Parent);
      end loop;
   end Get;

   function Get return Unbounded_Unsigned is
      Value  : Unbounded_Unsigned;
      Digit  : Unbounded_Unsigned;
      Power  : Bit_Offset := 0;
      Last   : Stream_Element_Offset;
      Buffer : Stream_Element_Array (1..1);
   begin
      loop
         Read (Stream, Buffer, Last);
         if Last /= 1 then
            raise End_Error;
         end if;
         Offset := Offset + 1;
         Set (Digit, Half_Word (Buffer (1) and 16#7F#));
         Mul_By_Power_Of_Two (Digit, Power);
         Add (Value, Digit);
         if 0 = (Buffer (1) and 16#80#) then
            return Value;
         end if;
         Power := Power + 7;
      end loop;
   end Get;

   function Get_Integer return Unbounded_Integer is
      Sign : constant Integer := Get;
   begin
      return Compose (Get, Sign /= 0);
   end Get_Integer;

   procedure Get_Named_Term
             (  Result    : Node_Ref;
                Malformed : Boolean
             )  is
      This : Named_Term'Class renames Named_Term'Class (Result.all);
   begin
      This.Malformed := Malformed;
      String'Read (Stream'Access, This.Value);
      Offset := Offset + This.Value'Length;
   end Get_Named_Term;

   procedure Get_Numeric_Term
             (  Result    : Node_Ref;
                Malformed : Boolean
             )  is
      This : Numeric_Literal'Class renames
             Numeric_Literal'Class (Result.all);
   begin
      Get_Named_Term (Result, Malformed);
      This.Base := Get;
      This.Exponent := Get;
      if 0 = (This.Exponent mod 2) then
         This.Exponent := This.Exponent / 2;
      else
         This.Exponent := -This.Exponent / 2;
      end if;
   end Get_Numeric_Term;

   function Get_Rational return Unbounded_Rational is
      Sign      : constant Integer := Get;
      Numerator : Unbounded_Unsigned;
   begin
      Numerator := Get;
      return Compose
             (  Numerator   => Numerator,
                Denominator => Get,
                Negative    => Sign /= 0
             );
   end Get_Rational;

   function Get_Node
            (  Node_Type : Term_Class
            )  return Node_Ptr is separate;

   function Get_Program_Node
            (  Tag     : Natural;
               Parent  : Context_Location;
               Loop_Of : Loop_Statement_Ptr
            )  return Node_Ref is separate;

   Tag : constant Integer := Get;
begin
   if Tag < Term_Class_Mod then
      Result.Value := Get_Node (Term_Class'Val (Tag));
   else
      Result.Value :=
         Get_Program_Node (Tag, Parent, Loop_Of).all'Unchecked_Access;
   end if;
   Get (Result.Location);
end Restore;
