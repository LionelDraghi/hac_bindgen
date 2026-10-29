--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Context.Get_Entry                    Spring, 2026       --
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

with Parsers.Ada_Syntax_Analyzer.Bodies;
use  Parsers.Ada_Syntax_Analyzer.Bodies;

separate (Parsers.Ada_Syntax_Analyzer.Get_Context)
   function Get_Entry
            (  Overrides : Overriding_Indicator_Type
            )  return Tokens.Argument_Token is
   Parent        : Context_Location := Enclosing;
   Result        : Tokens.Argument_Token;
   Name          : Tokens.Argument_Token;
   Open_At       : Location;
   Profile       : Parameter_Profile_Ref;
   Aspects_Count : Natural := 0;
   Family_Of     : Boolean := False;
   Family        : Tokens.Argument_Token;
begin
   Result.Location := Before (Code);
   Get_Simple_Name (Context, Code, True, Name);
   if Get ("(", False) then
      Open_At := Link (Code);
      if Get ("for") then
         Lexers.Parse (Context, Code, Family);
         if not Get (")") then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "')' closing '(' at " &
               Image (Open_At)       &
               " is expected at "    &
               Image (Link (Code))
            );
         end if;
         if Family.Value.all not in Expression'Class then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Entry index specification is expected at " &
               Image (Family.Location)
            );
            declare
               This : Expression'Class renames
                      Expression'Class (Family.Value.all);
            begin
               if This.Operation /= Member then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'in' of entry index specification is " &
                     "expected at "                          &
                     Image (Family.Location)
                  );
               elsif This.Operands (This.Operands'First).Value.all
                     not in Identifier'Class then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Identifier of entry index specification is " &
                     "expected at "                                &
                     Image (Family.Location)
                  );
               end if;
            end;
         end if;
         Profile := Get_Procedure_Profile
                    (  Context   => Context'Access,
                       Code      => Code'Access,
                       File      => File,
                       Parent    => Enclosing,
                       Unknown   => False,
                       No_Access => True,
                       Profile   => True
                    );
         Family_Of := True;
      else
         Lexers.Parse (Context, Code, Family);
         if not Get (":=", False) and then Get (":", False) then
            Check_Identifier (Family);
            Profile := Get_Procedure_Profile
                       (  Context   => Context'Access,
                          Code      => Code'Access,
                          File      => File,
                          Parent    => Parent,
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
                          No_Access => True,
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
                  " is expected at " &
                  Image (Link (Code))
               );
            end if;
            Family_Of := True;
            Profile := Get_Procedure_Profile
                       (  Context   => Context'Access,
                          Code      => Code'Access,
                          File      => File,
                          Parent    => Enclosing,
                          Unknown   => False,
                          No_Access => True,
                          Profile   => True
                       );
         end if;
      end if;
   end if;
   if Profile /= null then
      Parent := Ref (Profile);
   end if;
   if Get ("with") then
      Get_Blank (Context, Code);
      Get_Aspect (Context, Code, Aspects_Count);
   end if;
   if Get ("when") then
      declare
         Entry_Context : Declaration_Context_Ref;
         Keyword       : Reserved_Word;
         Private_Unit  : Boolean;
         Barrier       : Tokens.Argument_Token;
         Sequence      : Statement_Sequence_Ref;
      begin
         Lexers.Parse (Context, Code, Barrier);
         if not Get ("is") then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'is' is expected at " & Image (Link (Code))
            );
         end if;
         if Profile /= null then
            Profile.Scope := Before (Code);
            Profile.File  := File;
         end if;
         Get_Context
         (  Context      => Context,
            Code         => Code,
            File         => File,
            Kind_Of      => Code_Block_Context,
            Parent       => Parent,
            Private_Unit => Private_Unit,
            Keyword      => Keyword,
            Result       => Entry_Context
         );
         if Keyword /= Begin_Word then
            Raise_Exception
            (  Syntax_Error'Identity,
               "'begin' is expected at " & Image (Link (Code))
            );
         end if;
         Get_Sequence
         (  Context   => Context,
            Code      => Code,
            File      => File,
            Parent    => Ref (Entry_Context),
            Handled   => Handled_Sequence or -- Exceptions
                         Action_Sequence  or -- requeue
                         Procedure_Sequence, -- return
            Enclosing => null,
            Keyword   => Keyword,
            Result    => Sequence
         );
         declare
            type Arena_Ptr is access Entry_Body;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                   new Entry_Body
                       (  Has_Index     => Family_Of,
                          Declarations  => Entry_Context,
                          Aspects_Count => Aspects_Count,
                          Overrides     => Overrides,
                          Code          => Handled_Statement_Sequence
                                           (  Sequence.all
                                           ) 'Access
                       );
            This : Entry_Body renames Ptr.all;
            Ends : constant Location := Before (Code);
         begin
            Sequence.Outer := This'Unchecked_Access;
            Set
            (  Context,
               Name,
               Enclosing,
               File,
               This,
               This.Name'Access
            );
            if Profile /= null then
               Profile.Outer := This'Unchecked_Access;
               This.Profile  := Profile.all'Unchecked_Access;
               Add (Context, Profile.all, Ends, File);
            end if;
            Add (Context, Entry_Context.all, Ends, File);
            This.Barrier := Barrier;
            if This.Index.Present then
               This.Index.Item := Family;
            end if;
            Pop (Context, This.Aspects);
            Get_Blank (Context, Code);
            if not Has_Semicolon (Code) then
               Check (Context, Code, Name);
            end if;
            Get_Semicolon (Context, Code);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Result.Location & Link (Code);
            This.Location   := Result.Location;
         end;
      end;
   else
      declare
         type Arena_Ptr is access Entry_Declaration;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Ptr  : constant Arena_Ptr :=
                     new Entry_Declaration
                         (  Is_Family     => Family_Of,
                            Overrides     => Overrides,
                            Aspects_Count => Aspects_Count
                         );
         This : Entry_Declaration renames Ptr.all;
      begin
         Set (Context, Name, Enclosing, File, This, This.Name'Access);
         if This.Is_Family then
            This.Index.Item := Family;
         end if;
         if Profile /= null then
            Profile.Outer := This'Unchecked_Access;
            This.Profile  := Profile.all'Unchecked_Access;
         end if;
         Pop (Context, This.Aspects);
         Get_Semicolon (Context, Code);
         Result.Value    := This'Unchecked_Access;
         Result.Location := Result.Location & Link (Code);
         This.Location   := Result.Location;
      end;
   end if;
   return Result;
end Get_Entry;
