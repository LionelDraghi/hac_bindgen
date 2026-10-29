--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Sequence.Get_Accept                  Spring, 2026       --
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
   function Get_Accept return Accept_Statement_Ptr is
   Name      : Tokens.Argument_Token;
   Profile   : Parameter_Profile_Ref;
   Family_Of : Boolean := False;
   Family    : Tokens.Argument_Token;
   Open_At   : Location;
   Keyword   : Reserved_Word;
   Sequence  : Statement_Sequence_Ref;
   Enclosing : Context_Location := Parent;
begin
   if 0 = (Handled and Task_Sequence) then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "The accept statement's innermost enclosing body " &
         "is not a task body at "                           &
         Image (Link (Code))
      );
   end if;
   Get_Simple_Name (Context, Code, True, Name);
   if Get ("(", False) then
      Open_At := Link (Code);
      Lexers.Parse (Context, Code, Family);
      if not Get (":=", False) and then Get (":", False) then
         Check_Identifier (Family);
         Profile := Get_Procedure_Profile
                    (  Context   => Context'Access,
                       Code      => Code'Access,
                       File      => File,
                       Parent    => Enclosing,
                       Unknown   => False,
                       No_Access => True,
                       Profile   => True,
                       Start     => (  Part => Parameter_Colon,
                                       Name => Family
                    )               );
      elsif Get (",", False) then
         Check_Identifier (Family);
         Profile := Get_Procedure_Profile
                    (  Context   => Context'Access,
                       Code      => Code'Access,
                       File      => File,
                       Parent    => Enclosing,
                       Unknown   => False,
                       No_Access => False,
                       Profile   => True,
                       Start     => (  Part => Parameter_Comma,
                                       Name => Family
                    )               );
      else
         if not Get (")", False) then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "')' closing '(' at " &
               Image (Open_At)       &
               " is expected at "    &
               Image (Link (Code))
            );
         end if;
         Family_Of := True;
         Profile := Get_Procedure_Profile
                    (  Context   => Context'Access,
                       Code      => Code'Access,
                       File      => File,
                       Parent    => Enclosing,
                       No_Access => False,
                       Unknown   => False,
                       Profile   => True
                    );
      end if;
   end if;
   if Profile /= null then
      Enclosing := Ref (Profile);
   end if;
   if Get ("do") then
      if Profile /= null then
         Profile.Scope := Before (Code);
         Profile.File  := File;
      end if;
      Get_Sequence
      (  Context   => Context,
         Code      => Code,
         File      => File,
         Parent    => Enclosing,
         Handled   => Handled or Handled_Sequence or Action_Sequence,
         Enclosing => null,
         Keyword   => Keyword,
         Result    => Sequence
      );
      if Keyword /= End_Word then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'end' is expected at " & Image (Link (Code))
         );
      end if;
      Get_Blank (Context, Code);
      if not Has_Semicolon (Code) then
         Check (Context, Code, Name);
      end if;
   end if;
   declare
      type Arena_Ptr is access Accept_Statement;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Ptr  : constant Arena_Ptr :=
                  new Accept_Statement
                      (  Labels_Count => Labels_Count,
                         Is_Family    => Family_Of
                      );
      This : Accept_Statement renames Ptr.all;
   begin
      if This.Is_Family then
         This.Index.Item := Family;
      end if;
      Set (Context, Name, Parent, File, This, This.Name'Access);
      if Profile /= null then
         Profile.Outer := This'Unchecked_Access;
         Add (Context, Profile.all, Before (Code), File);
         This.Profile := Profile.all'Unchecked_Access;
      end if;
      if Sequence /= null then
         Sequence.Outer := This'Unchecked_Access;
         This.Sequence :=
            Handled_Statement_Sequence (Sequence.all)'Access;
      end if;
      Pop (Context, Parent, File, This, This.Labels);
      return This'Unchecked_Access;
   end;
end Get_Accept;
