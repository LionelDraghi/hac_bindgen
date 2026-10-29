--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Package                              Spring, 2026       --
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
   procedure Get_Package
             (  Context      : in out Ada_Program;
                Code         : in out Source'Class;
                File         : Source_Description_Ptr;
                Parent       : Context_Location;
                Separated    : Parent_Unit;
                Private_Unit : Boolean;
                Generic_Unit : Boolean;
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

   procedure Body_Expected is
   begin
      if Separated.Separate_Body then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Package body is expected at " &
            Image (Link (Code))
         );
      end if;
   end Body_Expected;

   Aspects_Count : Natural := 0;
   Name          : Tokens.Argument_Token;
   Target        : Tokens.Argument_Token;

   procedure Get_Renaming (Parent : Context_Location) is
      type Arena_Ptr is access Package_Renaming;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Ptr  : constant Arena_Ptr :=
                  new Package_Renaming
                      (  Generic_Unit  => Generic_Unit,
                         Aspects_Count => Get_Aspects_Count
                      );
      This : Package_Renaming renames Ptr.all;
   begin
      Pop (Context, This.Aspects);
      Set (Context, Name, Parent, File, This, This.Name'Access);
      This.Full_Name  := Name;
      This.Target     := Target;
      This.Parent     := Parent;
      Get_Semicolon (Context, Code);
      Result.Value    := This'Unchecked_Access;
      Result.Location := Result.Location & Link (Code);
      This.Location   := Result.Location;
   end Get_Renaming;

begin
   Result.Location := Before (Code);
   if Get ("body") then
      if Library_Unit then
         Get_Expanded_Name (Context, Code, False, Name);
      elsif Generic_Unit then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Generic package body cannot have a formal " &
            "generic part as found at "                  &
            Image (Link (Code))
         );
      else
         case Get_Kind_Of (Parent) is
            when Code_Block_Context     |
                 Protected_Body_Context |
                 Library_Unit_Context   =>
               Get_Simple_Name (Context, Code, False, Name);
            when others =>
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Package body is not allowed in the " &
                  Image (Get_Kind_Of (Parent))          &
                  " at "                                &
                  Image (Link (Code))
               );
         end case;
      end if;
      Aspects_Count := Get_Aspects_Count;
      if not Get ("is") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'is' is expected at " & Image (Link (Code))
         );
      elsif Get ("separate") then
         Body_Expected;
         Check_Body_Stub (Code, Parent, "Package body");
         if Aspects_Count > 0 then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Package aspect specified at "      &
               Image (Aspect_At)                   &
               " must appear after 'separate' at " &
               Image (Link (Code))
            );
         end if;
         declare
            type Arena_Ptr is access Package_Stub;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Package_Stub (Get_Aspects_Count);
            This : Package_Stub renames Ptr.all;
         begin
            Set (Context, Name, Parent, File, This, This.Name'Access);
            Pop (Context, This.Aspects);
            Get_Semicolon (Context, Code);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Result.Location & Link (Code);
            This.Location   := Result.Location;
         end;
      elsif Get ("(", False) then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Package body cannot be an expression found at " &
            Image (Link (Code))
         );
      elsif Get ("null") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Package body cannot be null found at " &
            Image (Link (Code))
         );
      else
         declare
            Private_Unit : Boolean;
            Keyword      : Reserved_Word;
            Declarations : Declaration_Context_Ref;
            Sequence     : Statement_Sequence_Ref;
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
                     Handled   => Handled_Sequence,
                     Enclosing => null,
                     Keyword   => Keyword,
                     Result    => Sequence
                  );
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
               type Arena_Ptr is access Package_Body;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr  : constant Arena_Ptr :=
                      new Package_Body
                          (  Declarations  => Declarations,
                             Separate_Body => Separated.Separate_Body,
                             Aspects_Count => Aspects_Count
                          );
               This : Package_Body renames Ptr.all;
            begin
               Set
               (  Context,
                  Name,
                  Parent,
                  File,
                  This,
                  This.Name'Access
               );
               This.Full_Name := Name;
               This.Parent    := Separated;
               if Sequence /= null then
                  Sequence.Outer := This'Unchecked_Access;
                  This.Code := Handled_Statement_Sequence
                               (  Sequence.all
                               ) 'Unchecked_Access;
               end if;
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
   else
      Body_Expected;
      if Library_Unit then
         Get_Expanded_Name (Context, Code, False, Name);
      else
         Get_Simple_Name (Context, Code, False, Name);
      end if;
      Aspects_Count := Get_Aspects_Count;
      if Get ("is") then
         if Get ("separate") then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Package specification is expected at " &
               Image (Link (Code))
            );
         elsif Get ("new") then
            if Generic_Unit then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Generic package instantiation cannot have " &
                  "a formal generic part as found at "         &
                  Image (Link (Code))
               );
            elsif Aspects_Count > 0 then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Package instantiation aspect specified at " &
                  Image (Aspect_At)                            &
                  " must appear after 'new' at "               &
                  Image (Link (Code))
               );
            end if;
            declare
               Target : Tokens.Argument_Token;
            begin
               Lexers.Parse (Context, Code, Target);
               declare
                  type Arena_Ptr is access Package_Instantiation;
                  for Arena_Ptr'Storage_Pool use Context.Pool.all;
                  Ptr  : constant Arena_Ptr :=
                         new Package_Instantiation (Get_Aspects_Count);
                  This : Package_Instantiation renames Ptr.all;
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
         else
            declare
               Is_Private   : Boolean;
               Keyword      : Reserved_Word;
               Public_Part  : Declaration_Context_Ref;
               Private_Part : Declaration_Context_Ref;
               Private_At   : Location;
            begin
               Get_Context
               (  Context      => Context,
                  Code         => Code,
                  File         => File,
                  Kind_Of      => Package_Interface_Context,
                  Parent       => Parent,
                  Private_Unit => Is_Private,
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
                        Kind_Of      => Package_Private_Context,
                        Parent       => Ref (Public_Part),
                        Private_Unit => Is_Private,
                        Keyword      => Keyword,
                        Result       => Private_Part
                     );
                     case Keyword is
                        when Private_Word =>
                           Raise_Exception
                           (  Parsers.Syntax_Error'Identity,
                              "Private part of the package " &
                              "specified at "                &
                              Image (Private_At)             &
                              " is duplicated at "           &
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
                     Add
                     (  Context,
                        Private_Part.all,
                        Before (Code),
                        File
                     );
                  when End_Word =>
                     null;
                  when others =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'end' or 'private' is expected at " &
                        Image (Link (Code))
                     );
               end case;
               Add (Context, Public_Part.all, Before (Code), File);
               declare
                  type Arena_Ptr is access Package_Declaration;
                  for Arena_Ptr'Storage_Pool use Context.Pool.all;
                  Ptr  : constant Arena_Ptr :=
                              new Package_Declaration
                                  (  Private_Unit  => Private_Unit,
                                     Generic_Unit  => Generic_Unit,
                                     Public_Part   => Public_Part,
                                     Aspects_Count => Aspects_Count
                                  );
                  This : Package_Declaration renames Ptr.all;
               begin
                  Set
                  (  Context,
                     Name,
                     Parent,
                     File,
                     This,
                     This.Name'Access
                  );
                  This.Full_Name := Name;
                  if Private_Part /= null then
                     This.Private_Part :=
                        Private_Part.all'Unchecked_Access;
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
         end if;
      elsif Get ("renames") then
         if Aspects_Count > 0 then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Package renaming aspect specified at " &
               Image (Aspect_At)                       &
               " must appear after 'renames' at "      &
               Image (Link (Code))
            );
         end if;
         Get_Blank (Context, Code);
         Get_Expanded_Name (Context, Code, True, Target);
         if Generic_Unit then
            if Get_Items_Number (Parent.Context.all) > 0 then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Generic package renaming cannot have a formal " &
                  "generic part as found at "                      &
                  Image (Parent.Context.Location)
               );
            end if;
            Get_Renaming (Parent.Context.Parent);
         else
            Get_Renaming (Parent);
         end if;
      else
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'is' is expected at " & Image (Link (Code))
         );
      end if;
   end if;
end Get_Package;
