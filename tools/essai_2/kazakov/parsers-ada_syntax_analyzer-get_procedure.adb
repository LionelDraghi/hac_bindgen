--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Procedure                            Spring, 2026       --
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

with Parsers.Ada_Syntax_Analyzer.Declarations.Renamings;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Renamings;

with Parsers.Ada_Syntax_Analyzer.Declarations.Stubs;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Stubs;

separate (Parsers.Ada_Syntax_Analyzer)
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
             )  is
   Library_Unit : constant Boolean := Separated.Separate_Body or else
                                      Is_Library_Unit (Parent);
   Aspect_At    : Location;

   function Get (Text : String; Delimited : Boolean := True)
      return Boolean is
      pragma Inline (Get);
      Got_It : Boolean;
   begin
      Get_Blank (Context, Code);
      Get_Delimited (Code, Text, Delimited, Got_It);
      return Got_It;
   end Get;

   function Get_Aspects_Count return Natural is
      Count  : Natural := 0;
   begin
      if Get ("with") then
         Aspect_At := Link (Code);
         Get_Blank (Context, Code);
         Get_Aspect (Context, Code, Count);
      end if;
      return Count;
   end Get_Aspects_Count;

   Aspects_Count : Natural := 0;
   Name          : Tokens.Argument_Token;
   Profile       : Parameter_Profile_Ref;
   Keyword       : Reserved_Word;
begin
   Result.Location := Before (Code);
   if Library_Unit then
      Get_Expanded_Name (Context, Code, True, Name);
   else
      Get_Simple_Name (Context, Code, True, Name);
   end if;
   Get_Blank (Context, Code);
   Profile := Get_Procedure_Profile
              (  Context   => Context'Access,
                 Code      => Code'Access,
                 File      => File,
                 Parent    => Parent,
                 No_Access => False,
                 Unknown   => False,
                 Profile   => True
              );
   Aspects_Count := Get_Aspects_Count;
   if Get ("is") then
      if Profile /= null then
         Profile.Scope := Before (Code);
         Profile.File  := File;
      end if;
      if Profile = null and then Get ("new") then
         if Aspects_Count > 0 then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Procedure instantiation aspect specified at " &
               Image (Aspect_At)                              &
               " must appear after 'new' at "                 &
               Image (Link (Code))
            );
         elsif Generic_Unit then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Generic procedure instantiation cannot have a formal " &
               "generic part as found at "                             &
               Image (Link (Code))
            );
         end if;
         declare
            Target : Tokens.Argument_Token;
         begin
            Lexers.Parse (Context, Code, Target);
            declare
               type Arena_Ptr is access Procedure_Instantiation;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr  : constant Arena_Ptr :=
                           new Procedure_Instantiation
                               (  Overrides,
                                  Get_Aspects_Count
                               );
               This : Procedure_Instantiation renames Ptr.all;
            begin
               Pop (Context, This.Aspects);
               Set
               (  Context,
                  Name,
                  Parent,
                  File,
                  This,
                  This.Name'Access
               );
               This.Full_Name  := Name;
               This.Target     := Target;
               Get_Semicolon (Context, Code);
               Result.Value    := This'Unchecked_Access;
               Result.Location := Result.Location & Link (Code);
               This.Location   := Result.Location;
            end;
         end;
      elsif Get ("separate") then
         if Library_Unit then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "A procedure body is expected at " & Image (Link (Code))
            );
         elsif Generic_Unit then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Generic procedure stub cannot have a formal " &
               "generic part as found at "                    &
               Image (Link (Code))
            );
         end if;
         Check_Body_Stub (Code, Parent, "Procedure body");
         if Aspects_Count > 0 then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Procedure body aspect specified at " &
               Image (Aspect_At)                     &
               " must appear after 'separate' at "   &
               Image (Link (Code))
            );
         end if;
         declare
            type Arena_Ptr is access Procedure_Stub;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Procedure_Stub
                            (  Aspects_Count => Get_Aspects_Count,
                               Overrides     => Overrides
                            );
            This : Procedure_Stub renames Ptr.all;
         begin
            Set (Context, Name, Parent, File, This, This.Name'Access);
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
      elsif Get ("(", False) then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Procedure body cannot be an expression as found at " &
            Image (Link (Code))
         );
      elsif Get ("null") then
         if Library_Unit then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "The body in a compilation unit cannot cannot be " &
               "null as found at "                                &
               Image (Link (Code))
            );
         elsif Aspects_Count > 0 then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Null procedure aspect specified at " &
               Image (Aspect_At)                     &
               " must appear after 'null' at "       &
               Image (Link (Code))
            );
         end if;
         declare
            type Arena_Ptr is access Null_Procedure;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Null_Procedure
                            (  Private_Unit        => Private_Unit,
                               Generic_Unit        => Generic_Unit,
                               Overrides           => Overrides,
                               Abstract_Subprogram => False,
                               Aspects_Count       => Get_Aspects_Count
                            );
            This : Null_Procedure renames Ptr.all;
         begin
            Set (Context, Name, Parent, File, This, This.Name'Access);
            if Profile /= null then
               Profile.Outer := This'Unchecked_Access;
               This.Profile  := Profile.all'Unchecked_Access;
            end if;
            This.Full_Name := Name;
            Pop (Context, This.Aspects);
            Get_Semicolon (Context, Code);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Result.Location & Link (Code);
            This.Location   := Result.Location;
         end;
      elsif Get ("abstract") then
         if Library_Unit then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "A body of the procedure is expected at " &
               Image (Link (Code))
            );
         elsif Aspects_Count > 0 then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Abstract procedure aspect specified at " &
               Image (Aspect_At)                         &
               " must appear after 'abstract' at "       &
               Image (Link (Code))
            );
         elsif Generic_Unit then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Generic procedure cannot be abstract as found at " &
               Image (Link (Code))
            );
         end if;
         declare
            type Arena_Ptr is access Procedure_Declaration;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Procedure_Declaration
                            (  Private_Unit        => Private_Unit,
                               Generic_Unit        => Generic_Unit,
                               Abstract_Subprogram => True,
                               Overrides           => Overrides,
                               Aspects_Count       => Get_Aspects_Count
                            );
            This : Procedure_Declaration renames Ptr.all;
         begin
            Set (Context, Name, Parent, File, This, This.Name'Access);
            This.Full_Name := Name;
            if Profile /= null then
               Profile.Outer := This'Unchecked_Access;
               This.Profile  := Profile.all'Unchecked_Access;
            end if;
            Pop (Context, This.Aspects);
            Get_Semicolon (Context, Code);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Result.Location & Link (Code);
            This.Location   := Result.Location;
            This.Parent     := Parent;
         end;
      else
         if Generic_Unit then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Generic procedure body cannot have a formal " &
               "generic part as found at "                    &
               Image (Link (Code))
            );
         end if;
         case Get_Kind_Of (Parent) is
            when Code_Block_Context     |
                 Protected_Body_Context |
                 Library_Unit_Context   =>
               null;
            when others =>
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Procedure body is not allowed in the " &
                  Image (Get_Kind_Of (Parent))            &
                  " at "                                  &
                  Image (Link (Code))
               );
         end case;
         declare
            Declarations : Declaration_Context_Ref;
            Sequence     : Statement_Sequence_Ref;
            Private_Unit : Boolean;
            function Enclosing return Context_Location is
            begin
               if Profile = null then
                  return Parent;
               else
                  return Ref (Profile);
               end if;
            end Enclosing;
         begin
            Get_Context
            (  Context      => Context,
               Code         => Code,
               File         => File,
               Kind_Of      => Code_Block_Context,
               Parent       => Enclosing,
               Private_Unit => Private_Unit,
               Keyword      => Keyword,
               Result       => Declarations
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
               Parent    => Ref (Declarations),
               Handled   => Handled_Sequence or Procedure_Sequence,
               Enclosing => null,
               Keyword   => Keyword,
               Result    => Sequence
            );
            declare
               type Arena_Ptr is access Procedure_Body;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr  : constant Arena_Ptr :=
                      new Procedure_Body
                          (  Declarations  => Declarations,
                             Separate_Body => Separated.Separate_Body,
                             Overrides     => Overrides,
                             Aspects_Count => Aspects_Count,
                             Code          => Handled_Statement_Sequence
                                              (  Sequence.all
                                              ) 'Access
                          );
               This : Procedure_Body renames Ptr.all;
               Ends : constant Location := Before (Code);
            begin
               Sequence.Outer := This'Unchecked_Access;
               Set
               (  Context,
                  Name,
                  Parent,
                  File,
                  This,
                  This.Name'Access
               );
               if Profile /= null then
                  Profile.Outer := This'Unchecked_Access;
                  Add (Context, Profile.all, Ends, File);
                  This.Profile := Profile.all'Unchecked_Access;
               end if;
               Add (Context, Declarations.all, Ends, File);
               This.Full_Name := Name;
               This.Parent    := Separated;
               Get_Blank (Context, Code);
               if not Has_Semicolon (Code) then
                  Check (Context, Code, Name);
               end if;
               Pop (Context, This.Aspects);
               Get_Semicolon (Context, Code);
               Result.Value    := This'Unchecked_Access;
               Result.Location := Result.Location & Link (Code);
               This.Location   := Result.Location;
            end;
         end;
      end if;
   elsif Get ("renames") then
      if Separated.Separate_Body then
          Raise_Exception
          (  Parsers.Syntax_Error'Identity,
             "A procedure separate body is expected at " &
             Image (Link (Code))
          );
      elsif Aspects_Count > 0 then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Procedure renaming aspect specified at " &
            Image (Aspect_At)                         &
            " must appear after 'renames' at "        &
            Image (Link (Code))
         );
      end if;
      declare
         Target : Tokens.Argument_Token;
         procedure Get_Renaming (Parent : Context_Location) is
            type Arena_Ptr is access Procedure_Renaming;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Procedure_Renaming
                            (  Private_Unit     => Private_Unit,
                               Generic_Unit     => Generic_Unit,
                               Overrides        => Overrides,
                               Aspects_Count    => Get_Aspects_Count
                            );
            This : Procedure_Renaming renames Ptr.all;
         begin
            Set (Context, Name, Parent, File, This, This.Name'Access);
            This.Full_Name := Name;
            This.Target    := Target;
            This.Parent    := Parent;
            if Profile /= null then
               Profile.Outer := This'Unchecked_Access;
               This.Profile := Profile.all'Unchecked_Access;
            end if;
            Pop (Context, This.Aspects);
            Get_Semicolon (Context, Code);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Result.Location & Link (Code);
            This.Location   := Result.Location;
         end Get_Renaming;
      begin
         Lexers.Parse (Context, Code, Target);
         Check_Name (Target);
         if Generic_Unit then
            if Get_Items_Number (Parent.Context.all) > 0 then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Generic procedure renaming cannot have a formal " &
                  "generic part as found at "                        &
                  Image (Parent.Context.Location)
               );
            end if;
            Get_Renaming (Parent.Context.Parent);
         else
            Get_Renaming (Parent);
         end if;
      end;
   else
      declare
         type Arena_Ptr is access Procedure_Declaration;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Ptr  : constant Arena_Ptr :=
                     new Procedure_Declaration
                         (  Private_Unit        => Private_Unit,
                            Generic_Unit        => Generic_Unit,
                            Abstract_Subprogram => False,
                            Overrides           => Overrides,
                            Aspects_Count       => Aspects_Count
                         );
         This : Procedure_Declaration renames Ptr.all;
      begin
         Set (Context, Name, Parent, File, This, This.Name'Access);
         This.Full_Name := Name;
         if Profile /= null then
            Profile.Outer := This'Unchecked_Access;
            This.Profile  := Profile.all'Unchecked_Access;
         end if;
         Pop (Context, This.Aspects);
         Get_Semicolon (Context, Code);
         Result.Value    := This'Unchecked_Access;
         Result.Location := Result.Location & Link (Code);
         This.Location   := Result.Location;
         This.Parent     := Parent;
      end;
   end if;
end Get_Procedure;
