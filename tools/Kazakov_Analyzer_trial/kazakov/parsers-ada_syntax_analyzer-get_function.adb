--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Function                             Spring, 2026       --
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

with Strings_Edit.Integers;

with Parsers.Ada_Syntax_Analyzer.Bodies;
use  Parsers.Ada_Syntax_Analyzer.Bodies;

with Parsers.Ada_Syntax_Analyzer.Declarations.Renamings;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Renamings;

with Parsers.Ada_Syntax_Analyzer.Declarations.Stubs;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Stubs;

separate (Parsers.Ada_Syntax_Analyzer)
   procedure Get_Function
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
   use Object_Specification_Stack;

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
      Get_Simple_Name (Context, Code, False, Name);
   end if;
   Get_Blank (Context, Code);
   if Get ("is") then
      if not Get ("new") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'new' is expected after 'is' in function " &
            "renaming at "                              &
            Image (Link (Code))
         );
      elsif Generic_Unit then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Generic function instantiation cannot have a formal " &
            "generic part as found at "                            &
            Image (Link (Code))
         );
      end if;
      declare
         Target : Tokens.Argument_Token;
      begin
         Lexers.Parse (Context, Code, Target);
         declare
            type Arena_Ptr is access Function_Instantiation;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Function_Instantiation
                            (  Overrides,
                               Get_Aspects_Count
                            );
            This : Function_Instantiation renames Ptr.all;
         begin
            Set (Context, Name, Parent, File, This, This.Name'Access);
            This.Full_Name  := Name;
            This.Target     := Target;
            Get_Semicolon (Context, Code);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Result.Location & Link (Code);
            This.Location   := Result.Location;
         end;
      end;
   else
      Profile := Get_Function_Profile
                 (  Context => Context'Access,
                    Code    => Code'Access,
                    File    => File,
                    Parent  => Parent
                 );
      declare
         use Strings_Edit.Integers;
         Operator : constant Operations := Get_Operator (Name);
         function Count return Natural is
         begin
            if Profile = null then
               return 0;
            else
               return Get_Count (Profile.all);
            end if;
         end Count;
      begin
         case Operator is
            when Add | Sub =>
               if Count not in 1..2 then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Unary or dyadic operator '"         &
                     Image (Operator)                     &
                     "' has wrong number of parameters (" &
                     Image (Count)                        &
                     ") at "                              &
                     Image (Result.Location & Link (Code))
                  );
               end if;
            when Concatenate | Modulus    | Remainder   |
                 Logical_And | Logical_Or | Logical_Xor |
                 Mul | Pow | Div | NE | LT | LE | EQ | GT | GE =>
               if Count /= 2 then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Dyadic operator '"                  &
                     Image (Operator)                     &
                     "' has wrong number of parameters (" &
                     Image (Count)                        &
                     ") at "                              &
                     Image (Result.Location & Link (Code))
                  );
               end if;
            when Abs_Value | Logical_Not =>
               if Count /= 1 then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Unary operator '"                   &
                     Image (Operator)                     &
                     "' has wrong number of parameters (" &
                     Image (Count)                        &
                     ") at "                              &
                     Image (Result.Location & Link (Code))
                  );
               end if;
            when others =>
               null;
         end case;
      end;
      Aspects_Count := Get_Aspects_Count;
      if Get ("is") then
         if Profile /= null then
            Profile.Scope := Before (Code);
            Profile.File  := File;
         end if;
         if Get ("separate") then
            if Library_Unit then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "A function body is expected at " &
                  Image (Link (Code))
               );
            elsif Generic_Unit then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Generic function stub cannot have a formal " &
                  "generic part as found at "                   &
                  Image (Link (Code))
               );
            end if;
            Check_Body_Stub (Code, Parent, "Function body");
            if Name.Value.all in String_Literal then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Function stubs are not allowed for " &
                  "operators as found at "              &
                  Image (Name.Location)
               );
            elsif Aspects_Count > 0 then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Function body aspect specified at " &
                  Image (Aspect_At)                    &
                  " must appear after 'separate' at "  &
                  Image (Link (Code))
               );
            end if;
            declare
               type Arena_Ptr is access Function_Stub;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr   : constant Arena_Ptr :=
                            new Function_Stub
                                (  Aspects_Count => Get_Aspects_Count,
                                   Overrides     => Overrides
                                );
               This  : Function_Stub renames Ptr.all;
               Where : Location;
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
                  This.Profile  := Profile.all'Unchecked_Access;
               end if;
               Pop (Context, This.Aspects);
               Pop (Context, This.Result, Where);
               Add_Outer (This.Result.all, This, Parent);
               Get_Semicolon (Context, Code);
               Result.Value    := This'Unchecked_Access;
               Result.Location := Result.Location & Link (Code);
               This.Location   := Result.Location;
            end;
         elsif Get ("(", False) then
            if Library_Unit then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "The body in a compilation unit cannot " &
                  "be an expression as found at "          &
                  Image (Link (Code))
               );
            elsif Aspects_Count > 0 then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Function expression aspect specified at " &
                  Image (Aspect_At)                          &
                  " must appear after the expression at "   &
                  Image (Link (Code))
               );
            elsif Generic_Unit then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Generic function cannot be an expression as " &
                  "as found at "                                 &
                  Image (Link (Code))
               );
            end if;
            declare
               Body_Of : Tokens.Argument_Token;
            begin
               Reset_Pointer (Code);
               Get_Blank (Context, Code);
               Lexers.Parse (Context, Code, Body_Of);
               if Body_Of.Value.all in Expression then
                  declare
                     This : Expression renames
                            Expression (Body_Of.Value.all);
                  begin
                     if This.Operation = Left_Bracket and then
                        This.Operands'Length = 1
                     then -- Drop enclosing paranthesis
                        Body_Of := This.Operands (1);
                     end if;
                  end;
               end if;
               declare
                  type Arena_Ptr is access Function_Expression;
                  for Arena_Ptr'Storage_Pool use Context.Pool.all;
                  Ptr   : constant Arena_Ptr :=
                          new Function_Expression
                              (  Aspects_Count => Get_Aspects_Count,
                                 Overrides     => Overrides
                              );
                  This  : Function_Expression renames Ptr.all;
                  Where : Location;
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
                     Add (Context, Profile.all, Link (Code), File);
                     This.Profile := Profile.all'Unchecked_Access;
                  end if;
                  This.Expression := Body_Of;
                  Pop (Context, This.Aspects);
                  Pop (Context, This.Result, Where);
                  Add_Outer (This.Result.all, This, Parent);
                  Get_Semicolon (Context, Code);
                  Result.Value    := This'Unchecked_Access;
                  Result.Location := Result.Location & Link (Code);
                  This.Location   := Result.Location;
               end;
            end;
         elsif Get ("null") then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Function body cannot be null as found at " &
               Image (Link (Code))
            );
         elsif Get ("abstract") then
            if Library_Unit then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "A body of the function is expected at " &
                  Image (Link (Code))
               );
            elsif Aspects_Count > 0 then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Abstract function aspect specified at " &
                  Image (Aspect_At)                        &
                  " must appear after 'abstract' at "      &
                  Image (Link (Code))
               );
            elsif Generic_Unit then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Generic function cannot be abstract as found at " &
                  Image (Link (Code))
               );
            end if;
            declare
               type Arena_Ptr is access Function_Declaration;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr   : constant Arena_Ptr :=
                       new Function_Declaration
                           (  Private_Unit        => Private_Unit,
                              Generic_Unit        => Generic_Unit,
                              Abstract_Subprogram => True,
                              Overrides           => Overrides,
                              Aspects_Count       => Get_Aspects_Count
                           );
               This  : Function_Declaration renames Ptr.all;
               Where : Location;
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
               if Profile /= null then
                  Profile.Outer := This'Unchecked_Access;
                  This.Profile  := Profile.all'Unchecked_Access;
               end if;
               Pop (Context, This.Aspects);
               Pop (Context, This.Result, Where);
               Add_Outer (This.Result.all, This, Parent);
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
                  "Generic function body cannot have a formal " &
                  "generic part as found at "                   &
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
                     "Function body is not allowed in the " &
                     Image (Get_Kind_Of (Parent))           &
                     " at "                                 &
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
                  Handled   => Handled_Sequence or Function_Sequence,
                  Enclosing => null,
                  Keyword   => Keyword,
                  Result    => Sequence
               );
               declare
                  Ends : constant Location := Before (Code);
               begin
                  if Profile /= null then
                     Add (Context, Profile.all, Ends, File);
                  end if;
                  Add (Context, Declarations.all, Ends, File);
               end;
               declare
                  type Arena_Ptr is access Function_Body;
                  for Arena_Ptr'Storage_Pool use Context.Pool.all;
                  Ptr : constant Arena_Ptr :=
                     new Function_Body
                         (  Declarations  => Declarations,
                            Separate_Body => Separated.Separate_Body,
                            Overrides     => Overrides,
                            Aspects_Count => Aspects_Count,
                            Code          => Handled_Statement_Sequence
                                             (  Sequence.all
                                             ) 'Access
                         );
                  This  : Function_Body renames Ptr.all;
                  Where : Location;
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
                  This.Full_Name := Name;
                  This.Parent    := Separated;
                  if Profile /= null then
                     Profile.Outer := This'Unchecked_Access;
                     This.Profile  := Profile.all'Unchecked_Access;
                  end if;
                  Pop (Context, This.Result, Where);
                  Add_Outer (This.Result.all, This, Parent);
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
                "A function separate body is expected at " &
                Image (Link (Code))
             );
         elsif Aspects_Count > 0 then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Function renaming aspect specified at " &
               Image (Aspect_At)                        &
               " must appear after 'renames' at "       &
               Image (Link (Code))
            );
         end if;
         declare
            Target : Tokens.Argument_Token;

            procedure Get_Renaming (Parent : Context_Location) is
               type Arena_Ptr is access Function_Renaming;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr : constant Arena_Ptr :=
                          new Function_Renaming
                              (  Private_Unit  => Private_Unit,
                                 Generic_Unit  => Generic_Unit,
                                 Overrides     => Overrides,
                                 Aspects_Count => Get_Aspects_Count
                              );
               This  : Function_Renaming renames Ptr.all;
               Where : Location;
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
               This.Target    := Target;
               This.Parent    := Parent;
               if Profile /= null then
                  Profile.Outer := This'Unchecked_Access;
                  This.Profile  := Profile.all'Unchecked_Access;
               end if;
               Pop (Context, This.Aspects);
               Pop (Context, This.Result, Where);
               Add_Outer (This.Result.all, This, Parent);
               Get_Semicolon (Context, Code);
               Result.Value    := This'Unchecked_Access;
               Result.Location := Result.Location & Link (Code);
               This.Location   := Result.Location;
            end Get_Renaming;
         begin
            Lexers.Parse (Context, Code, Target);
            Check_Name (Target, False);
            if Generic_Unit then
               if Get_Items_Number (Parent.Context.all) > 0 then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Generic function renaming cannot have a formal " &
                     "generic part as found at "                       &
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
            type Arena_Ptr is access Function_Declaration;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr   : constant Arena_Ptr :=
                         new Function_Declaration
                             (  Private_Unit        => Private_Unit,
                                Generic_Unit        => Generic_Unit,
                                Abstract_Subprogram => False,
                                Overrides           => Overrides,
                                Aspects_Count       => Aspects_Count
                             );
            This  : Function_Declaration renames Ptr.all;
            Where : Location;
         begin
            Set (Context, Name, Parent, File, This, This.Name'Access);
            This.Full_Name := Name;
            if Profile /= null then
               Profile.Outer := This'Unchecked_Access;
               This.Profile := Profile.all'Unchecked_Access;
            end if;
            Pop (Context, This.Aspects);
            Pop (Context, This.Result, Where);
            Add_Outer (This.Result.all, This, Parent);
            Get_Semicolon (Context, Code);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Result.Location & Link (Code);
            This.Location   := Result.Location;
            This.Parent     := Parent;
         end;
      end if;
   end if;
end Get_Function;
