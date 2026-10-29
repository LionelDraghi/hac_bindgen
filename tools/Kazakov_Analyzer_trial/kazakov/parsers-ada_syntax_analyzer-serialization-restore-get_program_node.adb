--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Serialization.Restore.Get_Program_Node   Summer, 2026       --
--  Separate body                                                     --
--                                Last revision :  21:25 05 Aug 2026  --
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

separate (Parsers.Ada_Syntax_Analyzer.Serialization.Restore)
   function Get_Program_Node
            (  Tag     : Natural;
               Parent  : Context_Location;
               Loop_Of : Loop_Statement_Ptr
            )  return Node_Ref is

   type Parameter_Profile_Ref   is access all Parameter_Profile;
   type Program_Node_Ref        is access all Program_Node'Class;

   function Ref is new Ada.Unchecked_Conversion (Node_Ptr, Node_Ref);
   function Ref is new Ada.Unchecked_Conversion
                       (  Parameter_Profile_Ptr,
                          Parameter_Profile_Ref
                       );
   function Get
            (  Have_It : Boolean;
               Parent  : Context_Location
            )  return Declaration_Context_Ptr;
   function Get
            (  Parent  : Context_Location;
               Tag     : Natural
            )  return Declaration_Context_Ptr;
   function Get
            (  Have_It : Boolean;
               Outer   : Program_Node_Ptr;
               Parent  : Context_Location
            )  return Parameter_Profile_Ptr;
   function Get
            (  Outer  : Program_Node_Ptr;
               Parent : Context_Location
            )  return Object_Specification_Ptr;
   function Get
            (  Parent : Context_Location
            )  return Parameter_Specification_Ptr;
   procedure Get
             (  Item      : out Singleton_Parameter;
                Outer     : in out Program_Node'Class;
                Parent    : Context_Location;
                Add_Scope : Boolean
             );
   procedure Get_Body
             (  Item  : in out Abstract_Body'Class;
                Outer : in out Program_Node'Class;
                Parent : Context_Location
             );
   procedure Get_Compilation_Context
             (  Item      : in out Compilation_Context'Class;
                Parent    : Context_Location;
                Add_Scope : Boolean
             );
   procedure Get_Formal_Parameter
             (  Item : in out Formal_Parameter'Class
             );
   procedure Get_Formal_Type_Parameter
             (  Item  : in out Formal_Type_Parameter'Class
             );
   procedure Get_Labels
             (  Item   : in out Abstract_Statement_Node'Class;
                Outer  : in out Program_Node'Class;
                Parent : Context_Location
             );
   procedure Get_Type
             (  Item  : in out Abstract_Type_Declaration'Class
             );

   function Get_Statement_Sequence
            (  Outer   : Program_Node_Ptr;
               Parent  : Context_Location;
               Loop_Of : Loop_Statement_Ptr
            )  return Statement_Sequence_Ref;

   procedure Add
             (  Scope   : Location;
                Context : in out Compilation_Context'Class
             )  is
      use Contexts_Reference;
   begin
      if Xref /= null then
         declare
            Location : constant File_Location := (File, Scope);
         begin
            Add (Xref.Contexts, Location, Context'Unchecked_Access);
         exception
            when Error : Constraint_Error =>
               declare
                  Other : constant Context_Entry :=
                                   Get (Xref.all, Scope, File);
               begin
                  if Other = No_Context then
                     Raise_Exception
                     (  Constraint_Error'Identity,
                        Image (Location)          &
                         ": "                     &
                        Exception_Message (Error) &
                        ' '                       &
                        Ada.Tags.Expanded_Name (Context'Tag)
                     );
                  else
                     Raise_Exception
                     (  Constraint_Error'Identity,
                        Image (Location)                     &
                         ": "                                &
                        Ada.Tags.Expanded_Name (Context'Tag) &
                        " already in "                       &
                        Ada.Tags.Expanded_Name
                        (  Get_Context (Other).all'Tag
                     )  );
                  end if;
               end;
         end;
      end if;
   end Add;

   function By (Declarations : Declaration_Context_Ptr)
      return Context_Location is
   begin
      if Declarations = null then
         return
         (  Context => null,
            After   => 0
         );
      else
         return
         (  Context => Declarations.all'Unchecked_Access,
            After   => Get_Items_Number (Declarations.all)
         );
      end if;
   end By;

   function By (List : Identifier_List) return Context_Location is
   begin
      return
      (  Context => List'Unchecked_Access,
         After   => Get_Items_Number (List)
      );
   end By;

   function By (Parameter : Singleton_Parameter)
      return Context_Location is
   begin
      return (Context => Parameter'Unchecked_Access, After => 1);
   end By;

   function Get
            (  Outer  : Program_Node_Ptr;
               Parent : Context_Location
            )  return Anonymous_Access_Definition is
      Tag      : constant Natural := Get;
      Not_Null : constant Boolean := Tag mod 2 /= 0;
      Profile  : Parameter_Profile_Ptr;
   begin
      case Access_Mode'(Mode_Type'Val (Tag / 4)) is
         when Access_To_All =>
            return (  Mode     => Access_To_All,
                      Not_Null => Not_Null,
                      Object   => Get (Parent)
                   );
         when Access_To_Constant =>
            return (  Mode     => Access_To_Constant,
                      Not_Null => Not_Null,
                      Object   => Get (Parent)
                   );
         when  Access_To_Variable =>
            return (  Mode     => Access_To_Variable,
                      Not_Null => Not_Null,
                      Object   => Get (Parent)
                   );
         when Access_To_Procedure =>
            Profile := Get ((Tag / 2) mod 2 = 0, Outer, Parent);
            return (  Mode     => Access_To_Procedure,
                      Not_Null => Not_Null,
                      Profile  => Profile
                   );
         when Access_To_Protected_Procedure =>
            Profile := Get ((Tag / 2) mod 2 = 0, Outer, Parent);
            return (  Mode     => Access_To_Protected_Procedure,
                      Not_Null => Not_Null,
                      Profile  => Profile
                   );
         when Access_To_Function =>
            Profile := Get ((Tag / 2) mod 2 = 0, Outer, Parent);
            return (  Mode     => Access_To_Function,
                      Not_Null => Not_Null,
                      Profile  => Profile,
                      Result   => Get (Outer, Parent)
                   );
         when Access_To_Protected_Function =>
            Profile := Get ((Tag / 2) mod 2 = 0, Outer, Parent);
            return (  Mode     => Access_To_Protected_Function,
                      Not_Null => Not_Null,
                      Profile  => Profile,
                      Result   => Get (Outer, Parent)
                   );
      end case;
   end Get;

   function Get
            (  Outer  : Program_Node_Ptr;
               Parent : Context_Location
            )  return Array_Type_Specification_Ptr is

      type Array_Type_Specification_Ref is
         access Array_Type_Specification;
      for Array_Type_Specification_Ref'Storage_Pool use Pool;
      Tag  : constant Natural := Get;
      Ptr  : constant Array_Type_Specification_Ref :=
                  new Array_Type_Specification
                      (  Mode =>
                            Mode_Type'Val ((Tag / 2) mod Mode_Type_Mod),
                         Dimension         => Tag / (Mode_Type_Mod * 2),
                         Aliased_Component => Tag mod 2 /= 0
                      );
      This : Array_Type_Specification renames Ptr.all;
   begin
      Get (This.Indices, Parent);
      case This.Mode is
         when Access_Mode =>
            This.Access_Component := Get (Outer, Parent);
         when Object_Mode =>
            This.Object_Component := Get (Parent);
      end case;
      return This'Unchecked_Access;
   end Get;

   function Get (Parent : Context_Location) return Context_Location is
      Tag : constant Natural := Get;
   begin
      if Tag /= 0 then
         declare
            Context : constant Declaration_Context_Ptr :=
                               Get (Parent, Tag);
         begin
            if Context /= null then
               return
               (  Context => Context.all'Unchecked_Access,
                  After   => Get_Items_Number (Context.all)
               );
            end if;
         end;
      end if;
      return Parent;
   end Get;

   procedure Get
             (  List   : out Guarded_Alternatives_Array;
                Outer  : in out Program_Node'Class;
                Parent : Context_Location
             )  is
   begin
      for Index in List'Range loop
         List (Index).Guard := Get (Parent);
         List (Index).Code  :=
            Get_Statement_Sequence
            (  Outer'Unchecked_Access,
               Parent,
               Loop_Of
            ) .all'Unchecked_Access;
      end loop;
   end Get;

   function Get
            (  Have_It : Boolean;
               Outer   : Program_Node_Ptr;
               Parent  : Context_Location
            )  return Parameter_Profile_Ptr is
      type Parameter_Profile_Ref is access Parameter_Profile;
      for Parameter_Profile_Ref'Storage_Pool use Pool;
   begin
      if Have_It then
         declare
            Ptr  : constant Parameter_Profile_Ref :=
                        new Parameter_Profile (Get);
            This : Parameter_Profile renames Ptr.all;
         begin
            Get_Compilation_Context (This, Parent, True);
            This.Outer := Outer;
            for Index in This.List'Range loop
               This.List (Index) :=
                  Get
                  (  (  Context => This'Unchecked_Access,
                        After   => Index - 1
                  )  );
            end loop;
            return This'Unchecked_Access;
         end;
      else
         return null;
      end if;
   end Get;

   function Get
            (  Outer  : Program_Node_Ptr;
               Parent : Context_Location
            )  return Object_Specification_Ptr is
      type Object_Specification_Ref is access Object_Specification;
      for Object_Specification_Ref'Storage_Pool use Pool;
      Tag  : constant Natural := Get;
      Ptr  : constant Object_Specification_Ref :=
                  new Object_Specification
                      (  Mode => Mode_Type'Val (Tag / 2)
                      );
      This : Object_Specification renames Ptr.all;
   begin
      case This.Mode is
         when Object_Mode =>
            This.Variable := Get (Parent);
         when In_Mode | Inout_Mode | Out_Mode =>
            This.Not_Null := Tag mod 2 /= 0;
            This.Result   := Get (Parent);
         when Access_Mode =>
            This.Pointer := Get (Outer, Parent);
         when Array_Mode =>
            This.Array_Object := Get (Outer, Parent);
         when Constant_Mode =>
            null;
      end case;
      return This'Unchecked_Access;
   end Get;

   function Get
            (  Parent : Context_Location
            )  return Parameter_Specification_Ptr is
      type Parameter_Specification_Ref is
         access Parameter_Specification;
      for Parameter_Specification_Ref'Storage_Pool use Pool;
      Tag_1 : constant Natural := Get;
      Tag_2 : constant Natural := Get;
      Ptr   : constant Parameter_Specification_Ref :=
              new Parameter_Specification
                  (  Mode => Mode_Type'Val
                             (  (Tag_2 / 2) mod Mode_Type_Mod
                             ),
                     Aliased_Parameter => 0 /= (Tag_1 mod 2),
                     Defaulted         => 0 /= ((Tag_1 / 2) mod 2),
                     Parameters_Count  => Tag_1 / 4,
                     Aspects_Count     => Tag_2 / (2 * Mode_Type_Mod)
                  );
       This : Parameter_Specification renames Ptr.all;
   begin
      case This.Mode is
         when In_Mode | Inout_Mode | Out_Mode =>
            This.Not_Null := 0 /= (Tag_2 mod 2);
            This.Value    := Get (Parent);
         when Access_Mode =>
            This.Pointer  := Get (This'Unchecked_Access, Parent);
      end case;
      for Index in This.Parameters'Range loop
         Get
         (  This.Parameters (Index)'Access,
            This'Unchecked_Access,
            Parent
         );
      end loop;
      if Parent.Context /= null then
         This.Profile :=
            Parameter_Profile (Parent.Context.all)'Unchecked_Access;
      end if;
      Get (This.Aspects);
      if This.Default.Present then
         This.Default.Item := Get (Parent);
      end if;
      Get (This.Location);
      return This'Unchecked_Access;
   end Get;

   function Get
            (  Outer  : Program_Node_Ptr;
               Parent : Context_Location
            )  return Parameter_Type is
      Tag                : Natural := Get;
      Aliased_Parameter  : Boolean := False;
      Constant_Parameter : Boolean := False;
   begin
      if Tag mod 2 = 0 then
         return
         (  Present => False,
            Aliased_Parameter  => False,
            Constant_Parameter => False,
            Mode               => Object_Mode
         );
      end if;
      Tag := Tag / 2; Aliased_Parameter  :=  Tag mod 2 /= 0;
      Tag := Tag / 2; Constant_Parameter :=  Tag mod 2 /= 0;
      case Component_Mode'(Mode_Type'Val (Tag / 2)) is
         when Access_To_All =>
            return
            (  Present            => True,
               Aliased_Parameter  => Aliased_Parameter,
               Constant_Parameter => Constant_Parameter,
               Mode               => Access_To_All,
               Access_Parameter   => Get (Outer, Parent)
            );
         when Access_To_Constant =>
            return
            (  Present            => True,
               Aliased_Parameter  => Aliased_Parameter,
               Constant_Parameter => Constant_Parameter,
               Mode               => Access_To_Constant,
               Access_Parameter   => Get (Outer, Parent)
            );
         when Access_To_Variable =>
            return
            (  Present            => True,
               Aliased_Parameter  => Aliased_Parameter,
               Constant_Parameter => Constant_Parameter,
               Mode               => Access_To_Variable,
               Access_Parameter   => Get (Outer, Parent)
            );
         when Access_To_Procedure =>
            return
            (  Present            => True,
               Aliased_Parameter  => Aliased_Parameter,
               Constant_Parameter => Constant_Parameter,
               Mode               => Access_To_Procedure,
               Access_Parameter   => Get (Outer, Parent)
            );
         when Access_To_Protected_Procedure =>
            return
            (  Present            => True,
               Aliased_Parameter  => Aliased_Parameter,
               Constant_Parameter => Constant_Parameter,
               Mode               => Access_To_Protected_Procedure,
               Access_Parameter   => Get (Outer, Parent)
            );
         when Access_To_Function =>
            return
            (  Present            => True,
               Aliased_Parameter  => Aliased_Parameter,
               Constant_Parameter => Constant_Parameter,
               Mode               => Access_To_Function,
               Access_Parameter   => Get (Outer, Parent)
            );
         when Access_To_Protected_Function =>
            return
            (  Present            => True,
               Aliased_Parameter  => Aliased_Parameter,
               Constant_Parameter => Constant_Parameter,
               Mode               => Access_To_Protected_Function,
               Access_Parameter   => Get (Outer, Parent)
            );
         when Object_Mode =>
            return
            (  Present            => True,
               Aliased_Parameter  => Aliased_Parameter,
               Constant_Parameter => Constant_Parameter,
               Mode               => Object_Mode,
               Object_Parameter   => Get (Parent)
            );
      end case;
   end Get;

   function Get_Declaration_Context
            (  Parent  : Context_Location;
               Tag     : Natural
            )  return Node_Ref is separate;

   function Get
            (  Have_It : Boolean;
               Parent  : Context_Location
            )  return Declaration_Context_Ptr is
   begin
      if Have_It then
         declare
            Result : constant Node_Ref :=
                              Get_Declaration_Context (Parent, Get);
         begin
            return Declaration_Context (Result.all)'Unchecked_Access;
         end;
      else
         return null;
      end if;
   end Get;

   function Get
            (  Parent : Context_Location;
               Tag    : Natural
            )  return Declaration_Context_Ptr is
      Result : constant Node_Ref :=
                        Get_Declaration_Context (Parent, Tag);
   begin
      return Declaration_Context (Result.all)'Unchecked_Access;
   end Get;

   procedure Get
             (  List   : out Defining_Identifier_Array;
                Outer  : in out Program_Node'Class;
                Parent : Context_Location
             )  is
   begin
      for Index in List'Range loop
         Get
         (  List (Index)'Access,
            Outer'Unchecked_Access,
            Parent
         );
      end loop;
   end Get;

   function Get
            (  Outer   : Handled_Statement_Sequence_Ptr;
               Parent  : Context_Location;
               Loop_Of : Loop_Statement_Ptr
            )  return Exception_Handler_Ptr is
      Tag    : constant Natural := Get;
      Result : constant Node_Ref :=
                    new Exception_Handler
                        (  Has_Parameter => Tag mod 2 /= 0,
                           Choices_Count => Tag / 2
                        );
      This   : Exception_Handler renames
               Exception_Handler (Result.all);
   begin
      This.Outer := Outer;
      This.Sequence := Get_Statement_Sequence
                       (  This'Unchecked_Access,
                          Parent,
                          Loop_Of
                       ) .all'Unchecked_Access;
      Get (This.Choices, Parent);
      if This.Has_Parameter then
         Get (This.Parameter, This, Parent, True);
      end if;
      return This'Unchecked_Access;
   end Get;

   procedure Get
             (  Item      : out Singleton_Parameter;
                Outer     : in out Program_Node'Class;
                Parent    : Context_Location;
                Add_Scope : Boolean
             )  is
   begin
      Get_Compilation_Context (Item, Parent, Add_Scope);
      Get (Item.Name'Access, Outer'Unchecked_Access, Item.Parent);
      Item.Type_Of := Get (Outer'Unchecked_Access, Item.Parent);
   end Get;

   function Get
            (  Parent : Context_Location
            )  return Variant_Part_Item_Ptr is
      Choices_Count : constant Natural := Get;
      Result : constant Node_Ref :=
                    new Variant_Part_Item
                        (  Choices_Count => Choices_Count,
                           Components    => Get (True, Parent)
                        );
      This   : Variant_Part_Item renames
               Variant_Part_Item (Result.all);
   begin
      Get (This.Choices, Parent);
      Get (This.Location);
      return This'Unchecked_Access;
   end Get;

   procedure Get_Body
             (  Item   : in out Abstract_Body'Class;
                Outer  : in out Program_Node'Class;
                Parent : Context_Location
             )  is
   begin
      Get (Item.Name'Access, Outer'Unchecked_Access, Parent);
      Get (Item.Aspects);
      Get (Item.Location);
   end Get_Body;

   function Get_Call_Statement return Node_Ref is
      Result : constant Node_Ref :=
                    new Call_Statement (Get);
      This : Call_Statement renames Call_Statement (Result.all);
   begin
      This.Target := Get (Parent);
      Get_Labels (This, This, Parent);
      return Result;
   end Get_Call_Statement;

   function Get_Chunk
            (  Mode  : Chunk_Specification_Type;
               Outer : Program_Node_Ref
            )  return Node_Ref is
      Result : constant Node_Ref := new Chunk_Specification (Mode);
      This   : Chunk_Specification renames
               Chunk_Specification (Result.all);
   begin
      This.Outer := Outer.all'Unchecked_Access;
      case This.Mode is
         when Chunk_Any =>
            null;
         when Chunk_Parameter =>
            Get (This.Name, This, Parent, True);
         when Chunk_Expression =>
            This.Value := Get (Parent);
      end case;
      Get (This.Location);
      return Result;
   end Get_Chunk;

   procedure Get_Compilation_Context
             (  Item      : in out Compilation_Context'Class;
                Parent    : Context_Location;
                Add_Scope : Boolean
             )  is
   begin
      if Trace /= null then
         Put (Trace.all, Prefix & Image (Offset));
         Put_Line (Trace.all, Ada.Tags.Expanded_Name (Item'Tag));
      end if;
      if Boolean'Val (Get) then
         if Parent.Context /= null then
            raise Constraint_Error;
         end if;
         Item.Parent := By (Get (True, Parent));
      else
         Item.Parent := Parent;
      end if;
      Get (Item.Location);
      Get (Item.Scope);
      Item.File := File;
      if Add_Scope and then Item.Scope /= Empty_Location then
         Add (Item.Scope, Item);
      end if;
   end Get_Compilation_Context;

   procedure Get_Formal_Parameter
             (  Item : in out Formal_Parameter'Class
             )  is
   begin
      Get (Item.Name'Access, Item'Unchecked_Access, Parent);
   end Get_Formal_Parameter;

   procedure  Get_Formal_Subprogram_Parameter
              (  Item    : in out Formal_Subprogram_Parameter'Class;
                 Profile : Parameter_Profile_Ptr
              )  is
   begin
      Item.Profile := Profile;
      Get (Item.Aspects);
      case Item.Default is
         when Name_Default =>
            Item.Default_Name := Get (Parent);
         when No_Default | Box_Default | Null_Default =>
            null;
      end case;
      Get_Formal_Parameter (Item);
   end Get_Formal_Subprogram_Parameter;

   procedure  Get_Formal_Type_Parameter
              (  Item : in out Formal_Type_Parameter'Class
              )  is
   begin
      if Item.Default.Defaulted then
         Item.Default.Default := Get (Parent);
      end if;
      Get (Item.Aspects);
      Get_Formal_Parameter (Item);
   end Get_Formal_Type_Parameter;

   function Get_Handled_Statement_Sequence
            (  Outer   : Program_Node_Ptr;
               Parent  : Context_Location;
               Loop_Of : Loop_Statement_Ptr
            )  return Handled_Statement_Sequence_Ref is
      Length         : constant Positive := Get;
      Handlers_Count : constant Natural  := Get;
      Labels_Count   : constant Natural  := Get;
      Result         : constant Handled_Statement_Sequence_Ref :=
                            new Handled_Statement_Sequence
                                (  Labels_Count   => Labels_Count,
                                   Length         => Length,
                                   Handlers_Count => Handlers_Count
                                );
      This : Handled_Statement_Sequence renames Result.all;
   begin
      This.Context := Parent;
      This.Outer   := Outer;
      for Index in This.List'Range loop
         declare
            Item : Abstract_Statement_Node'Class renames
                   Abstract_Statement_Node'Class
                   (  Get_Program_Node (Get, Parent, Loop_Of).all
                   );
         begin
            This.List (Index)  := Item'Unchecked_Access;
            Item.Path.Sequence := This'Unchecked_Access;
            Item.Path.Position := Index;
         end;
      end loop;
      for Index in This.Handlers'Range loop
         This.Handlers (Index) :=
            Get (This'Unchecked_Access, Parent, Loop_Of);
      end loop;
      Get_Labels (This, This, Parent);
      Get (This.Location);
      return Result;
   end Get_Handled_Statement_Sequence;

   function Get_Identifier_List
            (  Outer  : access Program_Node'Class;
               Parent : Context_Location
            )
      return Node_Ref is
      Result : constant Node_Ref := new Identifier_List (Get);
      This   : Identifier_List renames Identifier_List (Result.all);
   begin
      This.Parent := Parent;
      This.Outer  := Outer.all'Unchecked_Access;
      for Index in This.List'Range loop
         Get
         (  This.List (Index),
            This,
            (  Context => This'Unchecked_Access,
               After   => Index - 1
            ),
            False
         );
      end loop;
      Get (This.Location);
      Get (This.Scope);
      This.File := File;
      Add (This.Scope, This);
      return Result;
   end Get_Identifier_List;

    procedure Get_Instantiation
              (  Item : in out Abstract_Instantiation'Class
              )  is
    begin
       Item.Full_Name := Get (Parent);
       Get (Item.Name'Access, Item'Unchecked_Access, Parent);
       Item.Target := Get (Parent);
       Get (Item.Aspects);
       Get (Item.Location);
    end Get_Instantiation;

   procedure Get_Labels
             (  Item   : in out Abstract_Statement_Node'Class;
                Outer  : in out Program_Node'Class;
                Parent : Context_Location
             )  is
   begin
      Get (Item.Location);
      for Index in Item.Labels'Range loop
         Get
         (  Item.Labels (Index)'Access,
            Outer'Unchecked_Access,
            Parent
         );
      end loop;
   end Get_Labels;

   procedure Get_Loop
             (  Item    : in out Abstract_Loop_Statement'Class;
                Context : Context_Location
             )  is
   begin
      if Item.Name.Present then
         Item.Name.Item := Get (Parent);
      end if;
      Item.Sequence :=
         Get_Statement_Sequence
         (  Item'Unchecked_Access,
            Context,
            Item'Unchecked_Access
         ) .all'Unchecked_Access;
      Get_Labels (Item, Item, Parent);
   end Get_Loop;

   procedure Get_Renaming
             (  Item   : in out Abstract_Renaming'Class;
                Parent : Context_Location
             )  is
   begin
      Get (Item.Name'Access, Item'Unchecked_Access, Parent);
      Item.Target := Get (Parent);
      Get (Item.Aspects);
      Get (Item.Location);
   end Get_Renaming;

   procedure Get_Scalar_Type
             (  Item : in out Scalar_Type_Definition'Class
             )  is
   begin
      if Item.Constraint.Present then
         Item.Constraint.Item := Get (Parent);
      end if;
      Get_Type (Item);
   end Get_Scalar_Type;

   function Get_Statement_Sequence
            (  Outer   : Program_Node_Ptr;
               Parent  : Context_Location;
               Loop_Of : Loop_Statement_Ptr
            )  return Statement_Sequence_Ref is
      Length       : constant Positive := Get;
      Labels_Count : constant Natural  := Get;
      Result       : constant Statement_Sequence_Ref :=
                          new Statement_Sequence
                              (  Labels_Count => Labels_Count,
                                 Length       => Length
                              );
      This : Statement_Sequence renames Result.all;
   begin
      This.Context := Parent;
      This.Outer   := Outer;
      for Index in This.List'Range loop
         declare
            Item : Abstract_Statement_Node'Class renames
                   Abstract_Statement_Node'Class
                   (  Get_Program_Node (Get, Parent, Loop_Of).all
                   );
         begin
            This.List (Index)  := Item'Unchecked_Access;
            Item.Path.Sequence := This'Unchecked_Access;
            Item.Path.Position := Index;
         end;
      end loop;
      Get_Labels (This, This, Parent);
      return Result;
   end Get_Statement_Sequence;

   procedure Get_Stub (Item : in out Abstract_Stub'Class) is
   begin
      Get (Item.Name'Access, Item'Unchecked_Access, Parent);
      Get (Item.Aspects);
      Get (Item.Location);
   end Get_Stub;

   procedure Get_Subroutine_Body
             (  Item    : in out Subroutine_Body'Class;
                Profile : Parameter_Profile_Ptr;
                Code    : Handled_Statement_Sequence_Ref
             )  is
      Context : Context_Location := Item.Declarations.Parent;
   begin
      Code.Outer  := Item'Unchecked_Access;
      Item.Full_Name := Get (Parent);
      if Profile /= null then
         Item.Profile := Profile;
         Context := Profile.Parent;
         Ref (Profile).Outer := Item'Unchecked_Access;
      end if;
      if Item.Parent.Separate_Body then
         Item.Parent.Parent := Get (Parent);
      end if;
      Get_Body (Item, Item, Context);
   end Get_Subroutine_Body;

   procedure Get_Subprogram_Renaming
             (  Item        : in out Subprogram_Renaming'Class;
                Has_Profile : Boolean
             )  is
   begin
      Item.Parent    := Get (Parent);
      Item.Full_Name := Get (Item.Parent);
      Item.Profile :=
         Get (Has_Profile, Item'Unchecked_Access, Item.Parent);
      Get_Renaming (Item, Item.Parent);
   end Get_Subprogram_Renaming;

   procedure Get_Subprogram_Specification
             (  Item        : in out Subprogram_Specification'Class;
                Has_Profile : Boolean
             )  is
   begin
      if Item.Generic_Unit then
         Item.Parent := By (Get (True, Parent));
      else
         Item.Parent  := Get (Parent);
      end if;
      Item.Profile :=
         Get (Has_Profile, Item'Unchecked_Access, Item.Parent);
      Item.Full_Name := Get (Item.Parent);
      Get (Item.Name'Access, Item'Unchecked_Access, Item.Parent);
      Get (Item.Aspects);
      Get (Item.Location);
   end Get_Subprogram_Specification;

   procedure Get_Subprogram_Stub
             (  Item        : in out Subprogram_Stub'Class;
                Has_Profile : Boolean
             )  is
   begin
      Item.Profile := Get (Has_Profile, Item'Unchecked_Access, Parent);
      Get_Stub (Item);
   end Get_Subprogram_Stub;

   procedure Get_Type (Item : in out Abstract_Type_Declaration'Class) is
   begin
      Get (Item.Name'Access, Item'Unchecked_Access, Parent);
      Get (Item.Aspects);
      Get (Item.Location);
   end Get_Type;

   procedure Get_Context_Clause (Item : in out Context_Clause'Class) is
   begin
      Get (Item.List, Parent);
      Get (Item.Location);
   end Get_Context_Clause;

   procedure Trace_Result is
   begin
      if Trace /= null then
         Put (Trace.all, Prefix & Image (Offset) & "--- ");
         Put_Line
         (  Trace.all,
            Program_Node_Class'Image
            (  Program_Node_Class'Val (Tag - Term_Class_Mod)
         )  );
      end if;
   end Trace_Result;
begin
   if Trace /= null then
      Put (Trace.all, Prefix & Image (Offset));
      Put
      (  Trace.all,
         Program_Node_Class'Image
         (  Program_Node_Class'Val (Tag - Term_Class_Mod)
      )  );
      Put_Line (Trace.all, Integer'Image (Tag));
   end if;
   case Program_Node_Class'Val (Tag - Term_Class_Mod) is
      when Abort_Statement_Node =>
         declare
            Labels_Count : constant Natural  := Get;
            Tasks_Count  : constant Positive := Get;
            Result       : constant Node_Ref :=
                              new Abort_Statement
                                  (  Labels_Count => Labels_Count,
                                     Tasks_Count  => Tasks_Count
                                  );
            This : Abort_Statement renames
                   Abort_Statement (Result.all);
         begin
            Get (This.Tasks, Parent);
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Accept_Statement_Node =>
         declare
            Tag          : constant Natural := Get;
            Labels_Count : constant Natural := Tag / 8;
            Result       : constant Node_Ref :=
                              new Accept_Statement
                                  (  Labels_Count => Labels_Count,
                                     Is_Family    => Tag mod 2 /= 0
                                  );
            This : Accept_Statement renames
                   Accept_Statement (Result.all);
         begin
            Get (This.Name'Access, This'Unchecked_Access, Parent);
            if This.Index.Present then
               This.Index.Item := Get (Parent);
            end if;
            This.Profile := Get
                            (  ((Tag / 2) mod 4) = 0,
                               This'Unchecked_Access,
                               Parent
                            );
            if ((Tag / 2) mod 2) = 0 then
               This.Sequence := Get_Handled_Statement_Sequence
                                (  This'Unchecked_Access,
                                   This.Profile or Parent,
                                   Loop_Of
                                ) .all'Unchecked_Access;
            end if;
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Access_Type_Declaration_Node =>
         declare
            Tag     : constant Natural  := Get;
            Result  : constant Node_Ref :=
                      new Access_Type_Declaration
                          (  Aspects_Count => Tag / Mode_Type_Mod,
                             Mode =>
                                Mode_Type'Val (Tag mod Mode_Type_Mod)
                          );
            This : Access_Type_Declaration renames
                   Access_Type_Declaration (Result.all);
         begin
            This.Pointer := Get (This'Unchecked_Access, Parent);
            Get_Type (This);
            Trace_Result;
            return Result;
         end;
      when Array_Type_Declaration_Node =>
         declare
            Result : constant Node_Ref :=
                          new Array_Type_Declaration (Get);
            This   : Array_Type_Declaration renames
                     Array_Type_Declaration (Result.all);
         begin
            This.Definition := Get (This'Unchecked_Access, Parent);
            Get_Type (This);
            Trace_Result;
            return Result;
         end;
      when Assignment_Statement_Node =>
         declare
            Result : constant Node_Ref :=
                          new Assignment_Statement (Get);
            This : Assignment_Statement renames
                   Assignment_Statement (Result.all);
         begin
            This.Variable   := Get (Parent);
            This.Expression := Get (Parent);
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Asynchronous_Transfer_Control_Node =>
         declare
            Tag       : constant Natural  := Get;
            Trigger   : constant Node_Ref :=
                        Get_Program_Node (Get, Parent, Loop_Of);
            Abortable : constant Statement_Sequence_Ref :=
                        Get_Statement_Sequence (null, Parent, Loop_Of);
            Result : constant Node_Ref :=
                          new Asynchronous_Transfer_Control
                              (  Labels_Count => Tag / 2,
                                 Trigger      => Trigger_Node'Class
                                                 (  Trigger.all
                                                 ) 'Unchecked_Access,
                                 Abortable    => Abortable
                              );
            This : Asynchronous_Transfer_Control renames
                   Asynchronous_Transfer_Control (Result.all);
         begin
            Abortable.Outer := This'Unchecked_Access;
            if Tag mod 2 = 0 then
               This.Triggered :=
                  Get_Statement_Sequence
                  (  This'Unchecked_Access,
                     Parent,
                     Loop_Of
                  ) .all'Unchecked_Access;
            end if;
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when At_Clause_Node =>
         declare
            Result : constant Node_Ref := new At_Clause;
            This   : At_Clause renames At_Clause (Result.all);
         begin
            This.Address  := Get (Parent);
            This.Name     := Get (Parent);
            Get (This.Location);
            Trace_Result;
            return Result;
         end;
      when Attribute_Definition_Clause_Node =>
         declare
            Result : constant Node_Ref :=
                          new Attribute_Definition_Clause;
            This   : Attribute_Definition_Clause renames
                     Attribute_Definition_Clause (Result.all);
         begin
            This.Attribute := Get (Parent);
            This.Value     := Get (Parent);
            This.Name      := Get (Parent);
            Get (This.Location);
            Trace_Result;
            return Result;
         end;
      when Block_Statement_Node =>
         declare
            Tag          : constant Natural := Get;
            Declarations : constant Declaration_Context_Ptr :=
                                    Get ((Tag / 2) mod 2 = 0, Parent);
            Sequence : constant Handled_Statement_Sequence_Ref :=
                                Get_Handled_Statement_Sequence
                                (  null,
                                   Declarations or Parent,
                                   Loop_Of
                                );
            Code   : Handled_Statement_Sequence renames Sequence.all;
            Result : constant Node_Ref :=
                          new Block_Statement
                              (  Labels_Count => Tag / 4,
                                 Named        => Tag mod 2 /= 0,
                                 Sequence     => Code'Unchecked_Access
                              );
            This   : Block_Statement renames
                     Block_Statement (Result.all);
         begin
            This.Declarations := Declarations;
            Code.Outer := This'Unchecked_Access;
            if This.Named then
               This.Name.Item := Get (Parent);
            end if;
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Call_Statement_Node =>
         declare
            Result : constant Node_Ref := Get_Call_Statement;
         begin
            Trace_Result;
            return Result;
         end;
      when Case_Statement_Node =>
         declare
            Tag    : constant Natural  := Get;
            Result : constant Node_Ref :=
               new Case_Statement
                   (  Labels_Count => Tag / 2,
                      Count        => Get
                   );
            This : Case_Statement renames
                   Case_Statement (Result.all);
            procedure Get (Item : out Choice_Alternative) is
            begin
               Item.Choice := Get (Parent);
               Item.Code :=
                  Get_Statement_Sequence
                  (  This'Unchecked_Access,
                     Parent,
                     Loop_Of
                  ) .all'Unchecked_Access;
            end Get;
         begin
            This.Selector := Get (Parent);
            if Tag mod 2 = 0 then
               This.Default :=
                  Get_Statement_Sequence
                  (  This'Unchecked_Access,
                     Parent,
                     Loop_Of
                  ) .all'Unchecked_Access;
            end if;
            for Index in This.Alternatives'Range loop
               Get (This.Alternatives (Index));
            end loop;
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Chunk_Specification_Node =>
         declare
            Result : constant Node_Ref :=
               Get_Chunk (Chunk_Specification_Type'Val (Get), null);
         begin
            Trace_Result;
            return Result;
         end;
      when Conditional_Entry_Call_Node =>
         declare
            Tag           : constant Natural  := Get;
            Entry_Call    : constant Node_Ref :=
                            Get_Program_Node (Get, Parent, Loop_Of);
            Rejected_Code : constant Statement_Sequence_Ref :=
                     Get_Statement_Sequence (null, Parent, Loop_Of);
            Result : constant Node_Ref :=
                     new Conditional_Entry_Call
                         (  Labels_Count  => Tag / 2,
                            Entry_Call    => Call_Statement
                                             (  Entry_Call.all
                                             ) 'Unchecked_Access,
                            Rejected_Code => Rejected_Code
                         );
            This : Conditional_Entry_Call renames
                   Conditional_Entry_Call (Result.all);
         begin
            Rejected_Code.Outer := This'Unchecked_Access;
            if Tag mod 2 = 0 then
               This.Accepted_Code :=
                  Get_Statement_Sequence
                  (  This'Unchecked_Access,
                     Parent,
                     Loop_Of
                  ) .all'Unchecked_Access;
            end if;
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Decimal_Fixed_Point_Type_Declaration_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Decimal_Fixed_Point_Type_Declaration
                              (  Aspects_Count => Tag / 2,
                                 Constrained   => Tag mod 2 /= 0
                              );
            This   : Decimal_Fixed_Point_Type_Declaration renames
                     Decimal_Fixed_Point_Type_Declaration (Result.all);
         begin
            This.Delta_Value  := Get (Parent);
            This.Digits_Value := Get (Parent);
            Get_Scalar_Type (This);
            Trace_Result;
            return Result;
         end;
      when Declaration_Context_Node =>
         declare
            Result : constant Node_Ref :=
                              Get_Declaration_Context (Parent, Get);
         begin
            Trace_Result;
            return Result;
         end;
      when Delay_Statement_Node =>
         declare
            Tag    : constant Natural  := Get;
            Result : constant Node_Ref :=
                          new Delay_Statement
                              (  Labels_Count => Tag / 2,
                                 Relative     => Tag mod 2 /= 0
                              );
            This : Delay_Statement renames
                   Delay_Statement (Result.all);
         begin
            This.Time := Get (Parent);
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Derived_Type_Declaration_Node =>
         declare
            Tag    : constant Natural := Get;
            Count  : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Derived_Type_Declaration
                         (  Abstract_Type    => Tag mod 2 /= 0,
                            Limited_Type     => (Tag / 2) mod 2 /= 0,
                            Extension_Record => (Tag / 4) mod 2 /= 0,
                            Interfaces_Count => Get,
                            Aspects_Count    => Count
                         );
            This   : Derived_Type_Declaration renames
                     Derived_Type_Declaration (Result.all);
         begin
            This.Parent_Type   := Get (Parent);
            This.Discriminants := Get
                                  (  (Tag / 8) mod 2 = 0,
                                     This'Unchecked_Access,
                                     Parent
                                  );
            Get (This.Interfaces, Parent);
            if This.Extension_Record and then (Tag / 16) mod 2 = 0 then
               This.Extension := Get (This.Extension_Record, Parent);
            end if;
            Get_Type (This);
            Trace_Result;
            return Result;
         end;
      when Enumeration_Representation_Clause_Node =>
         declare
            Result : constant Node_Ref :=
                        new Enumeration_Representation_Clause (Get);
            This   : Enumeration_Representation_Clause renames
                     Enumeration_Representation_Clause (Result.all);
         begin
            Get (This.Enumeration, Parent);
            This.Name := Get (Parent);
            Get (This.Location);
            Trace_Result;
            return Result;
         end;
      when Enumeration_Type_Declaration_Node =>
         declare
            Count  : constant Natural := Get;
            Length : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Enumeration_Type_Declaration
                              (  Aspects_Count => Count,
                                 List_Length   => Length
                              );
            This   : Enumeration_Type_Declaration renames
                     Enumeration_Type_Declaration (Result.all);
         begin
            Get (This.List, Parent);
            Get_Type (This);
            Trace_Result;
            return Result;
         end;
      when Entry_Body_Node =>
         declare
            Tag           : constant Natural := Get;
            Profile       : constant Parameter_Profile_Ptr :=
                                     Get
                                     (  (Tag / 2) mod 2 = 0,
                                        null,
                                        Parent
                                     );
            Declarations  : constant Declaration_Context_Ptr :=
                                     Get (True, Profile or Parent);
            Context : constant Context_Location :=
                               Declarations or (Profile or Parent);
            Code    : constant Handled_Statement_Sequence_Ref :=
                               Get_Handled_Statement_Sequence
                               (  null,
                                  Context,
                                  null
                               );
            Result : constant Node_Ref :=
                 new Entry_Body
                     (  Has_Index    => Tag mod 2 /= 0,
                        Declarations =>
                           Declarations.all'Unchecked_Access,
                        Code         => Code.all'Unchecked_Access,
                        Overrides =>
                           Overriding_Indicator_Type'Val
                           (  (Tag / 4)
                           mod
                              Overriding_Indicator_Type_Mod
                           ),
                        Aspects_Count =>
                           Tag / (4 * Overriding_Indicator_Type_Mod)
                     );
            This   : Entry_Body renames Entry_Body (Result.all);
         begin
            Code.Outer := This'Unchecked_Access;
            if Profile /= null then
               Ref (Profile).Outer := This'Unchecked_Access;
            end if;
            This.Profile := Profile;
            This.Barrier := Get (Context);
            if This.Index.Present then
               This.Index.Item := Get (Parent);
            end if;
            Get_Body (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Entry_Declaration_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Entry_Declaration
                         (  Is_Family => Tag mod 2 /= 0,
                            Overrides =>
                               Overriding_Indicator_Type'Val
                               (  (Tag / 4)
                               mod
                                  Overriding_Indicator_Type_Mod
                               ),
                            Aspects_Count =>
                               Tag / (4 * Overriding_Indicator_Type_Mod)
                         );
            This   : Entry_Declaration renames
                     Entry_Declaration (Result.all);
         begin
            Get (This.Name'Access, This'Unchecked_Access, Parent);
            This.Profile := Get
                            (  (Tag / 2) mod 2 = 0,
                               This'Unchecked_Access,
                               Parent
                            );
            if This.Index.Present then
               This.Index.Item := Get (Parent);
            end if;
            Get (This.Aspects);
            Get (This.Location);
            Trace_Result;
            return Result;
         end;
      when Exception_Declaration_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Exception_Declaration
                         (  Count         => Tag,
                            Aspects_Count => Get
                         );
            This   : Exception_Declaration renames
                     Exception_Declaration (Result.all);
         begin
            Get (This.Names, This, Parent);
            Get (This.Aspects);
            Get (This.Location);
            Trace_Result;
            return Result;
         end;
      when Exception_Handler_Node =>
         declare
            Result : constant Exception_Handler_Ptr :=
                              Get (null, Parent, Loop_Of);
         begin
            Trace_Result;
            return Ref (Node_Ptr'(Result.all'Unchecked_Access));
         end;
      when Exception_Renaming_Node =>
         declare
            Result : constant Node_Ref :=
                          new Exception_Renaming (Get);
            This   : Exception_Renaming renames
                     Exception_Renaming (Result.all);
         begin
            Get_Renaming (This, Parent);
            Trace_Result;
            return Result;
         end;
      when Exit_Statement_Node =>
         declare
            Tag    : constant Natural  := Get;
            Result : constant Node_Ref :=
                     new Exit_Statement
                         (  Labels_Count => Tag / 4,
                            Conditional  => (Tag / 2) mod 2 /= 0,
                            Named        => Tag mod 2 /= 0
                         );
            This : Exit_Statement renames Exit_Statement (Result.all);
         begin
            This.Loop_Of := Loop_Of;
            if This.Loop_Name.Present then
               This.Loop_Name.Item := Get (Parent);
            end if;
            if This.Condition.Present then
               This.Condition.Item := Get (Parent);
            end if;
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Extended_Return_Statement_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Extended_Return_Statement
                              (  Labels_Count => Tag / 4,
                                 Initialized  => Tag mod 2 /= 0
                              );
            This : Extended_Return_Statement renames
                   Extended_Return_Statement (Result.all);
         begin
            Get (This.Result, This, Parent, True);
            if (Tag / 2) mod 2 = 0 then
               This.Code := Get_Handled_Statement_Sequence
                            (  This'Unchecked_Access,
                               By (This.Result),
                               Loop_Of
                            ) .all'Unchecked_Access;
            end if;
            if This.Initial.Present then
               This.Initial.Item := Get (Parent);
            end if;
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Floating_Point_Type_Declaration_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Floating_Point_Type_Declaration
                              (  Aspects_Count => Tag / 2,
                                 Constrained   => Tag mod 2 /= 0
                              );
            This   : Floating_Point_Type_Declaration renames
                     Floating_Point_Type_Declaration (Result.all);
         begin
            This.Digits_Value := Get (Parent);
            Get_Scalar_Type (This);
            Trace_Result;
            return Result;
         end;
      when For_Loop_Statement_Node =>
         declare
            Tag_1      : constant Natural := Get;
            Tag_2      : constant Natural := Get;
            Chunk_Mode : constant Natural :=
                            Tag_2 mod Chunk_Specification_Type_Mod;
            Context    : Context_Location := Parent;
            Result     : constant Node_Ref :=
               new For_Loop_Statement
                   (  Labels_Count        => Tag_1 / 8,
                      Named               => Tag_1 mod 2 /= 0,
                      Has_Iterator_Filter => (Tag_1 / 2) mod 2 /= 0,
                      Mode =>
                         Iterator_Mode'Val
                         (  (Tag_2 / Chunk_Specification_Type_Mod)
                         mod
                            Iterator_Mode_Mod
                         ),
                      Aspects_Count =>
                         (  Tag_2
                         /  (  Chunk_Specification_Type_Mod
                            *  Iterator_Mode_Mod
                   )     )  );
            This : For_Loop_Statement renames
                   For_Loop_Statement (Result.all);
         begin
            if Chunk_Mode < Chunk_Specification_Type_Mod - 1 then
               This.Chunk :=
                  Chunk_Specification
                  (  Get_Chunk
                     (  Chunk_Specification_Type'Val (Chunk_Mode),
                        This'Unchecked_Access
                     ) .all
                  ) 'Unchecked_Access;
               Context := This.Chunk or Context;
            end if;
            if This.Iterator_Filter.Present then
               This.Iterator_Filter.Item := Get (Context);
            end if;
            case This.Mode is
               when In_Interation_Mode | Of_Interation_Mode =>
                  This.In_Reverse := (Tag_1 / 4) mod 2 /= 0;
                  Get (This.Parameter, This, Context, True);
                  This.Iterator_Subtype := Get (Context);
                  Context := By (This.Parameter);
               when Formal_Part_Mode | List_Mode =>
                  This.Iterator_Call := Get (Context);
                  case This.Mode is
                     when In_Interation_Mode |
                          Of_Interation_Mode =>
                        null;
                     when Formal_Part_Mode =>
                        This.Formal_Part :=
                           Get
                           (  Have_It => (Tag_1 / 4) mod 2 = 0,
                              Outer   => This'Unchecked_Access,
                              Parent  => Context
                           );
                        Context := This.Formal_Part or Context;
                     when List_Mode =>
                        if (Tag_1 / 4) mod 2 = 0 then
                           This.Iterator :=
                              Identifier_List
                              (  Get_Identifier_List
                                 (  This'Unchecked_Access,
                                    Context
                                 ) .all
                              ) 'Unchecked_Access;
                           Context := By (This.Iterator.all);
                        end if;
                  end case;
            end case;
            Get (This.Aspects);
            Get_Loop (This, Context);
            Trace_Result;
            return Result;
         end;
      when Formal_Access_Type_Parameter_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Formal_Access_Type_Parameter
                        (  Mode          => Mode_Type'Val (Tag / 4),
                           Not_Null      => Tag mod 2 /= 0,
                           Defaulted     => (Tag / 2) mod 2 /= 0,
                           Aspects_Count => Get
                        );
            This   : Formal_Access_Type_Parameter renames
                     Formal_Access_Type_Parameter (Result.all);
         begin
            This.Pointer := Get (This'Unchecked_Access, Parent);
            Get_Formal_Type_Parameter (This);
            Trace_Result;
            return Result;
         end;
      when Formal_Array_Type_Parameter_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Formal_Array_Type_Parameter
                             (  Defaulted     => Tag mod 2 /= 0,
                                Aspects_Count => Tag / 2
                             );
            This   : Formal_Array_Type_Parameter renames
                     Formal_Array_Type_Parameter (Result.all);
         begin
            This.Definition := Get (This'Unchecked_Access, Parent);
            Get_Formal_Type_Parameter (This);
            Trace_Result;
            return Result;
         end;
      when Formal_Derived_Type_Parameter_Node =>
         declare
            Tag_1  : constant Natural := Get;
            Tag_2  : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Formal_Derived_Type_Parameter
                         (  Abstract_Type => Tag_1 mod 2 /= 0,
                            With_Private  => (Tag_1 / 2) mod 2 /= 0,
                            Defaulted     => (Tag_1 / 4) mod 2 /= 0,
                            Aspects_Count => Tag_1 / 8,
                            Mode =>
                               Derived_Interface_Type'Val
                               (  (Tag_2 / 2)
                               mod
                                  Derived_Interface_Type_Mod
                               ),
                            Interfaces_Count =>
                               (  Tag_2
                               /  (2 * Derived_Interface_Type_Mod)
                         )     );
            This   : Formal_Derived_Type_Parameter renames
                     Formal_Derived_Type_Parameter (Result.all);
         begin
            This.Parent_Type := Get (Parent);
            This.Discriminants :=
               Get (Tag_2 mod 2 = 0, This'Unchecked_Access, Parent);
            Get (This.Interfaces, Parent);
            Get_Formal_Type_Parameter (This);
            Trace_Result;
            return Result;
         end;
      when Formal_Function_Parameter_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Formal_Function_Parameter
                         (  Abstract_Subprogram => Tag mod 2 /= 0,
                            Default  =>
                               Formal_Subprogram_Default_Type'Val
                               (  (Tag / 4)
                               mod
                                  Formal_Subprogram_Default_Type_Mod
                               ),
                            Aspects_Count =>
                               (  Tag
                               /  (  4
                                  *  Formal_Subprogram_Default_Type_Mod
                         )     )  );
            This   : Formal_Function_Parameter renames
                     Formal_Function_Parameter (Result.all);
         begin
            This.Result := Get (This'Unchecked_Access, Parent);
            Get_Formal_Subprogram_Parameter
            (  This,
               Get
               (  (Tag / 2) mod 2 = 0,
                  This'Unchecked_Access,
                  Parent
            )  );
            Trace_Result;
            return Result;
         end;
      when Formal_Incomplete_Type_Parameter_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Formal_Incomplete_Type_Parameter
                         (  Tagged_Type   => Tag mod 2 /= 0,
                            Defaulted     => (Tag / 2) mod 2 /= 0
                         );
            This   : Formal_Incomplete_Type_Parameter renames
                     Formal_Incomplete_Type_Parameter (Result.all);
         begin
            This.Discriminants :=
               Get ((Tag / 4) mod 2 = 0, This'Unchecked_Access, Parent);
            Get_Formal_Type_Parameter (This);
            Trace_Result;
            return Result;
         end;
      when Formal_Interface_Type_Parameter_Node =>
         declare
            Tag_1  : constant Natural := Get;
            Tag_2  : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Formal_Interface_Type_Parameter
                              (  Defaulted     => Tag_1 mod 2 /= 0,
                                 Aspects_Count => Tag_1 / 4,
                                 Mode =>
                                    Interface_Type'Val
                                    (  Tag_2 mod Interface_Type_Mod
                                    ),
                                 Interfaces_Count =>
                                    Tag_2 / Interface_Type_Mod
                              );
            This   : Formal_Interface_Type_Parameter renames
                     Formal_Interface_Type_Parameter (Result.all);
         begin
            This.Discriminants :=
               Get
               (  (Tag_1 / 2) mod 2 = 0,
                  This'Unchecked_Access,
                  Parent
               );
            Get (This.Interfaces, Parent);
            Get_Formal_Type_Parameter (This);
            Trace_Result;
            return Result;
         end;
      when Formal_Package_Parameter_Node =>
         declare
            Result : constant Node_Ref :=
                          new Formal_Package_Parameter (Get);
            This   : Formal_Package_Parameter renames
                     Formal_Package_Parameter (Result.all);
         begin
            This.Target := Get (Parent);
            Get_Formal_Parameter (This);
            Trace_Result;
            return Result;
         end;
      when Formal_Private_Type_Parameter_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Formal_Private_Type_Parameter
                         (  Abstract_Type => (Tag /  2) mod 2 /= 0,
                            Limited_Type  => (Tag /  4) mod 2 /= 0,
                            Tagged_Type   => (Tag /  8) mod 2 /= 0,
                            Defaulted     => (Tag / 16) mod 2 /= 0,
                            Aspects_Count => Get
                         );
            This   : Formal_Private_Type_Parameter renames
                     Formal_Private_Type_Parameter (Result.all);
         begin
            This.Discriminants :=
               Get (Tag mod 2 = 0, This'Unchecked_Access, Parent);
            Get_Formal_Type_Parameter (This);
            Trace_Result;
            return Result;
         end;
      when Formal_Procedure_Parameter_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
               new Formal_Procedure_Parameter
                   (  Abstract_Subprogram => Tag mod 2 /= 0,
                      Default  =>
                         Formal_Subprogram_Default_Type'Val
                         (  (Tag / 4)
                         mod
                            Formal_Subprogram_Default_Type_Mod
                         ),
                      Aspects_Count =>
                         (  Tag
                         /  (  4
                            *  Formal_Subprogram_Default_Type_Mod
                   )     )  );
            This   : Formal_Procedure_Parameter renames
                     Formal_Procedure_Parameter (Result.all);
         begin
            Get_Formal_Subprogram_Parameter
            (  This,
               Get ((Tag / 2) mod 2 = 0, This'Unchecked_Access, Parent)
            );
            Trace_Result;
            return Result;
         end;
      when Formal_Scalar_Type_Parameter_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Formal_Scalar_Type_Parameter
                         (  Kind_Of =>
                               Formal_Scalar_Type'Val
                               (  (Tag / 2)
                               mod
                                  Formal_Scalar_Type_Mod
                               ),
                            Defaulted     => Tag mod 2 /= 0,
                            Aspects_Count =>
                               Tag / (2 * Formal_Scalar_Type_Mod)
                         );
            This   : Formal_Scalar_Type_Parameter renames
                     Formal_Scalar_Type_Parameter (Result.all);
         begin
            Get_Formal_Type_Parameter (This);
            Trace_Result;
            return Result;
         end;
      when Function_Body_Node =>
         declare
            Tag          : constant Natural := Get;
            Profile      : constant Parameter_Profile_Ptr :=
                                    Get
                                    (  (Tag / 2) mod 2 = 0,
                                       null,
                                       Parent
                                    );
            Declarations : constant Declaration_Context_Ptr :=
                                    Get (True, Profile or Parent);
            Code   : constant Handled_Statement_Sequence_Ref :=
                              Get_Handled_Statement_Sequence
                              (  null,
                                 By (Declarations),
                                 null
                              );
            Result : constant Node_Ref :=
                 new Function_Body
                     (  Declarations =>
                            Declarations.all'Unchecked_Access,
                        Code      => Code.all'Unchecked_Access,
                        Overrides =>
                           Overriding_Indicator_Type'Val
                           (  (Tag / 4)
                           mod
                              Overriding_Indicator_Type_Mod
                          ),
                        Separate_Body => Tag mod 2 /= 0,
                        Aspects_Count =>
                           Tag / (4 * Overriding_Indicator_Type_Mod)
                     );
            This   : Function_Body renames
                     Function_Body (Result.all);
         begin
            Get_Subroutine_Body (This, Profile, Code);
            This.Result := Get (This'Unchecked_Access, Parent);
            Trace_Result;
            return Result;
         end;
      when Function_Declaration_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Function_Declaration
                         (  Private_Unit        => Tag mod 2 /= 0,
                            Generic_Unit        => (Tag / 2) mod 2 /= 0,
                            Abstract_Subprogram => (Tag / 4) mod 2 /= 0,
                            Aspects_Count       => Get,
                            Overrides           =>
                               Overriding_Indicator_Type'Val (Tag / 16)
                         );
            This   : Function_Declaration renames
                     Function_Declaration (Result.all);
         begin
            Get_Subprogram_Specification (This, (Tag / 8) mod 2 = 0);
            This.Result := Get (This'Unchecked_Access, Parent);
            Trace_Result;
            return Result;
         end;
      when Function_Expression_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                 new Function_Expression
                     (  Overrides =>
                           Overriding_Indicator_Type'Val
                           (  (Tag / 2)
                           mod
                              Overriding_Indicator_Type_Mod
                          ),
                        Aspects_Count =>
                           Tag / (2 * Overriding_Indicator_Type_Mod)
                     );
            This   : Function_Expression renames
                     Function_Expression (Result.all);
         begin
            This.Profile :=
               Get (Tag mod 2 = 0, This'Unchecked_Access, Parent);
            Get (This.Name'Access, This'Unchecked_Access, Parent);
            This.Result := Get (This'Unchecked_Access, Parent);
            This.Expression := Get (This.Profile or Parent);
            Get (This.Aspects);
            Get (This.Location);
            Trace_Result;
            return Result;
         end;
      when Function_Instantiation_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Function_Instantiation
                         (  Overrides =>
                               Overriding_Indicator_Type'Val
                               (  Tag mod Overriding_Indicator_Type_Mod
                               ),
                            Aspects_Count =>
                               Tag / Overriding_Indicator_Type_Mod
                         );
            This   : Function_Instantiation renames
                     Function_Instantiation (Result.all);
         begin
            Get_Instantiation (This);
            Trace_Result;
            return Result;
         end;
      when Function_Renaming_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
               new Function_Renaming
                   (  Private_Unit  => Tag mod 2 /= 0,
                      Generic_Unit  => (Tag / 2) mod 2 /= 0,
                      Overrides     =>
                         Overriding_Indicator_Type'Val (Tag / 8),
                      Aspects_Count => Get
                   );
            This : Function_Renaming renames
                   Function_Renaming (Result.all);
         begin
            Get_Subprogram_Renaming (This, (Tag / 4) mod 2 = 0);
            This.Result := Get (This'Unchecked_Access, Parent);
            Trace_Result;
            return Result;
         end;
      when Function_Stub_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Function_Stub
                         (  Overrides =>
                               Overriding_Indicator_Type'Val
                               (  (Tag / 2)
                               mod
                                  Overriding_Indicator_Type_Mod
                               ),
                            Aspects_Count =>
                               Tag / (2 * Overriding_Indicator_Type_Mod)
                         );
            This   : Function_Stub renames Function_Stub (Result.all);
         begin
            This.Result := Get (This'Unchecked_Access, Parent);
            Get_Subprogram_Stub (This, Tag mod 2 = 0);
            Trace_Result;
            return Result;
         end;
      when Goto_Statement_Node =>
         declare
            Result : constant Node_Ref := new Goto_Statement (Get);
            This : Goto_Statement renames
                   Goto_Statement (Result.all);
         begin
            This.Name := Get (Parent);
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when If_Statement_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new If_Statement
                              (  Labels_Count => Get,
                                 Count        => Tag / 2
                              );
            This : If_Statement renames
                   If_Statement (Result.all);
         begin
            if Tag mod 2 = 0 then
               This.Default :=
                  Get_Statement_Sequence
                  (  This'Unchecked_Access,
                     Parent,
                     Loop_Of
                  ) .all'Unchecked_Access;
            end if;
            Get (This.Alternatives, This, Parent);
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Incomplete_Type_Declaration_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Incomplete_Type_Declaration
                              (  Tagged_Type   => Tag mod 2 /= 0
                              );
            This   : Incomplete_Type_Declaration renames
                     Incomplete_Type_Declaration (Result.all);
         begin
            This.Discriminants := Get
                                  (  (Tag / 2) mod 2 = 0,
                                     This'Unchecked_Access,
                                     Parent
                                  );
            Get_Type (This);
            Trace_Result;
            return Result;
         end;
      when Identifier_List_Node =>
         declare
            Result : constant Node_Ref :=
                              Get_Identifier_List (null, Parent);
         begin
            Trace_Result;
            return Result;
         end;
      when Interface_Type_Declaration_Node =>
         declare
            Tag_1  : constant Natural := Get;
            Tag_2  : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Interface_Type_Declaration
                         (  Interfaces_Count => Tag_1 / 2,
                            Mode =>
                               Interface_Type'Val
                               (  Tag_2 mod Interface_Type_Mod
                               ),
                            Aspects_Count =>
                               Tag_2 / Interface_Type_Mod
                         );
            This   : Interface_Type_Declaration renames
                     Interface_Type_Declaration (Result.all);
         begin
            This.Discriminants :=
               Get (Tag_1 mod 2 = 0, This'Unchecked_Access, Parent);
            Get (This.Interfaces, Parent);
            Get_Type (This);
            Trace_Result;
            return Result;
         end;
      when Handled_Statement_Sequence_Node =>
         declare
            Result : constant Node_Ref :=
                              Ref
                              (  Get_Handled_Statement_Sequence
                                 (  null,
                                    Parent,
                                    Loop_Of
                                 ) .all'Unchecked_Access
                              );
         begin
            Trace_Result;
            return Result;
         end;
      when Loop_Statement_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Loop_Statement
                              (  Named        => Tag mod 2 /= 0,
                                 Labels_Count => Tag / 2
                              );
            This : Loop_Statement renames
                   Loop_Statement (Result.all);
         begin
            Get_Loop (This, Parent);
            Trace_Result;
            return Result;
         end;
      when Modular_Type_Declaration_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Modular_Type_Declaration
                              (  Aspects_Count => Tag / 2,
                                 Constrained   => Tag mod 2 /= 0
                              );
            This   : Modular_Type_Declaration renames
                     Modular_Type_Declaration (Result.all);
         begin
            This.Modulus := Get (Parent);
            Get_Scalar_Type (This);
            Trace_Result;
            return Result;
         end;
      when Null_Procedure_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Null_Procedure
                         (  Private_Unit        => Tag mod 2 /= 0,
                            Generic_Unit        => (Tag / 2) mod 2 /= 0,
                            Abstract_Subprogram => (Tag / 4) mod 2 /= 0,
                            Aspects_Count       => Get,
                            Overrides           =>
                               Overriding_Indicator_Type'Val (Tag / 16)
                         );
            This   : Null_Procedure renames
                     Null_Procedure (Result.all);
         begin
            Get_Subprogram_Specification (This, (Tag / 8) mod 2 = 0);
            Trace_Result;
            return Result;
         end;
      when Null_Statement_Node =>
         declare
            Result : constant Node_Ref := new Null_Statement (Get);
            This   : Null_Statement renames
                     Null_Statement (Result.all);
         begin
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Object_Declaration_Node =>
         declare
            Tag        : constant Natural := Get;
            Count      : constant Natural := Get;
            Definition : constant Object_Specification_Ptr :=
                                  Get (null, Parent);
            Result : constant Node_Ref :=
                          new Object_Declaration
                              (  Count          => Count,
                                 Initialized    => Tag mod 2 /= 0,
                                 Immutable      => (Tag / 2) mod 2 /= 0,
                                 Aliased_Object => (Tag / 4) mod 2 /= 0,
                                 Definition     => Definition,
                                 Aspects_Count  => Tag / 8
                              );
            This   : Object_Declaration renames
                     Object_Declaration (Result.all);
         begin
            Add_Outer (This.Definition.all, This, Parent);
            if This.Initial.Present then
               This.Initial.Item := Get (Parent);
            end if;
            Get (This.Names, This, Parent);
            Get (This.Aspects);
            Get (This.Location);
            Trace_Result;
            return Result;
         end;
      when Object_Renaming_Node =>
         declare
            Result : constant Node_Ref := new Object_Renaming (Get);
            This   : Object_Renaming renames
                     Object_Renaming (Result.all);
         begin
            This.Type_Of := Get (This'Unchecked_Access, Parent);
            Get_Renaming (This, Parent);
            Trace_Result;
            return Result;
         end;
      when Ordinary_Fixed_Point_Type_Declaration_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Ordinary_Fixed_Point_Type_Declaration
                              (  Aspects_Count => Tag / 2,
                                 Constrained   => Tag mod 2 /= 0
                              );
            This   : Ordinary_Fixed_Point_Type_Declaration renames
                     Ordinary_Fixed_Point_Type_Declaration
                     (  Result.all
                     );
         begin
            This.Delta_Value := Get (Parent);
            Get_Scalar_Type (This);
            Trace_Result;
            return Result;
         end;
      when Package_Body_Node =>
         declare
            Tag          : constant Natural := Get;
            Declarations : constant Declaration_Context_Ptr :=
                                    Get (True, Parent);
            Context      : constant Context_Location :=
                                    By (Declarations);
            Result : constant Node_Ref :=
                          new Package_Body
                              (  Separate_Body => Tag mod 2 /= 0,
                                 Aspects_Count => Tag / 4,
                                 Declarations  =>
                                    Declarations.all'Unchecked_Access
                              );
            This   : Package_Body renames Package_Body (Result.all);
         begin
            This.Full_Name := Get (Parent);
            if This.Parent.Separate_Body then
               This.Parent.Parent := Get (Parent);
            end if;
            if (Tag / 2 mod 2) = 0 then
               This.Code := Get_Handled_Statement_Sequence
                            (  This'Unchecked_Access,
                               Context,
                               null
                            ) .all'Unchecked_Access;
            end if;
            Get_Body (This, This, Declarations.Parent);
            Trace_Result;
            return Result;
         end;
      when Package_Declaration_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                 new Package_Declaration
                     (  Private_Unit  => Tag mod 2 /= 0,
                        Generic_Unit  => (Tag / 2) mod 2 /= 0,
                        Aspects_Count => Tag / 8,
                        Public_Part   =>
                           Get
                           (  True,
                              (  Get ((Tag / 2) mod 2 /= 0, Parent)
                              or Parent
                     )     )  );
            This   : Package_Declaration renames
                     Package_Declaration (Result.all);
         begin
            This.Full_Name := Get (Parent);
            Get
            (  This.Name'Access,
               This'Unchecked_Access,
               This.Public_Part.Parent
            );
            This.Private_Part :=
               Get ((Tag / 4) mod 2 = 0, By (This.Private_Part));
            Get (This.Aspects);
            Get (This.Location);
            Trace_Result;
            return Result;
         end;
      when Package_Renaming_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Package_Renaming
                              (  Generic_Unit  => Tag mod 2 /= 0,
                                 Aspects_Count => Tag / 2
                              );
            This   : Package_Renaming renames
                     Package_Renaming (Result.all);
         begin
            This.Parent    := Get (Parent);
            This.Full_Name := Get (This.Parent);
            Get_Renaming (This, This.Parent);
            Trace_Result;
            return Result;
         end;
      when Package_Instantiation_Node =>
         declare
            Result : constant Node_Ref :=
                     new Package_Instantiation (Get);
            This   : Package_Instantiation renames
                     Package_Instantiation (Result.all);
         begin
            Get_Instantiation (This);
            Trace_Result;
            return Result;
         end;
      when Package_Stub_Node =>
         declare
            Result : constant Node_Ref := new Package_Stub (Get);
            This   : Package_Stub renames Package_Stub (Result.all);
         begin
            Get_Stub (This);
            Trace_Result;
            return Result;
         end;
      when Parallel_Block_Node =>
         declare
            Tag_1  : constant Natural := Get;
            Tag_2  : constant Natural := Get;
            Tag_3  : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Parallel_Block_Statement
                         (  Labels_Count  => Tag_1,
                            Aspects_Count => Tag_3 / 2,
                            Paths_Count =>
                               Tag_2 / Chunk_Specification_Type_Mod
                         );
            This : Parallel_Block_Statement renames
                   Parallel_Block_Statement (Result.all);
         begin
            if Tag_3 mod 2 = 0 then
               This.Chunk :=
                  Chunk_Specification
                  (  Get_Chunk
                     (  Chunk_Specification_Type'Val
                        (  Tag_2 mod Chunk_Specification_Type_Mod
                        ),
                        This'Unchecked_Access
                     ) .all
                  ) 'Unchecked_Access;
            end if;
            for Index in This.Paths'Range loop
               This.Paths (Index) := Get_Statement_Sequence
                                     (  This'Unchecked_Access,
                                        This.Chunk or Parent,
                                        Loop_Of
                                     ) .all'Unchecked_Access;
            end loop;
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Parameter_Profile_Node =>
         declare
            Result : constant Parameter_Profile_Ptr :=
                              Get (True, null, Parent);
         begin
            Trace_Result;
            return Ref (Node_Ptr'(Result.all'Unchecked_Access));
         end;
      when Parameter_Specification_Node =>
         declare
            Result : constant Parameter_Specification_Ptr :=
                              Get (Parent);
         begin
            Trace_Result;
            return Ref (Node_Ptr'(Result.all'Unchecked_Access));
         end;
      when Pragma_Clause_Node =>
         declare
            Result : constant Node_Ref := new Pragma_Clause (Get);
            This   : Pragma_Clause renames Pragma_Clause (Result.all);
            function Get return Pragma_Argument_Association is
               Named : constant Boolean := Boolean'Val (Get);
            begin
               if Named then
                  declare
                     Argument : constant Tokens.Argument_Token :=
                                         Get (Parent);
                  begin
                     return
                     (  Named    => True,
                        Value    => Get (Parent),
                        Argument => (  Present => True,
                                       Item    => Argument
                     )              );
                  end;
               else
                  return
                  (  Named    => False,
                     Value    => Get (Parent),
                     Argument => (Present => False)
                  );
               end if;
            end Get;
         begin
            This.Name := Get (Parent);
            for Index in This.Associations'Range loop
               This.Associations (Index) := Get;
            end loop;
            Get (This.Location);
            Trace_Result;
            return Result;
         end;
      when Private_Type_Declaration_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Private_Type_Declaration
                         (  Abstract_Type => Tag mod 2 /= 0,
                            Tagged_Type   => (Tag / 2) mod 2 /= 0,
                            Limited_Type  => (Tag / 4) mod 2 /= 0,
                            Aspects_Count => Tag / 16
                         );
            This   : Private_Type_Declaration renames
                     Private_Type_Declaration (Result.all);
         begin
            This.Discriminants :=
               Get ((Tag / 8) mod 2 = 0, This'Unchecked_Access, Parent);
            Get_Type (This);
            Trace_Result;
            return Result;
         end;
      when Private_Extension_Type_Declaration_Node =>
         declare
            Tag_1  : constant Natural := Get;
            Tag_2  : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Private_Extension_Type_Declaration
                         (  Abstract_Type => Tag_1 mod 2 /= 0,
                            Mode =>
                               Derived_Interface_Type'Val
                               (  Tag_2 mod Derived_Interface_Type_Mod
                               ),
                            Interfaces_Count =>
                               Tag_2 / Derived_Interface_Type_Mod,
                            Aspects_Count => Tag_1 / 4
                         );
            This   : Private_Extension_Type_Declaration renames
                     Private_Extension_Type_Declaration (Result.all);
         begin
            This.Parent_Type := Get (Parent);
            This.Discriminants :=
               Get ((Tag_1 / 2) mod 2 = 0, This'Unchecked_Access, Parent);
            Get (This.Interfaces, Parent);
            Get_Type (This);
            Trace_Result;
            return Result;
         end;
      when Procedure_Body_Node =>
         declare
            Tag     : constant Natural := Get;
            Profile : constant Parameter_Profile_Ptr :=
                               Get ((Tag / 2) mod 2 = 0, null, Parent);
            Declarations : constant Declaration_Context_Ptr :=
                                    Get (True, Profile or Parent);
            Code   : constant Handled_Statement_Sequence_Ref :=
                              Get_Handled_Statement_Sequence
                              (  null,
                                 By (Declarations),
                                 null
                              );
            Result : constant Node_Ref :=
                 new Procedure_Body
                     (  Declarations =>
                            Declarations.all'Unchecked_Access,
                         Code      => Code.all'Unchecked_Access,
                         Overrides =>
                            Overriding_Indicator_Type'Val
                            (  (Tag / 4)
                            mod
                               Overriding_Indicator_Type_Mod
                            ),
                         Separate_Body => Tag mod 2 /= 0,
                         Aspects_Count =>
                            Tag / (4 * Overriding_Indicator_Type_Mod)
                     );
            This   : Procedure_Body renames
                     Procedure_Body (Result.all);
         begin
            Get_Subroutine_Body (This, Profile, Code);
            Trace_Result;
            return Result;
         end;
      when Procedure_Declaration_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Procedure_Declaration
                         (  Private_Unit        => Tag mod 2 /= 0,
                            Generic_Unit        => (Tag / 2) mod 2 /= 0,
                            Abstract_Subprogram => (Tag / 4) mod 2 /= 0,
                            Aspects_Count       => Get,
                            Overrides           =>
                               Overriding_Indicator_Type'Val (Tag / 16)
                         );
            This   : Procedure_Declaration renames
                     Procedure_Declaration (Result.all);
         begin
            Get_Subprogram_Specification (This, (Tag / 8) mod 2 = 0);
            Trace_Result;
            return Result;
         end;
      when Procedure_Instantiation_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Procedure_Instantiation
                         (  Overrides =>
                               Overriding_Indicator_Type'Val
                               (  Tag mod Overriding_Indicator_Type_Mod
                               ),
                            Aspects_Count =>
                               Tag / Overriding_Indicator_Type_Mod
                         );
            This   : Procedure_Instantiation renames
                     Procedure_Instantiation (Result.all);
         begin
            Get_Instantiation (This);
            Trace_Result;
            return Result;
         end;
      when Procedure_Renaming_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
               new Procedure_Renaming
                   (  Private_Unit  => Tag mod 2 /= 0,
                      Generic_Unit  => (Tag / 2) mod 2 /= 0,
                      Overrides     =>
                         Overriding_Indicator_Type'Val (Tag / 8),
                      Aspects_Count => Get
                   );
            This : Procedure_Renaming renames
                   Procedure_Renaming (Result.all);
         begin
            Get_Subprogram_Renaming (This, (Tag / 4) mod 2 = 0);
            Trace_Result;
            return Result;
         end;
      when Procedure_Stub_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Procedure_Stub
                         (  Overrides =>
                               Overriding_Indicator_Type'Val
                               (  (Tag / 2)
                               mod
                                  Overriding_Indicator_Type_Mod
                               ),
                            Aspects_Count =>
                               Tag / (2 * Overriding_Indicator_Type_Mod)
                         );
            This   : Procedure_Stub renames Procedure_Stub (Result.all);
         begin
            Get_Subprogram_Stub (This, Tag mod 2 = 0);
            Trace_Result;
            return Result;
         end;
      when Protected_Body_Node =>
         declare
            Tag          : constant Natural := Get;
            Declarations : constant Declaration_Context_Ptr :=
                                    Get (True, Parent);
            Result : constant Node_Ref :=
                     new Protected_Body
                         (  Separate_Body => Tag mod 2 /= 0,
                            Aspects_Count => Tag / 2,
                            Declarations  =>
                               Declarations.all'Unchecked_Access
                         );
            This   : Protected_Body renames
                     Protected_Body (Result.all);
         begin
            if This.Parent.Separate_Body then
               This.Parent.Parent := Get (Parent);
            end if;
            Get_Body (This, This, Declarations.Parent);
            Trace_Result;
            return Result;
         end;
      when Protected_Stub_Node =>
         declare
            Result : constant Node_Ref := new Protected_Stub (Get);
            This   : Protected_Stub renames Protected_Stub (Result.all);
         begin
            Get_Stub (This);
            Trace_Result;
            return Result;
         end;
      when Protected_Type_Declaration_Node =>
         declare
            Tag_1  : constant Natural := Get;
            Tag_2  : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Protected_Type_Declaration
                         (  Interfaces_Count => Tag_2,
                            Public_Part      => Get (True, Parent),
                            Aspects_Count    => Tag_1 / 4
                         );
            This   : Protected_Type_Declaration renames
                     Protected_Type_Declaration (Result.all);
         begin
            This.Private_Part :=
               Get
               (  Tag_1 mod 2 = 0,
                  By (This.Public_Part.all'Unchecked_Access)
               );
            This.Discriminants := Get
                                  (  (Tag_1 / 2) mod 2 = 0,
                                     This'Unchecked_Access,
                                     Parent
                                  );
            Get (This.Interfaces, Parent);
            Get_Type (This);
            Trace_Result;
            return Result;
         end;
      when Raise_Statement_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Raise_Statement
                              (  Labels_Count => Tag / 4,
                                 Reraise      => Tag mod 2 /= 0,
                                 Has_Text     => (Tag / 2) mod 2 /= 0
                              );
            This : Raise_Statement renames
                   Raise_Statement (Result.all);
         begin
            if not This.Reraise then
               This.Name := Get (Parent);
               if This.Text.Present then
                  This.Text.Item := Get (Parent);
               end if;
            end if;
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Record_Representation_Clause_Node =>
         declare
            procedure Get (Item : out Component_Clause) is
            begin
               Item.Name      := Get (Parent);
               Item.Position  := Get (Parent);
               Item.Bit_Range := Get (Parent);
            end Get;
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Record_Representation_Clause
                         (  Has_Modulus      => Tag mod 2 /= 0,
                            Components_Count => Tag / 2
                         );
            This   : Record_Representation_Clause renames
                     Record_Representation_Clause (Result.all);
         begin
            for Index in This.Components'Range loop
               Get (This.Components (Index));
            end loop;
            if This.Modulus.Present then
               This.Modulus.Item := Get (Parent);
            end if;
            This.Name := Get (Parent);
            Get (This.Location);
            Trace_Result;
            return Result;
         end;
      when Record_Type_Declaration_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                     new Record_Type_Declaration
                         (  Abstract_Type => Tag mod 2 /= 0,
                            Tagged_Type   => (Tag / 2) mod 2 /= 0,
                            Limited_Type  => (Tag / 4) mod 2 /= 0,
                            Aspects_Count => Get
                         );
            This   : Record_Type_Declaration renames
                     Record_Type_Declaration (Result.all);
         begin
            This.Discriminants :=
               Get ((Tag / 8) mod 2 = 0, This'Unchecked_Access, Parent);
            This.Components :=
               Get ((Tag / 16) mod 2 = 0, This.Discriminants or Parent);
            Get_Type (This);
            Trace_Result;
            return Result;
         end;
      when Requeue_Statement_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Requeue_Statement
                              (  Labels_Count => Tag / 2,
                                 With_Abort   => Tag mod 2 /= 0
                              );
            This : Requeue_Statement renames
                   Requeue_Statement (Result.all);
         begin
            This.Name := Get (Parent);
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Selective_Accept_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Selective_Accept
                              (  Labels_Count => Tag / 2,
                                 Count        => Get
                              );
            This : Selective_Accept renames
                   Selective_Accept (Result.all);
            function Get return Select_Alternative is
               Tag     : constant Natural := Get;
               Guarded : constant Boolean := Tag mod 2 /= 0;
               Code    : Unhandled_Statement_Sequence_Ptr;
               Guard   : Tokens.Argument_Token;
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
                  Guard := Get (Parent);
               end if;
               if (Tag / 2) mod 2 /= 0 then
                  Code := Get_Statement_Sequence
                          (  This'Unchecked_Access,
                             Parent,
                             Loop_Of
                          ) .all'Unchecked_Access;
               end if;
               case Select_Alternative_Type'Val (Tag / 4) is
                  when Accept_Alternative =>
                     return
                     (  Guarded => Guarded,
                        Mode    => Accept_Alternative,
                        Guard   => Get_Guard,
                        Code    => Code,
                        Accept_Statement =>
                           Accept_Statement
                           (  Get_Program_Node
                              (  (  Program_Node_Class'Pos
                                    (  Accept_Statement_Node
                                    )
                                 +  Term_Class_Mod
                                 ),
                                 Parent,
                                 Loop_Of
                              ) .all
                           ) 'Unchecked_Access
                     );
                  when Delay_Alternative =>
                     return
                     (  Guarded => Guarded,
                        Mode    => Delay_Alternative,
                        Guard   => Get_Guard,
                        Code    => Code,
                        Delay_Statement =>
                           Delay_Statement
                           (  Get_Program_Node
                              (  (  Program_Node_Class'Pos
                                    (  Delay_Statement_Node
                                    )
                                 +  Term_Class_Mod
                                 ),
                                 Parent,
                                 Loop_Of
                              ) .all
                           ) 'Unchecked_Access
                     );
                  when Terminate_Alternative =>
                     return
                     (  Guarded => Guarded,
                        Mode    => Terminate_Alternative,
                        Guard   => Get_Guard
                     );
               end case;
            end Get;
         begin
            if Tag mod 2 = 0 then
               This.Default :=
                  Get_Statement_Sequence
                  (  This'Unchecked_Access,
                     Parent,
                     Loop_Of
                  ) .all'Unchecked_Access;
            end if;
            for Index in This.Alternatives'Range loop
               This.Alternatives (Index) := Get;
            end loop;
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Signed_Integer_Type_Declaration_Node =>
         declare
            Result : constant Node_Ref :=
                          new Signed_Integer_Type_Declaration (Get);
            This   : Signed_Integer_Type_Declaration renames
                     Signed_Integer_Type_Declaration (Result.all);
         begin
            Get_Scalar_Type (This);
            Trace_Result;
            return Result;
         end;
      when Simple_Return_Statement_Node =>
         declare
            Tag    : constant Natural  := Get;
            Result : constant Node_Ref :=
                          new Simple_Return_Statement
                              (  Labels_Count => Tag / 2,
                                 Has_Result   => Tag mod 2 /= 0
                              );
            This : Simple_Return_Statement renames
                   Simple_Return_Statement (Result.all);
         begin
            if This.Result.Present then
               This.Result.Item := Get (Parent);
            end if;
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Single_Protected_Declaration_Node =>
         declare
            Tag    : constant Natural  := Get;
            Result : constant Node_Ref :=
                          new Single_Protected_Declaration
                              (  Aspects_Count    => Tag / 4,
                                 Interfaces_Count => Get
                              );
            This : Single_Protected_Declaration renames
                   Single_Protected_Declaration (Result.all);
         begin
            Get (This.Name'Access, This'Unchecked_Access, Parent);
            This.Public_Part  := Get (Tag mod 2 = 0, Parent);
            This.Private_Part :=
               Get ((Tag / 2) mod 2 = 0, This.Public_Part or Parent);
            Get (This.Interfaces, Parent);
            Get (This.Aspects);
            Get (This.Location);
            Trace_Result;
            return Result;
         end;
      when Single_Task_Declaration_Node =>
         declare
            Tag    : constant Natural  := Get;
            Result : constant Node_Ref :=
                          new Single_Task_Declaration
                              (  Aspects_Count    => Tag / 4,
                                 Interfaces_Count => Get
                              );
            This   : Single_Task_Declaration renames
                     Single_Task_Declaration (Result.all);
         begin
            Get (This.Name'Access, This'Unchecked_Access, Parent);
            This.Public_Part  := Get (Tag mod 2 = 0, Parent);
            This.Private_Part :=
               Get ((Tag / 2) mod 2 = 0, This.Public_Part or Parent);
            Get (This.Interfaces, Parent);
            Get (This.Aspects);
            Get (This.Location);
            Trace_Result;
            return Result;
         end;
      when Singleton_Parameter_Node =>
         declare
            Result : constant Node_Ref := new Singleton_Parameter;
            This   : Singleton_Parameter renames
                     Singleton_Parameter (Result.all);
         begin
            Get_Compilation_Context (This, Parent, True);
            Get (This.Name'Access, This'Unchecked_Access, Parent);
            This.Type_Of := Get (This'Unchecked_Access, Parent);
            Trace_Result;
            return Result;
         end;
      when Statement_Sequence_Node =>
         declare
            Result : constant Node_Ref :=
                              Ref
                              (  Get_Statement_Sequence
                                 (  null,
                                    Parent,
                                    Loop_Of
                                 ) .all'Unchecked_Access
                              );
         begin
            Trace_Result;
            return Result;
         end;
      when Subtype_Declaration_Node =>
         declare
            Result : constant Node_Ref :=
                          new Subtype_Declaration (Get);
            This   : Subtype_Declaration renames
                     Subtype_Declaration (Result.all);
         begin
            This.Indication := Get (Parent);
            Get_Type (This);
            Trace_Result;
            return Result;
         end;
      when Task_Body_Node =>
         declare
            Tag          : constant Natural := Get;
            Declarations : constant Declaration_Context_Ptr :=
                                    Get (True, Parent);
            Code   : constant Handled_Statement_Sequence_Ref :=
                              Get_Handled_Statement_Sequence
                              (  null,
                                 By (Declarations),
                                 null
                              );
            Result : constant Node_Ref :=
               new Task_Body
                   (  Separate_Body => Tag mod 2 /= 0,
                      Aspects_Count => Tag / 2,
                      Code          => Code,
                      Declarations  =>
                         Declarations.all'Unchecked_Access
                   );
            This   : Task_Body renames Task_Body (Result.all);
         begin
            Code.Outer := This'Unchecked_Access;
            if This.Parent.Separate_Body then
               This.Parent.Parent := Get (Parent);
            end if;
            Get_Body (This, This, Declarations.Parent);
            Trace_Result;
            return Result;
         end;
      when Task_Stub_Node =>
         declare
            Result : constant Node_Ref := new Task_Stub (Get);
            This   : Task_Stub renames Task_Stub (Result.all);
         begin
            Get_Stub (This);
            Trace_Result;
            return Result;
         end;
      when Task_Type_Declaration_Node =>
         declare
            Tag     : constant Natural := Get;
            Result  : constant Node_Ref :=
                      new Task_Type_Declaration
                          (  Interfaces_Count => Get,
                             Aspects_Count    => Tag / 8
                          );
            This    : Task_Type_Declaration renames
                      Task_Type_Declaration (Result.all);
            Context : Context_Location := Parent;
         begin
            This.Discriminants :=
               Get (Tag mod 2 = 0, This'Unchecked_Access, Context);
            Context := This.Discriminants or Parent;
            This.Public_Part := Get ((Tag / 2) mod 2 = 0, Context);
            Context := This.Public_Part or Context;
            This.Private_Part := Get ((Tag / 4) mod 2 = 0, Context);
            Get (This.Interfaces, Parent);
            Get_Type (This);
            Trace_Result;
            return Result;
         end;
      when Timed_Entry_Call_Node =>
         declare
            Tag        : constant Natural  := Get;
            Entry_Call : constant Node_Ref :=
                         Get_Program_Node (Get, Parent, Loop_Of);
            Timer      : constant Node_Ref :=
                         Get_Program_Node (Get, Parent, Loop_Of);
            Result     : constant Node_Ref :=
                         new Timed_Entry_Call
                             (  Labels_Count => Tag / 4,
                                Entry_Call   => Call_Statement
                                                (  Entry_Call.all
                                                ) 'Unchecked_Access,
                                Timer        => Delay_Statement
                                                (  Timer.all
                                                ) 'Unchecked_Access
                             );
            This : Timed_Entry_Call renames
                   Timed_Entry_Call (Result.all);
         begin
            if Tag mod 2 = 0 then
               This.Accepted_Code :=
                  Get_Statement_Sequence
                  (  This'Unchecked_Access,
                     Parent,
                     Loop_Of
                  ) .all'Unchecked_Access;
            end if;
            if (Tag / 2) mod 2 = 0 then
               This.Expired_Code :=
                  Get_Statement_Sequence
                  (  This'Unchecked_Access,
                     Parent,
                     Loop_Of
                  ) .all'Unchecked_Access;
            end if;
            Get_Labels (This, This, Parent);
            Trace_Result;
            return Result;
         end;
      when Use_Package_Clause_Node =>
         declare
            Result : constant Node_Ref := new Use_Package_Clause (Get);
            This   : Use_Package_Clause renames
                     Use_Package_Clause (Result.all);
         begin
            This.Enclosing := Parent;
            Get_Context_Clause (This);
            Trace_Result;
            return Result;
         end;
      when Use_Type_Clause_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new Use_Type_Clause
                              (  All_Type => Tag mod 2 /= 0,
                                 Length   => Tag / 2
                              );
            This   : Use_Type_Clause renames
                     Use_Type_Clause (Result.all);
         begin
            This.Enclosing := Parent;
            Get_Context_Clause (This);
            Trace_Result;
            return Result;
         end;
      when Variant_Part_Node =>
         declare
            Result : constant Node_Ref := new Variant_Part (Get);
            This   : Variant_Part renames Variant_Part (Result.all);
         begin
            This.Discriminant := Get (Parent);
            for Index in This.Alternatives'Range loop
               This.Alternatives (Index) := Get (Parent);
            end loop;
            Get (This.Location);
            Trace_Result;
            return Result;
         end;
      when Variant_Part_Item_Node =>
         declare
            Result : constant Variant_Part_Item_Ptr := Get (Parent);
         begin
            return Ref (Node_Ptr'(Result.all'Unchecked_Access));
         end;
      when While_Loop_Statement_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new While_Loop_Statement
                              (  Named        => Tag mod 2 /= 0,
                                 Labels_Count => Tag / 2
                              );
            This : While_Loop_Statement renames
                   While_Loop_Statement (Result.all);
         begin
            This.Condition := Get (Parent);
            Get_Loop (This, Parent);
            Trace_Result;
            return Result;
         end;
      when With_Clause_Node =>
         declare
            Tag    : constant Natural := Get;
            Result : constant Node_Ref :=
                          new With_Clause
                              (  Limited_With => Tag mod 2 /= 0,
                                 Private_With => (Tag / 2) mod 2 /= 0,
                                 Length       => Tag / 4
                              );
            This   : With_Clause renames
                     With_Clause (Result.all);
         begin
            Get_Context_Clause (This);
            Trace_Result;
            return Result;
         end;
   end case;
end Get_Program_Node;
