--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Protected                            Spring, 2026       --
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
   procedure Get_Protected
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
            "Separate protected body is expected at " &
            Image (Link (Code))
         );
      end if;
   end Body_Expected;

   Aspects_Count : Natural := 0;
   Profile       : Parameter_Profile_Ref;
   Keyword       : Reserved_Word;
   Name          : Tokens.Argument_Token;

   function Enclosing return Context_Location is
   begin
      if Profile = null then
         return Parent;
      else
         return Ref (Profile);
      end if;
   end Enclosing;
begin
   Result.Location := Before (Code);
   if Get ("body") then
      if Is_Formal_Generic (Parent) then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Protected body is not allowed as a formal generic " &
            "parameter  at "                                     &
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
         Check_Body_Stub (Code, Parent, "Protected body");
         if Aspects_Count > 0 then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Protected body aspect specified at " &
               Image (Aspects_At)                    &
               " must appear after 'separate' at "   &
               Image (Link (Code))
            );
         end if;
         declare
            type Arena_Ptr is access Protected_Stub;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Protected_Stub (Aspects_Count);
            This : Protected_Stub renames Ptr.all;
         begin
            Pop (Context, This.Aspects);
            Set (Context, Name, Parent, File, This, This.Name'Access);
            Get_Semicolon (Context, Code);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Result.Location & Link (Code);
            This.Location   := Result.Location;
         end;
      elsif Get ("(", False) then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Protected body cannot be an expression as found at " &
            Image (Link (Code))
         );
      elsif Get ("null") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Protected body cannot be null as found at " &
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
                  "Protected body is not allowed in the " &
                  Image (Get_Kind_Of (Parent))            &
                  " at "                                  &
                  Image (Link (Code))
               );
         end case;
         declare
            Declarations : Declaration_Context_Ref;
            Private_Unit : Boolean;
         begin
            Get_Context
            (  Context      => Context,
               Code         => Code,
               File         => File,
               Kind_Of      => Protected_Body_Context,
               Parent       => Parent,
               Private_Unit => Private_Unit,
               Keyword      => Keyword,
               Result       => Declarations
            );
            case Keyword is
               when End_Word =>
                  null;
               when others =>
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'end' is expected at " &
                     Image (Link (Code))
                  );
            end case;
            Add (Context, Declarations.all, Link (Code), File);
            declare
               type Arena_Ptr is access Protected_Body;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr  : constant Arena_Ptr :=
                      new Protected_Body
                          (  Declarations  => Declarations,
                             Aspects_Count => Aspects_Count,
                             Separate_Body => Separated.Separate_Body
                          );
               This : Protected_Body renames Ptr.all;
            begin
               This.Parent := Separated;
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
               Get_Semicolon (Context, Code);
               Result.Value    := This'Unchecked_Access;
               Result.Location := Result.Location & Link (Code);
               This.Location   := Result.Location;
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
                    Unknown   => False,
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
                                           Prefix  => "and"
                                        );
            Private_Unit : Boolean;
            Keyword      : Reserved_Word;
            Public_Part  : Declaration_Context_Ref;
            Private_Part : Declaration_Context_Ref;
            Private_At   : Location;
         begin
            if Profile /= null then
               Profile.Scope := Before (Code);
               Profile.File  := File;
            end if;
            Get_Context
            (  Context      => Context,
               Code         => Code,
               File         => File,
               Kind_Of      => Protected_Interface_Context,
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
                     Kind_Of      => Protected_Private_Context,
                     Parent       => Ref (Public_Part),
                     Private_Unit => Private_Unit,
                     Keyword      => Keyword,
                     Result       => Private_Part
                  );
                  case Keyword is
                     when Private_Word =>
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "Private part of the protected " &
                           "definition specified at "       &
                           Image (Private_At)               &
                           " is duplicated at "             &
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
               type Arena_Ptr is access Protected_Type_Declaration;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr  : constant Arena_Ptr :=
                      new Protected_Type_Declaration
                          (  Aspects_Count    => Aspects_Count,
                             Interfaces_Count => Interfaces_Count,
                             Public_Part      => Public_Part.all'Access
                          );
               Ends : constant Location := Before (Code);
               This : Protected_Type_Declaration renames Ptr.all;
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
               if Private_Part /= null then
                  This.Private_Part :=
                     Private_Part.all'Unchecked_Access;
                  Add (Context, Private_Part.all, Ends, File);
               end if;
               Pop (Context, This.Aspects);
               Pop (Context, This.Interfaces);
               Get_Blank (Context, Code);
               if not Has_Semicolon (Code) then
                  Check (Context, Code, Name);
               end if;
               Add (Context, Public_Part.all, Ends, File);
               Get_Semicolon (Context, Code);
               Result.Value    := This'Unchecked_Access;
               Result.Location := Result.Location & Link (Code);
               This.Location   := Result.Location;
            end;
         end;
      else
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'is' is expected at " & Image (Link (Code))
         );
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
                  "'with' is expected after interface list at " &
                  Image (Link (Code))
               );
            end if;
            Get_Context
            (  Context      => Context,
               Code         => Code,
               File         => File,
               Kind_Of      => Protected_Interface_Context,
               Parent       => Parent,
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
                     Kind_Of      => Protected_Private_Context,
                     Parent       => Ref (Public_Part),
                     Private_Unit => Private_Unit,
                     Keyword      => Keyword,
                     Result       => Private_Part
                  );
                  case Keyword is
                     when Private_Word =>
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "Private part of the protected object " &
                           "definition specified at "              &
                           Image (Private_At)                      &
                           " is duplicated at "                    &
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
               type Arena_Ptr is access Single_Protected_Declaration;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr  : constant Arena_Ptr :=
                      new Single_Protected_Declaration
                          (  Aspects_Count    => Aspects_Count,
                             Interfaces_Count => Interfaces_Count
                          );
               This : Single_Protected_Declaration renames Ptr.all;
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
               if Private_Part /= null then
                  This.Private_Part :=
                     Private_Part.all'Unchecked_Access;
                  Add
                  (  Context,
                     Private_Part.all,
                     Private_Part.Scope,
                     File
                  );
               end if;
               Add (Context, Public_Part.all, Public_Part.Scope, File);
               Get_Semicolon (Context, Code);
               Result.Value    := This'Unchecked_Access;
               Result.Location := Result.Location & Link (Code);
               This.Location   := Result.Location;
            end;
         end;
      else
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'is' expected at " & Image (Link (Code))
         );
      end if;
   end if;
end Get_Protected;
