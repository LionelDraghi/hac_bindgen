--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Context                              Spring, 2026       --
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

separate (Parsers.Ada_Syntax_Analyzer)
   procedure Get_Context
             (  Context      : in out Ada_Program;
                Code         : in out Source'Class;
                File         : Source_Description_Ptr;
                Kind_Of      : Compilation_Context_Type;
                Parent       : Context_Location;
                Private_Unit : out Boolean;
                Keyword      : out Reserved_Word;
                Result       : out Declaration_Context_Ref
             )  is
   use type Ada.Text_IO.File_Access;

   type Use_Clause_Ref is access all Use_Clause'Class;
   for Use_Clause_Ref'Storage_Pool use Context.Pool.all;

   Enclosing       : Context_Location;
   Last_Use_Clause : Use_Clause_Ref;
   Pragmas_Count   : Natural := 0;

   function "or"
             (  Profile : Parameter_Profile_Ref;
                Parent  : Context_Location
             )  return Context_Location is
   begin
      if Profile = null then
         return Parent;
      else
         return
         (  Context => Profile.all'Unchecked_Access,
            After   => Get_Items_Number (Profile.all)
         );
      end if;
   end "or";

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
         Get_Blank (Context, Code);
         Get_Aspect (Context, Code, Count);
      end if;
      return Count;
   end Get_Aspects_Count;

   function Get_Entry (Overrides : Overriding_Indicator_Type)
      return Tokens.Argument_Token is separate;
   function Get_For_Clause
      return Tokens.Argument_Token is separate;
   function Get_Formal_Function
      return Tokens.Argument_Token is separate;
   function Get_Formal_Package
      return Tokens.Argument_Token is separate;
   function Get_Formal_Procedure
      return Tokens.Argument_Token is separate;
   function Get_Formal_Type
      return Tokens.Argument_Token is separate;
   function Get_Object_Declaration
      return Tokens.Argument_Token is separate;
   function Get_Subtype
      return Tokens.Argument_Token is separate;
   function Get_Type
      return Tokens.Argument_Token is separate;
   function Get_Use
      return Tokens.Argument_Token is separate;
   function Get_Variant_Part
      return Tokens.Argument_Token is separate;

   procedure Get_Generic_With is
      Keyword : Reserved_Word;
   begin
      Get_Blank (Context, Code);
      Get_Reserved_Word (Code, Keyword);
      case Keyword is
         when Function_Word =>
            Push (Context, Get_Formal_Function);
            Enclosing.After := Enclosing.After + 1;
            return;
         when Package_Word =>
            Push (Context, Get_Formal_Package);
            Enclosing.After := Enclosing.After + 1;
            return;
         when Procedure_Word =>
            Push (Context, Get_Formal_Procedure);
            Enclosing.After := Enclosing.After + 1;
            return;
         when others =>
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'function', 'package' or 'procedure' is " &
               "expected after 'with' at "                &
               Image (Link (Code))
            );
      end case;
   end Get_Generic_With;

   procedure Get_With (Limited_With, Private_With : Boolean) is
      procedure Check (Name : Tokens.Argument_Token) is
      begin
         if Compare (Identifier (Name.Value.all).Value, "standard") =
            Equal
         then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "A user-defined standard package is specified at " &
               Image (Name.Location)
            );
         end if;
      end Check;
      Result : Tokens.Argument_Token;
      Length : Positive := 1;
   begin
      Result.Location := Link (Code);
      loop
         Get_Expanded_Name (Context, Code, True, Result);
         if Result.Value.all in Expression then
            declare
               This : Expression renames Expression (Result.Value.all);
            begin
               Check (This.Operands (This.Operands'First));
            end;
         else
            Check (Result);
         end if;
         Push (Context, Result);
         exit when not Get (",", False);
         Length := Length + 1;
      end loop;
      declare
         type Arena_Ptr is access With_Clause;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Ptr  : constant Arena_Ptr :=
                     new With_Clause
                         (  Limited_With,
                            Private_With,
                            Length
                         );
      begin
         Result.Value := Ptr.all'Unchecked_Access;
         Pop (Context, Context_Clause (Ptr.all).List);
      end;
      Result.Location := Result.Location & Link (Code);
      Get_Semicolon (Context, Code);
      Push (Context, Result);
      Enclosing.After := Enclosing.After + 1;
   end Get_With;

   procedure Unexpected (Text : String; Where : Location) is
   begin
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         Text                       &
         " is unexpected inside a " &
         Image (Kind_Of)            &
         " as found at "            &
         Image (Where)
      );
   end Unexpected;

   procedure Unexpected is
   begin
      Unexpected (''' & Image (Keyword) & ''', Link (Code));
   end Unexpected;

   type Arena_Ptr is access Declaration_Context;
   for Arena_Ptr'Storage_Pool use Context.Pool.all;

   Null_Record : Boolean := False;
   Ptr         : constant Arena_Ptr :=
                      new Declaration_Context (Kind_Of => Kind_Of);
begin
   Get_Blank (Context, Code);
   Private_Unit := False;
   declare
      This : Declaration_Context renames Ptr.all;
   begin
      This.Parent       := Parent;
      Enclosing.Context := This'Unchecked_Access;
      This.Location     := Link (Code);
      Result            := This'Unchecked_Access;
   end;
   loop
      Get_Reserved_Word (Code, Keyword);
      if Context.Trace /= null then
         Parsers.Multiline_Source.Location_Text_IO.Put_Line
         (  Code    => Code,
            File    => Context.Trace.all,
            Message => " ---context----------------" &
                       Reserved_Word'Image (Keyword) &
                       " in "                        &
                       Image (Kind_Of)               &
                       Natural'Image (Get_Arguments_Count (Context))
         );
      end if;
      case Keyword is
         when Begin_Word =>
            case Kind_Of is
               when Code_Block_Context =>
                  exit;
               when Generic_Formal_Parameters_Context |
                    Library_Unit_Context              |
                    Package_Interface_Context         |
                    Package_Private_Context           |
                    Task_Interface_Context            |
                    Task_Private_Context              |
                    Protected_Interface_Context       |
                    Protected_Body_Context            |
                    Protected_Private_Context         |
                    Record_Component_Context          =>
                  Unexpected;
            end case;
         when Case_Word =>
            case Kind_Of is
               when Record_Component_Context =>
                  Push (Context, Get_Variant_Part);
                  Enclosing.After := Enclosing.After + 1;
               when Code_Block_Context                |
                    Generic_Formal_Parameters_Context |
                    Library_Unit_Context              |
                    Package_Interface_Context         |
                    Package_Private_Context           |
                    Task_Interface_Context            |
                    Task_Private_Context              |
                    Protected_Body_Context            |
                    Protected_Interface_Context       |
                    Protected_Private_Context         =>
                  Unexpected;
            end case;
         when End_Word =>
            case Kind_Of is
               when Generic_Formal_Parameters_Context |
                    Library_Unit_Context              =>
                  Unexpected;
               when Code_Block_Context          |
                    Package_Interface_Context   |
                    Package_Private_Context     |
                    Task_Interface_Context      |
                    Task_Private_Context        |
                    Protected_Body_Context      |
                    Protected_Interface_Context |
                    Protected_Private_Context   =>
                  exit;
               when Record_Component_Context =>
                  exit;
            end case;
         when Entry_Word =>
            case Kind_Of is
               when Code_Block_Context                |
                    Generic_Formal_Parameters_Context |
                    Library_Unit_Context              |
                    Package_Interface_Context         |
                    Package_Private_Context           |
                    Record_Component_Context          =>
                  Unexpected;
               when Task_Interface_Context      |
                    Task_Private_Context        |
                    Protected_Body_Context      |
                    Protected_Interface_Context |
                    Protected_Private_Context   =>
                  Push (Context, Get_Entry (No_Indicator));
                  Enclosing.After := Enclosing.After + 1;
            end case;
         when For_Word =>
            case Kind_Of is
               when Code_Block_Context          |
                    Protected_Interface_Context |
                    Record_Component_Context    |
                    Task_Interface_Context      |
                    Task_Private_Context        |
                    Package_Interface_Context   |
                    Package_Private_Context     |
                    Protected_Private_Context   =>
                  Push (Context, Get_For_Clause);
                  Enclosing.After := Enclosing.After + 1;
               when Generic_Formal_Parameters_Context |
                    Library_Unit_Context              |
                    Protected_Body_Context            =>
                  Unexpected;
            end case;
         when Function_Word =>
            case Kind_Of is
               when Generic_Formal_Parameters_Context |
                    Library_Unit_Context              =>
                  exit;
               when Code_Block_Context          |
                    Package_Interface_Context   |
                    Package_Private_Context     |
                    Protected_Body_Context      |
                    Protected_Interface_Context |
                    Protected_Private_Context   =>
                  declare
                     Result : Tokens.Argument_Token;
                  begin
                     Get_Function
                     (  Context      => Context,
                        Code         => Code,
                        File         => File,
                        Parent       => Enclosing,
                        Separated    => (Separate_Body => False),
                        Private_Unit => False,
                        Generic_Unit => False,
                        Overrides    => No_Indicator,
                        Result       => Result
                     );
                     Push (Context, Result);
                     Enclosing.After := Enclosing.After + 1;
                  end;
               when Record_Component_Context |
                    Task_Interface_Context   |
                    Task_Private_Context     =>
                  Unexpected;
            end case;
         when Generic_Word =>
            case Kind_Of is
               when Library_Unit_Context =>
                  exit;
               when Code_Block_Context        |
                    Package_Interface_Context |
                    Package_Private_Context   =>
                  declare
                     Result : Tokens.Argument_Token;
                  begin
                     Get_Generic
                     (  Context => Context,
                        Code    => Code,
                        File    => File,
                        Parent  => Enclosing,
                        Result  => Result
                     );
                     Push (Context, Result);
                     Enclosing.After := Enclosing.After + 1;
                  end;
               when Generic_Formal_Parameters_Context |
                    Task_Interface_Context            |
                    Task_Private_Context              |
                    Protected_Body_Context            |
                    Protected_Interface_Context       |
                    Protected_Private_Context         |
                    Record_Component_Context          =>
                  Unexpected;
            end case;
         when Limited_Word =>
            case Kind_Of is
               when Library_Unit_Context =>
                  Get_Blank (Context, Code);
                  Get_Reserved_Word (Code, Keyword);
                  case Keyword is
                     when Private_Word =>
                        if not Get ("with") then
                           Raise_Exception
                           (  Parsers.Syntax_Error'Identity,
                              "'with' is expected after " &
                              "'limited private' at "     &
                              Image (Link (Code))
                           );
                        end if;
                        Get_With (True, True);
                     when With_Word =>
                        Get_With (True, False);
                     when others =>
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "'with' or 'private' is expected " &
                           "after 'limited' at "              &
                           Image (Link (Code))
                        );
                  end case;
               when Code_Block_Context                |
                    Generic_Formal_Parameters_Context |
                    Package_Interface_Context         |
                    Package_Private_Context           |
                    Task_Interface_Context            |
                    Task_Private_Context              |
                    Protected_Body_Context            |
                    Protected_Interface_Context       |
                    Protected_Private_Context         |
                    Record_Component_Context          =>
                  Unexpected;
            end case;
         when Not_Word =>
            case Kind_Of is
               when Code_Block_Context          |
                    Package_Interface_Context   |
                    Package_Private_Context     |
                    Protected_Private_Context   |
                    Protected_Interface_Context |
                    Task_Interface_Context      |
                    Task_Private_Context        =>
                  if not Get ("overriding") then
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'overriding' is expected at " &
                        Image (Link (Code))
                     );
                  end if;
                  declare
                     Result : Tokens.Argument_Token;
                  begin
                     Get_Blank (Context, Code);
                     Get_Reserved_Word (Code, Keyword);
                     case Keyword is
                        when Procedure_Word =>
                           Get_Procedure
                           (  Context      => Context,
                              Code         => Code,
                              File         => File,
                              Parent       => Enclosing,
                              Separated    => (Separate_Body => False),
                              Private_Unit => False,
                              Generic_Unit => False,
                              Overrides    =>
                                 Not_Overriding_Indicator,
                              Result       => Result
                           );
                        When Function_Word =>
                           Get_Function
                           (  Context      => Context,
                              Code         => Code,
                              File         => File,
                              Parent       => Enclosing,
                              Separated    => (Separate_Body => False),
                              Private_Unit => False,
                              Generic_Unit => False,
                              Overrides    =>
                                 Not_Overriding_Indicator,
                              Result       => Result
                           );
                        when Entry_Word =>
                           Result :=
                              Get_Entry (Not_Overriding_Indicator);
                        when others =>
                           Raise_Exception
                           (  Parsers.Syntax_Error'Identity,
                              "'function', 'entry' or 'procedure' " &
                              "is expected after 'overriding' at "  &
                              Image (Link (Code))
                           );
                     end case;
                     Push (Context, Result);
                     Enclosing.After := Enclosing.After + 1;
                  end;
               when Generic_Formal_Parameters_Context |
                    Library_Unit_Context              |
                    Protected_Body_Context            |
                    Record_Component_Context          =>
                  Unexpected;
            end case;
         when Null_Word =>
            case Kind_Of is
               when Record_Component_Context =>
                  Get_Semicolon (Context, Code);
                  if Enclosing.After > 1 then
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'null' must be the single member of " &
                        "record declaration at "               &
                        Image (Link (Code))
                     );
                  end if;
                  Enclosing.After := 0;
                  Null_Record     := True;
                  Get_Blank (Context, Code);
                  Get_Reserved_Word (Code, Keyword);
                  case Keyword is
                     when When_Word =>
                        Reset_Pointer (Code);
                     when End_Word =>
                        exit;
                     when others =>
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "'end record' or 'when' is expected at " &
                           Image (Link (Code))
                        );
                  end case;
               when Code_Block_Context                |
                    Generic_Formal_Parameters_Context |
                    Library_Unit_Context              |
                    Package_Interface_Context         |
                    Package_Private_Context           |
                    Protected_Body_Context            |
                    Protected_Private_Context         |
                    Protected_Interface_Context       |
                    Task_Interface_Context            |
                    Task_Private_Context              =>
                  Unexpected;
            end case;
         when Overriding_Word =>
            case Kind_Of is
               when Code_Block_Context          |
                    Package_Interface_Context   |
                    Package_Private_Context     |
                    Protected_Private_Context   |
                    Protected_Interface_Context |
                    Task_Interface_Context      |
                    Task_Private_Context        =>
                  declare
                     Result : Tokens.Argument_Token;
                  begin
                     Get_Blank (Context, Code);
                     Get_Reserved_Word (Code, Keyword);
                     case Keyword is
                        when Procedure_Word =>
                           Get_Procedure
                           (  Context      => Context,
                              Code         => Code,
                              File         => File,
                              Parent       => Enclosing,
                              Separated    => (Separate_Body => False),
                              Private_Unit => False,
                              Generic_Unit => False,
                              Overrides    => Overriding_Indicator,
                              Result       => Result
                           );
                        when Function_Word =>
                           Get_Function
                           (  Context      => Context,
                              Code         => Code,
                              File         => File,
                              Parent       => Enclosing,
                              Separated    => (Separate_Body => False),
                              Private_Unit => False,
                              Generic_Unit => False,
                              Overrides    => Overriding_Indicator,
                              Result       => Result
                           );
                        when Entry_Word =>
                           Result := Get_Entry (Overriding_Indicator);
                        when others =>
                           Raise_Exception
                           (  Parsers.Syntax_Error'Identity,
                              "'function', 'entry' or 'procedure' " &
                              "is expected after 'overriding' at "  &
                              Image (Link (Code))
                           );
                        end case;
                     Push (Context, Result);
                     Enclosing.After := Enclosing.After + 1;
                  end;
               when Generic_Formal_Parameters_Context |
                    Library_Unit_Context              |
                    Protected_Body_Context            |
                    Record_Component_Context          =>
                  Unexpected;
            end case;
         when Package_Word =>
            case Kind_Of is
               when Generic_Formal_Parameters_Context |
                    Library_Unit_Context              =>
                  exit;
               when Code_Block_Context        |
                    Package_Interface_Context |
                    Package_Private_Context   =>
                  declare
                     Result : Tokens.Argument_Token;
                  begin
                     Get_Package
                     (  Context      => Context,
                        Code         => Code,
                        File         => File,
                        Parent       => Enclosing,
                        Separated    => (Separate_Body => False),
                        Private_Unit => False,
                        Generic_Unit => False,
                        Result       => Result
                     );
                     Push (Context, Result);
                     Enclosing.After := Enclosing.After + 1;
                  end;
               when Task_Interface_Context      |
                    Task_Private_Context        |
                    Protected_Body_Context      |
                    Protected_Interface_Context |
                    Protected_Private_Context   |
                    Record_Component_Context    =>
                  Unexpected;
            end case;
         when Pragma_Word =>
            case Kind_Of is
               when Library_Unit_Context        |
                    Package_Interface_Context   |
                    Package_Private_Context     |
                    Protected_Body_Context      |
                    Protected_Interface_Context |
                    Protected_Private_Context   |
                    Record_Component_Context    |
                    Task_Interface_Context      |
                    Task_Private_Context        =>
                  declare
                     Argument : Tokens.Argument_Token;
                  begin
                     Pragmas_Count := Pragmas_Count + 1;
                     Get_Pragma (Context, Code, Argument);
                     Push (Context, Argument);
                     Enclosing.After := Enclosing.After + 1;
                  end;
               when Code_Block_Context                |
                    Generic_Formal_Parameters_Context =>
                 Unexpected;
            end case;
         when Private_Word =>
            case Kind_Of is
               when Library_Unit_Context =>
                  Get_Blank (Context, Code);
                  Get_Reserved_Word (Code, Keyword);
                  case Keyword is
                     when Function_Word | Generic_Word   |
                          Package_Word  | Procedure_Word =>
                        Private_Unit := True;
                        exit;
                     when With_Word =>
                        Get_With (False, True);
                     when No_Reserved_Word =>
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "'function', 'generic', 'package', " &
                           "'procedure', 'with' is expected "   &
                           "after 'private' at "                &
                           Image (Link (Code))
                        );
                     when others =>
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           ''' & Image (Keyword)    &
                           "' is unexpected after " &
                           "'private' at "          &
                           Image (Link (Code))
                        );
                  end case;
               when Code_Block_Context                |
                    Generic_Formal_Parameters_Context |
                    Protected_Body_Context            |
                    Record_Component_Context          =>
                  Unexpected;
               when Package_Interface_Context   |
                    Package_Private_Context     |
                    Task_Interface_Context      |
                    Task_Private_Context        |
                    Protected_Private_Context   |
                    Protected_Interface_Context =>
                  exit;
            end case;
         when Procedure_Word =>
            case Kind_Of is
               when Generic_Formal_Parameters_Context |
                    Library_Unit_Context              =>
                  exit;
               when Code_Block_Context          |
                    Package_Interface_Context   |
                    Package_Private_Context     |
                    Protected_Body_Context      |
                    Protected_Interface_Context |
                    Protected_Private_Context   =>
                  declare
                     Result : Tokens.Argument_Token;
                  begin
                     Get_Procedure
                     (  Context      => Context,
                        Code         => Code,
                        File         => File,
                        Parent       => Enclosing,
                        Separated    => (Separate_Body => False),
                        Private_Unit => False,
                        Generic_Unit => False,
                        Overrides    => No_Indicator,
                        Result       => Result
                     );
                     Push (Context, Result);
                     Enclosing.After := Enclosing.After + 1;
                  end;
               when Record_Component_Context |
                    Task_Interface_Context   |
                    Task_Private_Context     =>
                  Unexpected;
            end case;
         when Protected_Word =>
            case Kind_Of is
               when Code_Block_Context        |
                    Package_Interface_Context |
                    Package_Private_Context   =>
                  declare
                     Result : Tokens.Argument_Token;
                  begin
                     Get_Protected
                     (  Context   => Context,
                        Code      => Code,
                        File      => File,
                        Parent    => Enclosing,
                        Separated => (Separate_Body => False),
                        Result    => Result
                     );
                     Push (Context, Result);
                     Enclosing.After := Enclosing.After + 1;
                  end;
               when Generic_Formal_Parameters_Context |
                    Library_Unit_Context              |
                    Task_Interface_Context            |
                    Task_Private_Context              |
                    Protected_Body_Context            |
                    Protected_Interface_Context       |
                    Protected_Private_Context         |
                    Record_Component_Context          =>
                  Unexpected;
            end case;
         when Separate_Word =>
            case Kind_Of is
               when Library_Unit_Context =>
                  exit;
               when Code_Block_Context                |
                    Generic_Formal_Parameters_Context |
                    Package_Interface_Context         |
                    Package_Private_Context           |
                    Task_Interface_Context            |
                    Task_Private_Context              |
                    Protected_Body_Context            |
                    Protected_Interface_Context       |
                    Protected_Private_Context         |
                    Record_Component_Context          =>
                  Unexpected;
            end case;
         when Subtype_Word =>
            case Kind_Of is
               when Code_Block_Context                |
                    Package_Interface_Context         |
                    Package_Private_Context           =>
                  Push (Context, Get_Subtype);
                  Enclosing.After := Enclosing.After + 1;
               when Generic_Formal_Parameters_Context |
                    Library_Unit_Context              |
                    Task_Interface_Context            |
                    Task_Private_Context              |
                    Protected_Body_Context            |
                    Protected_Interface_Context       |
                    Protected_Private_Context         |
                    Record_Component_Context          =>
                  Unexpected;
            end case;
         when Task_Word =>
            case Kind_Of is
               when Code_Block_Context        |
                    Package_Interface_Context |
                    Package_Private_Context   =>
                  declare
                     Result : Tokens.Argument_Token;
                  begin
                     Get_Task
                     (  Context   => Context,
                        Code      => Code,
                        File      => File,
                        Parent    => Enclosing,
                        Separated => (Separate_Body => False),
                        Result    => Result
                     );
                     Push (Context, Result);
                     Enclosing.After := Enclosing.After + 1;
                  end;
               when Generic_Formal_Parameters_Context |
                    Library_Unit_Context              |
                    Task_Interface_Context            |
                    Task_Private_Context              |
                    Protected_Body_Context            |
                    Protected_Interface_Context       |
                    Protected_Private_Context         |
                    Record_Component_Context          =>
                  Unexpected;
            end case;
         when Type_Word =>
            case Kind_Of is
               when Generic_Formal_Parameters_Context =>
                  Push (Context, Get_Formal_Type);
                  Enclosing.After := Enclosing.After + 1;
               when Code_Block_Context          |
                    Package_Interface_Context   |
                    Package_Private_Context     =>
                  Push (Context, Get_Type);
                  Enclosing.After := Enclosing.After + 1;
               when Library_Unit_Context        |
                    Task_Interface_Context      |
                    Task_Private_Context        |
                    Protected_Body_Context      |
                    Protected_Interface_Context |
                    Protected_Private_Context   |
                    Record_Component_Context    =>
                  Unexpected;
            end case;
         when Use_Word =>
            case Kind_Of is
               when Code_Block_Context                |
                    Generic_Formal_Parameters_Context |
                    Library_Unit_Context              |
                    Package_Interface_Context         |
                    Package_Private_Context           =>
                  Push (Context, Get_Use);
                  Enclosing.After := Enclosing.After + 1;
               when Task_Interface_Context      |
                    Task_Private_Context        |
                    Protected_Body_Context      |
                    Protected_Interface_Context |
                    Protected_Private_Context   |
                    Record_Component_Context    =>
                 Unexpected;
            end case;
         when With_Word =>
            case Kind_Of is
               when Library_Unit_Context =>
                  Get_With (False, False);
               when Generic_Formal_Parameters_Context =>
                  Get_Generic_With;
               when Code_Block_Context          |
                    Package_Interface_Context   |
                    Package_Private_Context     |
                    Task_Interface_Context      |
                    Task_Private_Context        |
                    Protected_Body_Context      |
                    Protected_Interface_Context |
                    Protected_Private_Context   |
                    Record_Component_Context    =>
                  Unexpected;
            end case;
         when When_Word =>
            case Kind_Of is
               when Code_Block_Context                |
                    Generic_Formal_Parameters_Context |
                    Library_Unit_Context              |
                    Package_Interface_Context         |
                    Package_Private_Context           |
                    Task_Interface_Context            |
                    Task_Private_Context              |
                    Protected_Body_Context            |
                    Protected_Interface_Context       |
                    Protected_Private_Context         =>
                  Unexpected;
               when Record_Component_Context =>
                  exit;
            end case;
         when No_Reserved_Word =>
            case Kind_Of is
               when Code_Block_Context                |
                    Generic_Formal_Parameters_Context |
                    Package_Interface_Context         |
                    Package_Private_Context           |
                    Protected_Private_Context         |
                    Record_Component_Context          =>
                  Push (Context, Get_Object_Declaration);
                  Enclosing.After := Enclosing.After + 1;
               when Library_Unit_Context =>
                  if Enclosing.After = 0 and then End_Of (Code) then
                     Raise_Exception
                     (  End_Error'Identity,
                        "No compilation unit found before the file end"
                     );
                  else
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "A compilation unit is expected at " &
                        Image (Link (Code))
                     );
                  end if;
               when Task_Interface_Context |
                    Task_Private_Context   =>
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "A task item declaration is expected at " &
                     Image (Link (Code))
                  );
               when Protected_Body_Context      |
                    Protected_Interface_Context =>
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "A protected operation is expected at " &
                     Image (Link (Code))
                  );
            end case;
         when others =>
            Unexpected;
      end case;
      Get_Blank (Context, Code);
   end loop;
   if Kind_Of = Record_Component_Context and then
      not Null_Record                    and then
      Pragmas_Count >= Enclosing.After       then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "No record member declarations found before " &
         "'end' at "                                   &
         Image (Before (Code))
      );
   end if;
   case Kind_Of is
      when Generic_Formal_Parameters_Context |
           Library_Unit_Context              =>
         null;
      when Code_Block_Context                |
           Package_Interface_Context         |
           Package_Private_Context           |
           Task_Interface_Context            |
           Task_Private_Context              |
           Protected_Body_Context            |
           Protected_Interface_Context       |
           Protected_Private_Context         |
           Record_Component_Context          =>
         null;
   end case;
   declare
      use Tokens.Arguments;
      type Arena_Ptr is access Declaration_Ptr_Array;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      This  : Declaration_Context renames Ptr.all;
      Items : constant Arena_Ptr :=
                   new Declaration_Ptr_Array (1..Enclosing.After);
      List : Frame (1..1);
   begin
      This.Declarations := Items.all'Unchecked_Access;
      for Index in reverse Items'Range loop
         Pop (Context, List);
         Items (Index) :=
            Declaration_Node'Class
            (  List (1).Value.all
            ) 'Unchecked_Access;
      end loop;
      if Last_Use_Clause /= null then
         This.Last_Use_Clause := Last_Use_Clause.all'Unchecked_Access;
      end if;
      This.Location := This.Location & Before (Code);
      This.Scope    := This.Location;
      This.File     := File;
   end;
end Get_Context;
