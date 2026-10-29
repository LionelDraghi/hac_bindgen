--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Declarations.Specifications              Spring, 2026       --
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

with Ada.Unchecked_Conversion;

package body Parsers.Ada_Syntax_Analyzer.Declarations.Specifications is

   type Parameter_Profile_Ref is access all Parameter_Profile;
   function Ref is new Ada.Unchecked_Conversion
                       (  Parameter_Profile_Ptr,
                          Parameter_Profile_Ref
                       );

   procedure Set_Parent
             (  Profile : in out Parameter_Profile;
                Parent  : Context_Location
             );

   procedure Add_Outer
             (  Definition : Anonymous_Access_Definition;
                Node       : Program_Node'Class;
                Parent     : Context_Location
             )  is
   begin
      if Definition.Mode in Access_To_Subprogram_Mode then
         if Definition.Profile /= null then
            declare
               Profile : Parameter_Profile renames
                         Ref (Definition.Profile).all;
            begin
               Profile.Outer := Node'Unchecked_Access;
               Set_Parent (Profile, Parent);
            end;
         end if;
         case Definition.Mode is
            when Access_To_Function | Access_To_Protected_Function =>
               Add_Outer (Definition.Result.all, Node, Parent);
            when others =>
               null;
         end case;
      end if;
   end Add_Outer;

   procedure Add_Outer
             (  Definition : Array_Type_Specification;
                Node       : Program_Node'Class;
                Parent     : Context_Location
             )  is
   begin
      case Definition.Mode is
         when Access_Mode =>
            Add_Outer (Definition.Access_Component, Node, Parent);
         when others =>
            null;
      end case;
   end Add_Outer;

   procedure Add_Outer
             (  Definition : Object_Specification;
                Node       : Program_Node'Class;
                Parent     : Context_Location
             )  is
   begin
      case Definition.Mode is
         when Access_Mode =>
            Add_Outer (Definition.Pointer, Node, Parent);
         when Array_Mode =>
            Add_Outer (Definition.Array_Object.all, Node, Parent);
         when others =>
            null;
      end case;
   end Add_Outer;

   function Equal
            (  Left  : Anonymous_Access_Definition;
               Right : Anonymous_Access_Definition;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Left.Mode     /= Right.Mode or else
         Left.Not_Null /= Right.Not_Null then
         return Inequal;
      end if;
      case Left.Mode is
         when Access_To_All..Access_To_Variable =>
            return Equal (Left.Object, Right.Object, Mode);
         when Access_To_Subprogram_Mode =>
            if not Equal (Left.Profile, Right.Profile, Mode) then
               return Inequal;
            end if;
            case Left.Mode is
               when Access_To_Function | Access_To_Protected_Function =>
                  return Equal
                         (  Left.Result.all,
                            Right.Result.all,
                            Mode
                         );
               when others =>
                  return True;
            end case;
      end case;
   end Equal;

   function Equal
            (  Left  : Array_Type_Specification;
               Right : Array_Type_Specification;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Left.Mode /= Right.Mode then
         return Inequal;
      elsif Left.Aliased_Component /= Right.Aliased_Component then
         return Inequal;
      elsif not Equal (Left.Indices, Right.Indices, Mode) then
         return Inequal;
      end if;
      case Left.Mode is
         when Access_Mode =>
            return Equal
                   (  Left.Access_Component,
                      Right.Access_Component,
                      Mode
                   );
         when Object_Mode =>
            return Equal
                   (  Left.Object_Component,
                      Right.Object_Component,
                      Mode
                   );
      end case;
   end Equal;

   function Equal
            (  Left  : At_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in At_Clause then
         return Inequal;
      else
         declare
            Other : At_Clause renames At_Clause (Right);
         begin
            if not Equal (Left.Address, Other.Address, Mode) then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
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
            (  Left  : Attribute_Definition_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Attribute_Definition_Clause then
         return Inequal;
      else
         declare
            Other : Attribute_Definition_Clause renames
                    Attribute_Definition_Clause (Right);
         begin
            if not Equal (Left.Attribute, Other.Attribute, Mode) then
               return Inequal;
            elsif not Equal (Left.Value, Other.Value, Mode) then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
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
            (  Left  : Entry_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Entry_Declaration then
         return Inequal;
      else
         declare
            Other : Entry_Declaration renames
                    Entry_Declaration (Right);
         begin
            if Left.Is_Family /= Other.Is_Family then
               return Inequal;
            elsif Left.Overrides /= Other.Overrides then
               return Inequal;
            elsif not Equal (Left.Profile, Other.Profile, Mode) then
               return Inequal;
            elsif not Equal (Left.Index, Other.Index, Mode) then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Aspects, Other.Aspects, Mode) then
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
            (  Left  : Enumeration_Representation_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Enumeration_Representation_Clause then
         return Inequal;
      else
         declare
            Other : Enumeration_Representation_Clause renames
                    Enumeration_Representation_Clause (Right);
         begin
            if not Equal
                   (  Left.Enumeration,
                      Other.Enumeration,
                      Mode
                   )  then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
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
            (  Left  : Exception_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Exception_Declaration then
         return Inequal;
      else
         declare
            Other : Exception_Declaration renames
                    Exception_Declaration (Right);
         begin
            if Left.Count /= Other.Count then
               return Inequal;
            end if;
            for Index in Left.Names'Range loop
               if not Equal
                      (  Left.Names (Index),
                         Other.Names (Index),
                         Mode
                      )  then
                  return Inequal;
               end if;
            end loop;
            if not Equal (Left.Aspects, Other.Aspects, Mode) then
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
            (  Left  : Function_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Function_Declaration then
         return Inequal;
      else
         declare
            Other : Function_Declaration renames
                    Function_Declaration (Right);
         begin
            if Left.Private_Unit /= Other.Private_Unit then
               return Inequal;
            elsif Left.Generic_Unit /= Other.Generic_Unit then
               return Inequal;
            elsif Left.Abstract_Subprogram /=
                  Other.Abstract_Subprogram then
               return Inequal;
            elsif Left.Overrides /= Other.Overrides then
               return Inequal;
            elsif not Equal (Left.Profile, Other.Profile, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Parent,
                         Other.Parent,
                         Mode and not Follow_Links
                      )  then
               return Inequal;
            elsif not Equal
                      (  Left.Result.all,
                         Other.Result.all,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal (Left.Full_Name, Other.Full_Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Aspects, Other.Aspects, Mode) then
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
            (  Left  : Function_Instantiation;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Function_Instantiation then
         return Inequal;
      else
         declare
            Other : Function_Instantiation renames
                    Function_Instantiation (Right);
         begin
            if Left.Overrides /= Other.Overrides then
               return Inequal;
            elsif not Equal (Left.Full_Name, Other.Full_Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Target, Other.Target, Mode) then
               return Inequal;
            elsif not Equal (Left.Aspects, Other.Aspects, Mode) then
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
            (  Left  : Identifier_List;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
      use Strings_Edit.Lexicographical_Order;
   begin
      if Right not in Identifier_List then
         return Inequal;
      else
         declare
            Other : Identifier_List renames Identifier_List (Right);
         begin
            if Left.Outer = null or else Other.Outer = null then
               raise Constraint_Error;
            end if;
            if Left.Parameters_Count /= Other.Parameters_Count then
               return Inequal;
            end if;
            for Index in Left.List'Range loop
               if not Equal
                      (  Left.List (Index),
                         Other.List (Index),
                         Mode
                      )
               then
                  return Inequal;
               end if;
            end loop;
            if not  Equal (Left.Parent, Other.Parent, Mode) then
               return Inequal;
            elsif Program_Node_Class'(Get_Class (Left.Outer.all)) /=
                  Program_Node_Class'(Get_Class (Other.Outer.all)) then
               return Inequal;
            elsif 0 = (Location_Independent and Mode) then
               if Left.Scope /= Other.Scope then
                  return Inequal;
               elsif 0 = (Source_Independent and Mode) then
                  if Compare (Left.File, Other.File) /= Equal then
                     return Inequal;
                  end if;
               end if;
            end if;
            return True;
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Object_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Object_Declaration then
         return Inequal;
      else
         declare
            Other : Object_Declaration renames
                    Object_Declaration (Right);
         begin
            if Left.Count /= Other.Count then
               return Inequal;
            end if;
            for Index in Left.Names'Range loop
               if not Equal
                      (  Left.Names (Index),
                         Other.Names (Index),
                         Mode
                      )
               then
                  return Inequal;
               end if;
            end loop;
            if Left.Initialized /= Other.Initialized then
               return Inequal;
            elsif Left.Immutable /= Other.Immutable then
               return Inequal;
            elsif Left.Aliased_Object /= Other.Aliased_Object then
               return Inequal;
            elsif not Equal
                      (  Left.Definition.all,
                         Other.Definition.all,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal (Left.Aspects, Other.Aspects, Mode) then
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
            (  Left  : Object_Specification;
               Right : Object_Specification;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Left.Mode /= Right.Mode then
         return Inequal;
      end if;
      case Left.Mode is
         when Object_Mode =>
            return Equal (Left.Variable, Right.Variable, Mode);
         when In_Mode | Inout_Mode | Out_Mode =>
            return Left.Not_Null = Right.Not_Null and then
                   Equal (Left.Result, Right.Result, Mode);
         when Access_Mode =>
            return Equal (Left.Pointer, Right.Pointer, Mode);
         when Array_Mode =>
            return Equal
                   (  Left.Array_Object.all,
                      Right.Array_Object.all,
                      Mode
                   );
         when Constant_Mode =>
            return True;
      end case;
   end Equal;

   function Equal
            (  Left  : Package_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Package_Declaration then
         return Inequal;
      else
         declare
            Other : Package_Declaration renames
                    Package_Declaration (Right);
         begin
            if Left.Private_Unit /= Other.Private_Unit then
               return Inequal;
            elsif Left.Generic_Unit /= Other.Generic_Unit then
               return Inequal;
            elsif not Equal
                      (  Left.Public_Part.all,
                         Other.Public_Part.all,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal (Left.Full_Name, Other.Full_Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif (Left.Private_Part = null) /=
                  (Other.Private_Part = null) then
               return Inequal;
            elsif Left.Private_Part /= null and then
                  not Equal
                      (  Left.Public_Part.all,
                         Other.Public_Part.all,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal (Left.Aspects, Other.Aspects, Mode) then
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
            (  Left  : Package_Instantiation;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Package_Instantiation then
         return Inequal;
      else
         declare
            Other : Package_Instantiation renames
                    Package_Instantiation (Right);
         begin
            if not Equal (Left.Full_Name, Other.Full_Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Target, Other.Target, Mode) then
               return Inequal;
            elsif not Equal (Left.Aspects, Other.Aspects, Mode) then
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
            (  Left  : Parameter_Profile;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Parameter_Profile then
         return Inequal;
      else
         declare
            Other : Parameter_Profile renames
                    Parameter_Profile (Right);
         begin
            if Left.Outer = null or else Other.Outer = null then
               raise Constraint_Error;
            end if;
            if Left.Parameters_Count /= Other.Parameters_Count then
               return Inequal;
            end if;
            for Index in Left.List'Range loop
               if not Equal
                      (  Left.List (Index).all,
                         Other.List
                         (  Index
                         -  Left.List'First
                         +  Other.List'First
                         ) .all,
                         Mode
                      )  then
                  return Inequal;
               end if;
            end loop;
            if not Equal
                   (  Left.Parent,
                      Other.Parent,
                      Mode and not Follow_Links
                   )  then
               return Inequal;
            elsif Program_Node_Class'(Get_Class (Left.Outer.all)) /=
                  Program_Node_Class'(Get_Class (Other.Outer.all)) then
               return Inequal;
            elsif 0 = (Location_Independent and Mode) then
               if Left.Scope /= Other.Scope then
                  return Inequal;
               elsif Left.File /= Other.File then
                  return Inequal;
               end if;
            end if;
            return True;
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Parameter_Profile_Ptr;
               Right : Parameter_Profile_Ptr;
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
            (  Left  : Parameter_Specification;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
      procedure Check
                (  Profile : Parameter_Profile_Ptr;
                   Item    : Parameter_Specification
                )  is
      begin
         if Profile = null then
            raise Constraint_Error;
         end if;
         for Index in Profile.List'Range loop
            if Profile.List (Index) = Item'Unchecked_Access then
               return;
            end if;
         end loop;
         raise Constraint_Error;
      end Check;
   begin
      if Right not in Parameter_Specification then
         return Inequal;
      else
         declare
            Other : Parameter_Specification renames
                    Parameter_Specification (Right);
         begin
            Check (Left.Profile, Left);
            Check (Other.Profile, Other);
            if Left.Parameters_Count /= Other.Parameters_Count then
               return Inequal;
            elsif Left.Mode /= Other.Mode then
               return Inequal;
            elsif Left.Defaulted /= Other.Defaulted then
               return Inequal;
            end if;
            for Index in Left.Parameters'Range loop
               if not Equal
                      (  Left.Parameters (Index),
                         Other.Parameters
                         (  Index
                         -  Left.Parameters'First
                         +  Other.Parameters'First
                         ),
                         Mode
                      )  then
                  return Inequal;
               end if;
            end loop;
            case Left.Mode is
               when In_Mode | Inout_Mode | Out_Mode =>
                  if Left.Not_Null /= Other.Not_Null or else
                     not Equal (Left.Value, Other.Value, Mode)
                  then
                     return Inequal;
                  end if;
               when Access_Mode =>
                  if not Equal (Left.Pointer, Other.Pointer, Mode) then
                     return Inequal;
                  end if;
            end case;
            if not Equal (Left.Default, Other.Default, Mode) then
               return Inequal;
            elsif not Equal (Left.Aspects, Other.Aspects, Mode) then
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
            (  Left  : Parameter_Type;
               Right : Parameter_Type;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Left.Present            /= Right.Present            or else
         Left.Aliased_Parameter  /= Right.Aliased_Parameter  or else
         Left.Constant_Parameter /= Right.Constant_Parameter or else
         Left.Mode               /= Right.Mode
      then
         return Inequal;
      end if;
      if Left.Present then
         case Left.Mode is
            when Access_Mode =>
               return Equal
                      (  Left.Access_Parameter,
                         Right.Access_Parameter,
                         Mode
                      );
            when Object_Mode =>
               return Equal
                      (  Left.Object_Parameter,
                         Right.Object_Parameter,
                         Mode
                      );
         end case;
      else
         return True;
      end if;
   end Equal;

   function Equal
            (  Left  : Procedure_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Procedure_Declaration then
         return Inequal;
      else
         declare
            Other : Procedure_Declaration renames
                    Procedure_Declaration (Right);
         begin
            if Left.Private_Unit /= Other.Private_Unit then
               return Inequal;
            elsif Left.Generic_Unit /= Other.Generic_Unit then
               return Inequal;
            elsif Left.Abstract_Subprogram /=
                  Other.Abstract_Subprogram then
               return Inequal;
            elsif Left.Overrides /= Other.Overrides then
               return Inequal;
            elsif not Equal
                  (  Left.Parent,
                     Other.Parent,
                     Mode and not Follow_Links
                  )  then
               return Inequal;
            elsif not Equal (Left.Profile, Other.Profile, Mode) then
               return Inequal;
            elsif not Equal (Left.Full_Name, Other.Full_Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Aspects, Other.Aspects, Mode) then
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
            (  Left  : Procedure_Instantiation;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Procedure_Instantiation then
         return Inequal;
      else
         declare
            Other : Procedure_Instantiation renames
                    Procedure_Instantiation (Right);
         begin
            if Left.Overrides /= Other.Overrides then
               return Inequal;
            elsif not Equal (Left.Full_Name, Other.Full_Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Target, Other.Target, Mode) then
               return Inequal;
            elsif not Equal (Left.Aspects, Other.Aspects, Mode) then
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
            (  Left  : Record_Representation_Clause;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
      function Equal (Left, Right : Component_Clause) return Boolean is
      begin
         if not Equal (Left.Name, Right.Name, Mode) then
            return Inequal;
         elsif not Equal (Left.Position, Right.Position, Mode) then
            return Inequal;
         elsif not Equal (Left.Bit_Range, Right.Bit_Range, Mode) then
            return Inequal;
         end if;
         return True;
      end Equal;
   begin
      if Right not in Record_Representation_Clause then
         return Inequal;
      else
         declare
            Other : Record_Representation_Clause renames
                    Record_Representation_Clause (Right);
         begin
            if Left.Components_Count /= Other.Components_Count then
               return Inequal;
            end if;
            for Index in Left.Components'Range loop
               if not Equal
                      (  Left.Components (Index),
                         Other.Components (Index)
                      )  then
                  return Inequal;
               end if;
            end loop;
            if Left.Has_Modulus /= Other.Has_Modulus then
               return Inequal;
            elsif Left.Has_Modulus and then
                  not Equal (Left.Modulus, Other.Modulus, Mode) then
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
            (  Left  : Single_Protected_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Single_Protected_Declaration then
         return Inequal;
      else
         declare
            Other : Single_Protected_Declaration renames
                    Single_Protected_Declaration (Right);
         begin
            if not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Interfaces,
                         Other.Interfaces,
                         Mode
                      )  then
               return Inequal;
            elsif (Left.Public_Part = null) /=
               (Other.Public_Part = null) then
               return Inequal;
            elsif Left.Public_Part /= null and then
                  not Equal
                      (  Left.Public_Part.all,
                         Other.Public_Part.all,
                         Mode
                      )  then
               return Inequal;
            elsif (Left.Private_Part = null) /=
                  (Other.Private_Part = null) then
               return Inequal;
            elsif Left.Private_Part /= null and then
                  not Equal
                      (  Left.Private_Part.all,
                         Other.Private_Part.all,
                         Mode
                      ) then
               return Inequal;
            elsif not Equal (Left.Aspects, Other.Aspects, Mode) then
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
            (  Left  : Single_Task_Declaration;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Single_Task_Declaration then
         return Inequal;
      else
         declare
            Other : Single_Task_Declaration renames
                    Single_Task_Declaration (Right);
         begin
            if not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal
                      (  Left.Interfaces,
                         Other.Interfaces,
                         Mode
                      )  then
               return Inequal;
            elsif (Left.Public_Part = null) /=
                  (Other.Public_Part = null) then
               return Inequal;
            elsif Left.Public_Part /= null and then
                  not Equal
                      (  Left.Public_Part.all,
                         Other.Public_Part.all,
                         Mode
                      ) then
               return Inequal;
            elsif (Left.Private_Part = null) /=
                  (Other.Private_Part = null) then
               return Inequal;
            elsif Left.Private_Part /= null and then
                  not Equal
                      (  Left.Private_Part.all,
                         Other.Private_Part.all,
                         Mode
                      )  then
               return Inequal;
            elsif not Equal (Left.Aspects, Other.Aspects, Mode) then
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
            (  Left  : Singleton_Parameter;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
      use Strings_Edit.Lexicographical_Order;
   begin
      if Right not in Singleton_Parameter then
         return Inequal;
      else
         declare
            Other : Singleton_Parameter renames
                    Singleton_Parameter (Right);
         begin
            if not Equal (Left.Name, Other.Name, Mode) then
               return Inequal;
            elsif not Equal (Left.Type_Of, Other.Type_Of, Mode) then
               return Inequal;
            elsif not Equal (Left.Parent, Other.Parent, Mode) then
               return Inequal;
            elsif 0 = (Location_Independent and Mode) then
               if Left.Scope /= Other.Scope then
                  return Inequal;
               elsif 0 = (Source_Independent and Mode) then
                  if Compare (Left.File, Other.File) /= Equal then
                     return Inequal;
                  end if;
               end if;
            end if;
            return True;
         end;
      end if;
   end Equal;

   function Equal
            (  Left  : Variant_Part_Item;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Variant_Part_Item then
         return Inequal;
      else
         declare
            Other : Variant_Part_Item renames
                    Variant_Part_Item (Right);
         begin
            if not Equal
                   (  Left.Components.all,
                      Other.Components.all,
                      Mode
                   ) then
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
            (  Left  : Variant_Part;
               Right : Node'Class;
               Mode  : Node_Equivalence := Node_Equivalence'Last
            )  return Boolean is
   begin
      if Right not in Variant_Part then
         return Inequal;
      else
         declare
            Other : Variant_Part renames Variant_Part (Right);
         begin
            if not Equal
                   (  Left.Discriminant,
                      Other.Discriminant,
                      Mode
                   )  then
               return Inequal;
            elsif Left.Count /= Other.Count then
               return Inequal;
            elsif 0 = (Location_Independent and Mode) then
               if Left.Location /= Other.Location then
                  return Inequal;
               end if;
            end if;
            for Index in Left.Alternatives'Range loop
               if not Equal
                      (  Left.Alternatives (Index).all,
                         Other.Alternatives (Index).all,
                         Mode
                      )  then
                  return Inequal;
               end if;
            end loop;
            return True;
         end;
      end if;
   end Equal;

   function Get_Class (Item : At_Clause) return Program_Node_Class is
   begin
      return At_Clause_Node;
   end Get_Class;

   function Get_Class (Item : Object_Declaration)
      return Program_Node_Class is
   begin
      return Object_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Entry_Declaration)
      return Program_Node_Class is
   begin
      return Entry_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Enumeration_Representation_Clause)
      return Program_Node_Class is
   begin
      return Enumeration_Representation_Clause_Node;
   end Get_Class;

   function Get_Class (Item : Exception_Declaration)
      return Program_Node_Class is
   begin
      return Exception_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Attribute_Definition_Clause)
      return Program_Node_Class is
   begin
      return Attribute_Definition_Clause_Node;
   end Get_Class;

   function Get_Class (Item : Function_Declaration)
      return Program_Node_Class is
   begin
      return Function_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Function_Instantiation)
      return Program_Node_Class is
   begin
      return Function_Instantiation_Node;
   end Get_Class;

   function Get_Class (Item : Identifier_List)
      return Program_Node_Class is
   begin
      return Identifier_List_Node;
   end Get_Class;

   function Get_Class (Item : Package_Declaration)
      return Program_Node_Class is
   begin
      return Package_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Package_Instantiation)
      return Program_Node_Class is
   begin
      return Package_Instantiation_Node;
   end Get_Class;

   function Get_Class (Item : Parameter_Profile)
      return Program_Node_Class is
   begin
      return Parameter_Profile_Node;
   end Get_Class;

   function Get_Class (Item : Parameter_Specification)
      return Program_Node_Class is
   begin
      return Parameter_Specification_Node;
   end Get_Class;

   function Get_Class (Item : Procedure_Declaration)
      return Program_Node_Class is
   begin
      return Procedure_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Procedure_Instantiation)
      return Program_Node_Class is
   begin
      return Procedure_Instantiation_Node;
   end Get_Class;

   function Get_Class (Item : Record_Representation_Clause)
      return Program_Node_Class is
   begin
      return Record_Representation_Clause_Node;
   end Get_Class;

   function Get_Class (Item : Single_Protected_Declaration)
      return Program_Node_Class is
   begin
      return Single_Protected_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Single_Task_Declaration)
      return Program_Node_Class is
   begin
      return Single_Task_Declaration_Node;
   end Get_Class;

   function Get_Class (Item : Singleton_Parameter)
      return Program_Node_Class is
   begin
      return Accept_Statement_Node;
   end Get_Class;

   function Get_Class (Item : Variant_Part_Item)
      return Program_Node_Class is
   begin
      return Variant_Part_Item_Node;
   end Get_Class;

   function Get_Class (Item : Variant_Part)
      return Program_Node_Class is
   begin
      return Variant_Part_Node;
   end Get_Class;

   function Get_Count (Item : Parameter_Profile) return Natural is
      Count : Natural := 0;
   begin
      for Index in Item.List'Range loop
         Count := Count + Item.List (Index).Parameters_Count;
      end loop;
      return Count;
   end Get_Count;

   function Get_Item
            (  Context : Identifier_List;
               Index   : Positive
            )  return Declaration_Ptr is
   begin
      return Context.List (Index)'Unchecked_Access;
   end Get_Item;

   function Get_Item
            (  Context : Singleton_Parameter;
               Index   : Positive
            )  return Declaration_Ptr is
   begin
      if Index /= 1 then
         raise Constraint_Error;
      else
         return Context'Unchecked_Access;
      end if;
   end Get_Item;

   function Get_Item
            (  Context : Parameter_Profile;
               Index   : Positive
            )  return Declaration_Ptr is
   begin
      return Context.List (Index).all'Unchecked_Access;
   end Get_Item;

   function Get_Items_Number (Item : Identifier_List) return Natural is
   begin
      return Item.Parameters_Count;
   end Get_Items_Number;

   function Get_Items_Number (Item : Parameter_Profile)
      return Natural is
   begin
      return Item.Parameters_Count;
   end Get_Items_Number;

   function Get_Items_Number (Item : Singleton_Parameter)
      return Natural is
   begin
      return 1;
   end Get_Items_Number;

   function Image
            (  Item   : Interface_Type;
               Suffix : String := ""
            )  return String is
   begin
      case Item is
         when Any_Interface =>
            return "";
         when Limited_Interface =>
            return "limited" & Suffix;
         when Synchronized_Interface =>
            return "synchronized" & Suffix;
         when Protected_Interface =>
            return "protected" & Suffix;
         when Task_Interface =>
            return "task" & Suffix;
      end case;
   end Image;

   function Image (Mode : Mode_Type) return String is
   begin
      case Mode is
         when In_Mode =>
            return "in";
         when Inout_Mode =>
            return "in out";
         when Out_Mode =>
            return "out";
         when Access_To_All =>
            return "access all";
         when Access_To_Variable =>
            return "access";
         when Access_To_Constant =>
            return "access constant";
         when Access_To_Procedure =>
            return "access procedure";
         when Access_To_Protected_Procedure =>
            return "access protected procedure";
         when Access_To_Function =>
            return "access function";
         when Access_To_Protected_Function =>
            return "access protected function";
         when Array_Mode =>
            return "array";
         when Constant_Mode | Object_Mode =>
            return "";
      end case;
   end Image;

   procedure Put_Instantiation
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Abstract_Instantiation'Class
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, " is new ");
      Put (Destination, Index, Item.Target);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put_Instantiation;

   procedure Put_Prefix
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Subprogram_Specification'Class
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Generic_Unit then
         if Item.Profile /= null and then
            Is_Library_Unit (Item.Profile.Parent.Context.Parent)
         then
            Put
            (  Destination => Destination,
               Pointer     => Index,
               Item        => Item.Profile.Parent.Context.Parent
            );
         end if;
         Put (Destination, Index, "generic ");
         if Item.Profile = null then
            Put (Destination, Index, Item.Parent);
         else
            Put (Destination, Index, Item.Profile.Parent);
         end if;
      else
         if Item.Profile /= null and then
            Is_Library_Unit (Item.Profile.Parent)
         then
            Put (Destination, Index, Item.Profile.Parent);
         end if;
      end if;
      if Item.Private_Unit then
         Put (Destination, Index, "private ");
      end if;
      Pointer := Index;
   end Put_Prefix;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Anonymous_Access_Definition
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Not_Null then
         Put (Destination, Index, "not null ");
      end if;
      Put (Destination, Index, Image (Item.Mode));
      case Item.Mode is
         when Access_To_All..Access_To_Variable =>
            Put (Destination, Index, " ");
            Put (Destination, Index, Item.Object);
         when Access_To_Procedure | Access_To_Protected_Procedure =>
            Put (Destination, Index, Item.Profile);
         when Access_To_Function | Access_To_Protected_Function =>
            Put (Destination, Index, Item.Profile);
            Put (Destination, Index, " return ");
            Put (Destination, Index, Item.Result.all);
      end case;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Array_Type_Specification
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "array ");
      Put (Destination, Index, Item.Indices);
      Put (Destination, Index, " of ");
      if Item.Aliased_Component then
         Put (Destination, Index, "aliased ");
      end if;
      case Item.Mode is
         when Access_Mode =>
            Put (Destination, Index, Item.Access_Component);
         when Object_Mode =>
            Put (Destination, Index, Item.Object_Component);
      end case;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : At_Clause
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "for ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " use at ");
      Put (Destination, Index, Item.Address);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Component_Clause
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " at ");
      Put (Destination, Index, Item.Position);
      Put (Destination, Index, " range ");
      Put (Destination, Index, Item.Bit_Range);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Object_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Item.Names, "", ", ", " :");
      if Item.Aliased_Object then
         Put (Destination, Index, " aliased");
      end if;
      if Item.Immutable or else
         Item.Definition.Mode = Constant_Mode
      then
         Put (Destination, Index, " constant");
      end if;
      if Item.Definition.Mode /= Constant_Mode then
         Put (Destination, Index, " ");
         Put (Destination, Index, Item.Definition.all);
      end if;
      Put (Destination, Index, " := ", Item.Initial, "");
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Entry_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "entry ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " (", Item.Index, ")");
      if Item.Profile /= null then
         Put (Destination, Index, Item.Profile.all);
      end if;
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Enumeration_Representation_Clause
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "for ");
      Put (Destination, Index, Item.Name);
      Put
      (  Destination => Destination,
         Pointer     => Index,
         List        => Item.Enumeration,
         Prefix      => " use (",
         Delimiter   => ", ",
         Ligature    => " => ",
         Suffix      => ");"
      );
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Exception_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Item.Names, "", ", ", " : exception");
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Attribute_Definition_Clause
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "for ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, "'");
      Put (Destination, Index, Item.Attribute);
      Put (Destination, Index, " use ");
      Put (Destination, Index, Item.Value);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Function_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put_Prefix (Destination, Index, Item);
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "function ");
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, Item.Profile);
      Put (Destination, Index, " return ");
      Put (Destination, Index, Item.Result.all);
      if Item.Abstract_Subprogram then
         Put (Destination, Index, " is abstract");
      end if;
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Function_Instantiation
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "function ");
      Put_Instantiation (Destination, Index, Item);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Identifier_List
             )  is
   begin
      Put (Destination, Pointer, Item.List);
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Package_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Generic_Unit then
         if Is_Library_Unit (Item.Public_Part.Parent.Context.Parent)
         then
            Put
            (  Destination => Destination,
               Pointer     => Index,
               Item        => Item.Public_Part.Parent.Context.Parent
            );
         end if;
         Put (Destination, Index, "generic ");
         Put (Destination, Index, Item.Public_Part.Parent);
      else
         if Is_Library_Unit (Item.Public_Part.Parent) then
            Put (Destination, Index, Item.Public_Part.Parent);
         end if;
      end if;
      if Item.Private_Unit then
         Put (Destination, Index, "private ");
      end if;
      Put (Destination, Index, "package ");
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Public_Part.all);
      if Item.Private_Part /= null then
         Put (Destination, Index, "private ");
         Put (Destination, Index, Item.Private_Part.all);
      end if;
      Put (Destination, Index, "end ");
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Singleton_Parameter_Array
             )  is
      Index : Integer := Pointer;
   begin
      for Item in List'Range loop
         if Item > List'First then
            Put (Destination, Index, ", ");
         end if;
         Put (Destination, Index, List (Item));
      end loop;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Object_Specification
             )  is
      Index : Integer := Pointer;
   begin
      case Item.Mode is
         when Object_Mode =>
            Put (Destination, Index, Item.Variable);
         when In_Mode =>
            if Item.Not_Null then
               Put (Destination, Index, "not null ");
            end if;
            Put (Destination, Index, Item.Result);
         when Out_Mode =>
            Put (Destination, Index, "out ");
            if Item.Not_Null then
               Put (Destination, Index, "not null ");
            end if;
            Put (Destination, Index, Item.Result);
         when Inout_Mode =>
            Put (Destination, Index, "in out ");
            if Item.Not_Null then
               Put (Destination, Index, "not null ");
            end if;
            Put (Destination, Index, Item.Result);
         when Access_To_All..Access_To_Protected_Function =>
            Put (Destination, Index, Item.Pointer);
         when Array_Mode =>
            Put (Destination, Index, Item.Array_Object.all);
         when Constant_Mode =>
            null;
      end case;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Parameter_Profile
             )  is
   begin
      if Item.Parameters_Count = 0 then
         Put (Destination, Pointer, " (<>)");
      else
         Put (Destination, Pointer, Item.List, " ");
      end if;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Parameter_Profile_Ptr
             )  is
   begin
      if Item /= null then
         Put (Destination, Pointer, Item.all);
      end if;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Parameter_Specification
             )  is
      Index : Integer := Pointer;

      procedure Null_Exclusion is
      begin
         if Item.Not_Null then
            Put (Destination, Index, "not null ");
         end if;
      end Null_Exclusion;
   begin
      Put
      (  Destination => Destination,
         Pointer     => Index,
         List        => Item.Parameters,
         Prefix      => "",
         Delimiter   => ", ",
         Suffix      => " : "
      );
      if Item.Aliased_Parameter then
         Put (Destination, Index, "aliased ");
      end if;
      case Item.Mode is
         when In_Mode =>
            Null_Exclusion;
            Put (Destination, Index, Item.Value);
            Put (Destination, Index, " := ", Item.Default, "");
         when Inout_Mode | Out_Mode =>
            Put (Destination, Index, Image (Item.Mode));
            Null_Exclusion;
            Put (Destination, Index, " ");
            Put (Destination, Index, Item.Value);
            Put (Destination, Index, " := ", Item.Default, "");
         when Access_To_All..Access_To_Protected_Function =>
            Put (Destination, Index, Item.Pointer);
            Put (Destination, Index, " := ", Item.Default, "");
      end case;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Parameter_Specification_Ptr_Array;
                Prefix      : String := ""
             )  is
      Index : Integer := Pointer;
   begin
      if List'Length > 0 then
         Put (Destination, Index, Prefix);
         Put (Destination, Index, "(");
         for Item in List'Range loop
            if Item > List'First then
               Put (Destination, Index, "; ");
            end if;
            Put (Destination, Index, List (Item).all);
         end loop;
         Put (Destination, Index, ")");
         Pointer := Index;
      end if;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Package_Instantiation
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "package ");
      Put_Instantiation (Destination, Index, Item);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Parameter_Type
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Present then
         Put (Destination, Index, " : ");
         if Item.Aliased_Parameter then
            Put (Destination, Index, "aliased ");
         end if;
         if Item.Constant_Parameter then
            Put (Destination, Index, "constant ");
         end if;
         case Item.Mode is
            when Access_Mode =>
               Put (Destination, Index, Item.Access_Parameter);
            when Object_Mode =>
               Put (Destination, Index, Item.Object_Parameter);
         end case;
      end if;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Procedure_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put_Prefix (Destination, Index, Item);
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "procedure ");
      Put (Destination, Index, Item.Full_Name);
      Put (Destination, Index, Item.Profile);
      if Item.Abstract_Subprogram then
         Put (Destination, Index, " is abstract");
      end if;
      Put (Destination, Index, Item.Aspects);
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Procedure_Instantiation
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Image (Item.Overrides, " "));
      Put (Destination, Index, "procedure ");
      Put_Instantiation (Destination, Index, Item);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Record_Representation_Clause
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "for ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, " use record ");
      if Item.Modulus.Present then
         Put (Destination, Index, "at mod ");
         Put (Destination, Index, Item.Modulus.Item);
         Put (Destination, Index, "; ");
      end if;
      for Component in Item.Components'Range loop
         Put (Destination, Index, Item.Components (Component));
         Put (Destination, Index, "; ");
      end loop;
      Put (Destination, Index, "end record;");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Single_Protected_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "protected ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Aspects);
      if Item.Public_Part /= null or else Item.Private_Part /= null then
         Put (Destination, Index, " is ");
         Put
         (  Destination => Destination,
            Pointer     => Index,
            List        => Item.Interfaces,
            Prefix      => "new ",
            Delimiter   => " and ",
            Suffix      => " with "
        );
         Put (Destination, Index, Item.Public_Part.all);
         if Item.Private_Part /= null then
            Put (Destination, Index, "private ");
            Put (Destination, Index, Item.Private_Part.all);
         end if;
         Put (Destination, Index, "end ");
         Put (Destination, Index, Item.Name);
      end if;
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Single_Task_Declaration
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "task ");
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Aspects);
      if Item.Public_Part /= null or else Item.Private_Part /= null then
         Put (Destination, Index, " is ");
         Put
         (  Destination,
            Index,
            Item.Interfaces,
            "new ",
            " and ",
            " with "
         );
         Put (Destination, Index, Item.Public_Part.all);
         if Item.Private_Part /= null then
            Put (Destination, Index, "private ");
            Put (Destination, Index, Item.Private_Part.all);
         end if;
         Put (Destination, Index, "end ");
         Put (Destination, Index, Item.Name);
      end if;
      Put (Destination, Index, ";");
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Singleton_Parameter
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, Item.Name);
      Put (Destination, Index, Item.Type_Of);
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Variant_Part_Item
             )  is
      Index : Integer := Pointer;
   begin
      if Item.Choices_Count = 0 then
         Put (Destination, Index, "when others => ");
         Put (Destination, Index, Item.Components.all);
      else
         Put
         (  Destination => Destination,
            Pointer     => Index,
            List        => Item.Choices,
            Prefix      => "when ",
            Delimiter   => " | ",
            Suffix      => " => "
          );
          Put (Destination, Index, Item.Components.all);
      end if;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                List        : Variant_Part_Item_Ptr_Array
             )  is
      Index : Integer := Pointer;
   begin
      for Item in List'Range loop
         Put (Destination, Index, List (Item).all);
      end loop;
      Pointer := Index;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : Variant_Part
             )  is
      Index : Integer := Pointer;
   begin
      Put (Destination, Index, "case ");
      Put (Destination, Index, Item.Discriminant);
      Put (Destination, Index, " is ");
      Put (Destination, Index, Item.Alternatives);
      Put (Destination, Index, "end case;");
      Pointer := Index;
   end Put;

   procedure Set_Parent
             (  Profile : in out Parameter_Profile;
                Parent  : Context_Location
             )  is
   begin
      Profile.Parent := Parent;
      for Index in Profile.List'Range loop
         declare
            This : Parameter_Specification renames
                   Profile.List (Index).all;
         begin
            if This.Mode in Access_To_Subprogram_Mode then
               Set_Parent
               (  Ref (This.Pointer.Profile).all,
                  (Profile'Unchecked_Access, Index - 1)
               );
            end if;
         end;
      end loop;
   end Set_Parent;

end Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;
