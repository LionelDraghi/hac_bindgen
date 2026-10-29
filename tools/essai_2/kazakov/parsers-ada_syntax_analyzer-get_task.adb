--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Task                                 Spring, 2026       --
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

with Parsers.Ada_Syntax_Analyzer.Declarations.Stubs;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Stubs;

with Parsers.Ada_Syntax_Analyzer.Declarations.Types;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Types;

separate (Parsers.Ada_Syntax_Analyzer)
   procedure Get_Task
             (  Context   : in out Ada_Program;
                Code      : in out Source'Class;
                File      : Source_Description_Ptr;
                Parent    : Context_Location;
                Separated : Parent_Unit;
                Result    : out Tokens.Argument_Token
             )  is
   Aspects_At : Location;

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
         Aspects_At := Link (Code);
         Get_Blank (Context, Code);
         Get_Aspect (Context, Code, Count);
      end if;
      return Count;
   end Get_Aspects_Count;

   procedure Body_Expected is
   begin
      if Separated.Separate_Body then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Separate task body is expected at " & Image (Link (Code))
         );
      end if;
   end Body_Expected;

   Name          : Tokens.Argument_Token;
   Profile       : Parameter_Profile_Ref;
   Aspects_Count : Natural;
   Keyword       : Reserved_Word;

   function Enclosing return Context_Location is
   begin
      if Profile = null then
         return Parent;
      else
         return Ref (Profile);
      end if;
   end Enclosing;
begin
   Result.Location := Link (Code);
   if Get ("body") then
      if Is_Formal_Generic (Parent) then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Task body is not allowed as a formal generic " &
            "parameter  at "                                &
            Image (Link (Code))
         );
      end if;
      Get_Simple_Name (Context, Code, True, Name);
      Aspects_Count := Get_Aspects_Count;
      if not Get ("is") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'is' is expected at " & Image (Link (Code))
         );
      elsif Get ("separate") then
         Body_Expected;
         Check_Body_Stub (Code, Parent, "Task body");
         if Aspects_Count > 0 then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Task aspect specified at "         &
               Image (Aspects_At)                  &
               " must appear after 'separate' at " &
               Image (Link (Code))
            );
         end if;
         declare
            type Arena_Ptr is access Task_Stub;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Task_Stub (Get_Aspects_Count);
            This : Task_Stub renames Ptr.all;
         begin
            Pop (Context, This.Aspects);
            Set (Context, Name, Parent, File, This, This.Name'Access);
            Result.Value := This'Unchecked_Access;
         end;
      elsif Get ("(", False) then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Task body cannot be an expression found at " &
            Image (Link (Code))
         );
      elsif Get ("null") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Task body cannot be null found at " &
            Image (Link (Code))
         );
      else
         case Get_Kind_Of (Parent) is
            when Code_Block_Context     |
                 Protected_Body_Context |
                 Library_Unit_Context   =>
               null;
            when others =>
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Task body is not allowed in the " &
                  Image (Get_Kind_Of (Parent))       &
                  " at "                                                            &
                  Image (Link (Code))
               );
         end case;
         declare
            Declarations : Declaration_Context_Ref;
            Sequence     : Statement_Sequence_Ref;
            Private_Unit : Boolean;
         begin
            Get_Context
            (  Context      => Context,
               Code         => Code,
               File         => File,
               Kind_Of      => Code_Block_Context,
               Parent       => Parent,
               Private_Unit => Private_Unit,
               Keyword      => Keyword,
               Result       => Declarations
            );
            case Keyword is
               when Begin_Word =>
                  Get_Sequence
                  (  Context   => Context,
                     Code      => Code,
                     File      => File,
                     Parent    => Ref (Declarations),
                     Handled   => Handled_Sequence or Task_Sequence,
                     Enclosing => null,
                     Keyword   => Keyword,
                     Result    => Sequence
                  );
                  if Keyword /= End_Word then
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'end' is expected at " &
                        Image (Link (Code))
                     );
                  end if;
               when End_Word =>
                  null;
               when others =>
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'begin' or 'end' is expected at " &
                     Image (Link (Code))
                  );
            end case;
            Add (Context, Declarations.all, Before (Code), File);
            declare
               type Arena_Ptr is access Task_Body;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr  : constant Arena_Ptr :=
                  new Task_Body
                      (  Declarations  => Declarations,
                         Aspects_Count => Aspects_Count,
                         Separate_Body => Separated.Separate_Body,
                         Code          => Handled_Statement_Sequence
                                          (  Sequence.all
                                          ) 'Access
                      );
               This : Task_Body renames Ptr.all;
            begin
               Sequence.Outer := This'Unchecked_Access;
               This.Parent    := Separated;
               Pop (Context, This.Aspects);
               Set
               (  Context,
                  Name,
                  Parent,
                  File,
                  This,
                  This.Name'Access
               );
               Get_Blank (Context, Code);
               if not Has_Semicolon (Code) then
                  Check (Context, Code, Name);
               end if;
               Result.Value := This'Unchecked_Access;
            end;
         end;
      end if;
   elsif Get ("type") then
      Body_Expected;
      Get_Simple_Name (Context, Code, True, Name);
      Profile := Get_Procedure_Profile
                 (  Context   => Context'Access,
                    Code      => Code'Access,
                    File      => File,
                    Parent    => Parent,
                    Unknown   => True,
                    No_Access => False,
                    Profile   => True
                 );
      Aspects_Count := Get_Aspects_Count;
      if Get ("is") then
         declare
            Interfaces_Count : constant Natural :=
                                        Get_Interfaces_List
                                        (  Context => Context'Access,
                                           Code    => Code'Access,
                                           Prefix  => "new"
                                        );
            Private_Unit : Boolean;
            Keyword      : Reserved_Word;
            Public_Part  : Declaration_Context_Ref;
            Private_Part : Declaration_Context_Ref;
            Private_At   : Location;
         begin
            if Interfaces_Count > 0 and then not Get ("with") then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'with' is expected to end the task " &
                  "type interface list at "             &
                  Image (Link (Code))
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
               Kind_Of      => Task_Interface_Context,
               Parent       => Enclosing,
               Private_Unit => Private_Unit,
               Keyword      => Keyword,
               Result       => Public_Part
            );
            case Keyword is
               when Private_Word =>
                  Private_At := Link (Code);
                  Get_Context
                  (  Context      => Context,
                     Code         => Code,
                     File         => File,
                     Kind_Of      => Task_Private_Context,
                     Parent       => Ref (Public_Part),
                     Private_Unit => Private_Unit,
                     Keyword      => Keyword,
                     Result       => Private_Part
                  );
                  case Keyword is
                     when Private_Word =>
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "Private part of the task definition " &
                           "specified at "                        &
                           Image (Private_At)                     &
                           " is duplicated at "                   &
                           Image (Link (Code))
                        );
                     when End_Word =>
                        null;
                     when others =>
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "'end' is expected at " &
                           Image (Link (Code))
                        );
                  end case;
               when End_Word =>
                  null;
               when others =>
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'private' or 'end' is expected at " &
                     Image (Link (Code))
                  );
            end case;
            Get_Blank (Context, Code);
            if not Has_Semicolon (Code) then
               Check (Context, Code, Name);
            end if;
            declare
               type Arena_Ptr is access Task_Type_Declaration;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr  : constant Arena_Ptr :=
                           new Task_Type_Declaration
                               (  Aspects_Count    => Aspects_Count,
                                  Interfaces_Count => Interfaces_Count
                               );
               This : Task_Type_Declaration renames Ptr.all;
               Ends : constant Location := Before (Code);
            begin
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
                  This.Discriminants := Profile.all'Unchecked_Access;
                  Add (Context, Profile.all, Ends, File);
               end if;
               This.Public_Part  := Public_Part.all'Unchecked_Access;
               Pop (Context, This.Aspects);
               Pop (Context, This.Interfaces);
               if Private_Part /= null then
                  This.Private_Part :=
                     Private_Part.all'Unchecked_Access;
                  Add (Context, Private_Part.all, Ends, File);
               end if;
               Add (Context, Public_Part.all, Ends, File);
               Result.Value := This'Unchecked_Access;
            end;
         end;
      else
         declare
            type Arena_Ptr is access Task_Type_Declaration;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Task_Type_Declaration
                            (  Aspects_Count    => Aspects_Count,
                               Interfaces_Count => 0
                            );
            This : Task_Type_Declaration renames Ptr.all;
         begin
            Set (Context, Name, Parent, File, This, This.Name'Access);
            Pop (Context, This.Aspects);
            Result.Value := This'Unchecked_Access;
         end;
      end if;
   else
      Body_Expected;
      Get_Simple_Name (Context, Code, True, Name);
      Aspects_Count := Get_Aspects_Count;
      if Get ("is") then
         declare
            Interfaces_Count : constant Natural :=
                                        Get_Interfaces_List
                                        (  Context => Context'Access,
                                           Code    => Code'Access,
                                           Prefix  => "new"
                                        );
            Private_Unit : Boolean;
            Keyword      : Reserved_Word;
            Public_Part  : Declaration_Context_Ref;
            Private_Part : Declaration_Context_Ref;
            Private_At   : Location;
         begin
            if Interfaces_Count > 0 and then not Get ("with") then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'with' is expected to end the task's " &
                  "interface list at "                    &
                  Image (Link (Code))
               );
            end if;
            Get_Context
            (  Context      => Context,
               Code         => Code,
               File         => File,
               Kind_Of      => Task_Interface_Context,
               Parent       => Enclosing,
               Private_Unit => Private_Unit,
               Keyword      => Keyword,
               Result       => Public_Part
            );
            case Keyword is
               when Private_Word =>
                  Private_At := Link (Code);
                  Get_Context
                  (  Context      => Context,
                     Code         => Code,
                     File         => File,
                     Kind_Of      => Task_Private_Context,
                     Parent       => Ref (Public_Part),
                     Private_Unit => Private_Unit,
                     Keyword      => Keyword,
                     Result       => Private_Part
                  );
                  case Keyword is
                     when Private_Word =>
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "Private part of the task definition " &
                           "specified at "                        &
                           Image (Private_At)                     &
                           " is duplicated at "                   &
                           Image (Link (Code))
                        );
                     when End_Word =>
                        null;
                     when others =>
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "'end' is expected at " &
                           Image (Link (Code))
                        );
                  end case;
               when End_Word =>
                  null;
               when others =>
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'private' or 'end' is expected at " &
                     Image (Link (Code))
                  );
            end case;
            declare
               type Arena_Ptr is access Single_Task_Declaration;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr  : constant Arena_Ptr :=
                           new Single_Task_Declaration
                               (  Aspects_Count    => Aspects_Count,
                                  Interfaces_Count => Interfaces_Count
                               );
               This : Single_Task_Declaration renames Ptr.all;
               Ends : constant Location := Before (Code);
            begin
               Set
               (  Context,
                   Name,
                   Parent,
                   File,
                   This,
                   This.Name'Access
               );
               This.Public_Part := Public_Part.all'Unchecked_Access;
               Pop (Context, This.Interfaces);
               Pop (Context, This.Aspects);
               Get_Blank (Context, Code);
               if not Has_Semicolon (Code) then
                  Check (Context, Code, Name);
               end if;
               if Private_Part /= null then
                  This.Private_Part :=
                     Private_Part.all'Unchecked_Access;
                  Add (Context, Private_Part.all, Ends, File);
               end if;
               Add (Context, Public_Part.all, Ends, File);
               Result.Value := This'Unchecked_Access;
            end;
         end;
      else
         declare
            type Arena_Ptr is access Single_Task_Declaration;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Single_Task_Declaration
                            (  Aspects_Count    => Aspects_Count,
                               Interfaces_Count => 0
                           );
            This : Single_Task_Declaration renames Ptr.all;
         begin
            Set (Context, Name, Parent, File, This, This.Name'Access);
            Pop (Context, This.Aspects);
            Result.Value := This'Unchecked_Access;
         end;
      end if;
   end if;
   Get_Semicolon (Context, Code);
   Result.Location := Result.Location & Link (Code);
end Get_Task;
