--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Sequence.Get_For_Loop                Spring, 2026       --
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
   function Get_For_Loop
            (  Parent        : Context_Location;
               Chunk         : Chunk_Specification_Ref := null;
               Aspects_Count : Natural                 := 0
            )  return Node_Ptr is
   Iterator_Filter  : Tokens.Argument_Token;
   Profile          : Parameter_Profile_Ref;
   Identifiers      : Identifier_List_Ref;
   Iteration        : Iterator_Mode;
   Iterator_Call    : Tokens.Argument_Token;
   Iterator_Subtype : Subtype_Indication;
   Parameter        : Parameter_Type;
   Parameter_Name   : Tokens.Argument_Token;
   In_Reverse       : Boolean := False;
   Has_Filter       : Boolean;
   Enclosing        : Context_Location := Parent;
begin
   if Get ("(", False) then
      declare
         Open_At : Location;
         Name    : Tokens.Argument_Token;
      begin
         Open_At := Link (Code);
         Get_Simple_Name (Context, Code, True, Name);
         if not Get (":=", False) and then Get (":", False) then
            Iteration := Formal_Part_Mode;
            Profile := Get_Procedure_Profile
                       (  Context   => Context'Access,
                          Code      => Code'Access,
                          File      => File,
                          Parent    => Enclosing,
                          Unknown   => False,
                          No_Access => False,
                          Profile   => True,
                          Start     => (  Part => Parameter_Colon,
                                          Name => Name
                       )               );
            Enclosing := Ref (Profile);
         else
            declare
               Parameters_Count : Integer := 1;
            begin
               Iteration := List_Mode;
               Push (Context, Name);
               if Get (",", False) then
                  declare
                     Count : Positive;
                  begin
                     Get_Names_List (Context, Code, Count);
                     Parameters_Count := Parameters_Count + Count;
                  end;
               end if;
               declare
                  use Tokens.Arguments;
                  type Arena_Ptr is access Identifier_List;
                  for Arena_Ptr'Storage_Pool use Context.Pool.all;
                  Ptr  : constant Arena_Ptr :=
                              new Identifier_List (Parameters_Count);
                  This : Identifier_List renames Ptr.all;
                  Item : Frame (1..1);
               begin
                  This.Parent   := Enclosing;
                  This.Location := Name.Location & Link (Code);
                  Identifiers   := This'Unchecked_Access;
                  Enclosing.Context := This'Unchecked_Access;
                  for Index in reverse This.List'Range loop
                     Pop (Context, Item);
                     This.List (Index).Name.Term := Item (1);
                  end loop;
                  Enclosing := Ref (This'Unchecked_Access);
               end;
            end;
            if not Get (")", False) then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "')' closing '(' at " &
                  Image (Open_At)       &
                  " is expected at "    &
                  Image (Link (Code))
               );
            end if;
         end if;
         if not Get ("of", False) then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'of' is expected after parameter specification at " &
               Image (Link (Code))
            );
         end if;
         Lexers.Parse (Context, Code, Iterator_Call);
      end;
   else
      Get_Simple_Name (Context, Code, True, Parameter_Name);
      if not Get (":=", False) and then Get (":", False) then
         Parameter := Get_Parameter_Type
                      (  Context => Context'Access,
                         Code    => Code'Access,
                         File    => File,
                         Parent  => Parent
                      );
      end if;
      if Get ("in") then
         Iteration := In_Interation_Mode;
      elsif Get ("of") then
         Iteration := Of_Interation_Mode;
      else
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'in' or 'of' is expected at " & Image (Link (Code))
         );
      end if;
      In_Reverse := Get ("reverse");
      if Iteration = In_Interation_Mode then
         Get_Range
         (  Context     => Context,
            Code        => Code,
            Constrained => True,
            Any_Name    => True,
            Argument    => Iterator_Subtype
         );
      else
         Lexers.Parse (Context, Code, Iterator_Subtype.Mark.Name);
      end if;
   end if;
   Has_Filter := Get ("when");
   if Has_Filter then
      Lexers.Parse (Context, Code, Iterator_Filter);
   end if;
   if not Get ("loop") then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'loop' is expected at " & Image (Link (Code))
      );
   end if;
   declare
      type Arena_Ptr is access For_Loop_Statement;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Ptr  : constant Arena_Ptr :=
                  new For_Loop_Statement
                      (  Labels_Count        => Labels_Count,
                         Named               => Has_Identifier,
                         Mode                => Iteration,
                         Has_Iterator_Filter => Has_Filter,
                         Aspects_Count       => Aspects_Count
                      );
      Parent   : Context_Location := Enclosing;
      Sequence : Unhandled_Statement_Sequence_Ref;
      This     : For_Loop_Statement renames Ptr.all;

      procedure Set_Chunk (Where : Location) is
      begin
         if Chunk /= null then
            Chunk.Outer := This'Unchecked_Access;
            This.Chunk := Chunk.all'Unchecked_Access;
            if Chunk.Mode = Chunk_Parameter then
               Chunk.Name.Scope := Where;
               Chunk.Name.File  := File;
            end if;
         end if;
      end Set_Chunk;
   begin
      if Chunk /= null and then Chunk.Mode = Chunk_Parameter then
         Parent := (  Chunk.Name'Unchecked_Access,
                      Get_Items_Number (Chunk.Name)
                   );
      end if;
      if This.Named then
         This.Name.Item := Identifier;
      end if;
      if This.Has_Iterator_Filter then
         This.Iterator_Filter.Item := Iterator_Filter;
      end if;
      if Profile /= null then
         Profile.Outer := This'Unchecked_Access;
         Profile.Scope := Link (Code);
         Profile.File  := File;
      end if;
      Pop (Context, This.Aspects);
      case This.Mode is
         when In_Interation_Mode | Of_Interation_Mode =>
            This.In_Reverse := In_Reverse;
            This.Iterator_Subtype := Iterator_Subtype;
            This.Parameter.Type_Of := Parameter;
            Set
            (  Context,
               Parameter_Name,
               Parent,
               File,
               This,
               This.Parameter.Name'Access
            );
            This.Parameter.Location := Parameter_Name.Location;
            This.Parameter.Parent   := Parent;
            Set_Chunk (This.Parameter.Location);
            Sequence :=
               Get_Loop_Body
               (  Parent    => Ref (This.Parameter'Unchecked_Access),
                  Statement => This'Unchecked_Access,
                  Chunk     => Chunk,
                  For_Loop  => To_Context (This.Parameter'Access)
               );
         when Formal_Part_Mode =>
            This.Iterator_Call := Iterator_Call;
            if Profile /= null then
               This.Formal_Part := Profile.all'Unchecked_Access;
               Set_Chunk (This.Formal_Part.Location);
               Sequence :=
                  Get_Loop_Body
                  (  Parent    => Parent,
                     Statement => This'Unchecked_Access,
                     Chunk     => Chunk,
                     For_Loop  => Profile.all'Unchecked_Access
                  );
            else
               Set_Chunk (Link (Code));
               Sequence :=
                  Get_Loop_Body
                  (  Parent    => Parent,
                     Statement => This'Unchecked_Access
                  );
            end if;
         when List_Mode =>
            Identifiers.Outer  := This'Unchecked_Access;
            This.Iterator      := Identifiers.all'Unchecked_Access;
            This.Iterator_Call := Iterator_Call;
            Set_Chunk (This.Iterator.Location);
            Sequence :=
               Get_Loop_Body
               (  Parent    => Parent,
                  Statement => This'Unchecked_Access,
                  Chunk     => Chunk,
                  For_Loop  => Identifiers.all'Unchecked_Access
               );
             declare
                List   : Identifier_List renames Identifiers.all;
                Parent : Context_Location := (List'Unchecked_Access, 0);
             begin
                for Index in reverse List.List'Range loop
                   declare
                      Parameter : Singleton_Parameter renames
                                  List.List (Index);
                      Item  : Tokens.Argument_Token;
                      Scope : constant Location := Sequence.Location;
                   begin
                      Parent.After := Index - 1;
                      Item := Parameter.Name.Term;
                      Set
                      (  Context,
                         Item,
                         Parent,
                         File,
                         List,
                         Parameter.Name'Access
                      );
                      Parameter.Parent   := Parent;
                      Parameter.Scope    := Scope;
                      Parameter.File     := File;
                      Parameter.Location := Parameter.Name.Term.
                                            Location;
                   end;
                end loop;
             end;
      end case;
      Sequence.Outer := This'Unchecked_Access;
      This.Sequence := Sequence.all'Unchecked_Access;
      Pop (Context, Parent, File, This, This.Labels);
      return This'Unchecked_Access;
   end;
end Get_For_Loop;
