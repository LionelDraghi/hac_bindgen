--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Procedure_Profile                    Spring, 2026       --
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
--  executable, this unit does not by  itself  cause  the  Parametering  --
--  executable to be covered by the GNU General Public License. This  --
--  exception  does not however invalidate any other reasons why the  --
--  executable file might be covered by the GNU Public License.       --
--____________________________________________________________________--

with Ada.Unchecked_Conversion;

separate (Parsers.Ada_Syntax_Analyzer)
   function Get_Procedure_Profile
            (  Context   : access Ada_Program;
               Code      : access Source'Class;
               File      : Source_Description_Ptr;
               Parent    : Context_Location;
               Unknown   : Boolean;
               No_Access : Boolean;
               Profile   : Boolean;
               Start     : Parameter_Part := (Part => Parameter_Name)
            )  return Parameter_Profile_Ref is
   type Parameter_Profile_Ref is access Parameter_Profile;
   for Parameter_Profile_Ref'Storage_Pool use Context.Pool.all;

   type Parameter_Specification_Ref is access Parameter_Specification;
   for Parameter_Specification_Ref'Storage_Pool
      use Context.Pool.all;
   function Ref is new Ada.Unchecked_Conversion
                       (  Parameter_Specification_Ptr,
                          Parameter_Specification_Ref
                       );
   type Defining_Identifier_Ref is access Defining_Identifier;
   function Ref is new Ada.Unchecked_Conversion
                       (  Defining_Identifier_Ptr,
                          Defining_Identifier_Ref
                       );
   Program   : Ada_Program  renames Context.all;
   Input     : Source'Class renames Code.all;
   Parameter : Tokens.Argument_Token;

   function Get (Text : String; Delimited : Boolean := True)
      return Boolean is
      pragma Inline (Get);
      Got_It : Boolean;
   begin
      Get_Blank (Program, Input);
      Get_Delimited (Input, Text, Delimited, Got_It);
      return Got_It;
   end Get;

   function Get_Aspects_Count return Natural is
      Count  : Natural := 0;
   begin
      if Get ("with") then
         Get_Blank (Program, Input);
         Get_Aspect (Program, Input, Count);
      end if;
      return Count;
   end Get_Aspects_Count;

   function Get_Default (Mode : Parameter_Mode) return Boolean is
      Value : Tokens.Argument_Token;
   begin
      Parameter.Location := Parameter.Location & Link (Input);
      if Get (":=", False) then
         if Mode /= In_Mode then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "No default value is allowed for parameters in the " &
               Image (Mode)                                         &
               " mode at "                                          &
               Image (Link (Input))
            );
         end if;
         Lexers.Parse (Program, Input, Value);
         Parameter.Location := Parameter.Location & Link (Input);
         Push (Program, Value);
         Get_Blank (Program, Input);
         return True;
      else
         return False;
      end if;
   end Get_Default;

   Got_It : Boolean;
   Where  : Location;
   Length : Natural := 0;
begin
   case Start.Part is
      when Parameter_Name =>
         Get_Blank (Program, Input);
         Get_Delimited (Input, "(", False, Got_It);
         if not Got_It then
            return null;
         end if;
         Where := Link (Input);
      when Parameter_Comma | Parameter_Colon =>
         Where := Start.Name.Location;
   end case;
   Get_Delimited (Input, "<>)", False, Got_It);
   if Got_It then
      if Unknown then
         declare
            Result : constant Parameter_Profile_Ref :=
                          new Parameter_Profile (0);
            This   : Parameter_Profile renames Result.all;
         begin
            This.Parent   := Parent;
            This.Location := Link (Input);
            return Result.all'Unchecked_Access;
         end;
      else
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Unknown discriminant part is unexpectedly found at " &
            Image (Link (Input))
         );
      end if;
   end if;
   loop
      declare
         Specification : Parameter_Specification_Ref;
         Argument      : Tokens.Argument_Token;
         Not_Null      : Boolean  := False;
         Count         : Positive := 1; -- The names count
         procedure Get_List is
            pragma Inline (Get_List);
         begin
            loop
               Get_Simple_Name (Program, Input, True, Argument);
               Push (Program, Argument);
               Get_Blank (Program, Input);
               exit when not Get (",", False);
               Count := Count + 1;
            end loop;
            if Get (":=", False) or else not Get (":", False) then
               if Count > 1 then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "':' is expected after parameter " &
                     "names list at " &
                     Image (Link (Input))
                  );
               else
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "':' is expected after parameter name at " &
                     Image (Link (Input))
                  );
               end if;
            end if;
         end Get_List;
      begin
         Get_Blank (Program, Input);
         if Length = 0 then
            case Start.Part is
               when Parameter_Name | Parameter_Comma =>
                  if Start.Part = Parameter_Name then
                     Parameter.Location := Link (Input);
                  else
                     Parameter.Location := Start.Name.Location;
                     Push (Program, Start.Name);
                     Count := Count + 1;
                  end if;
                  Get_List;
               when Parameter_Colon =>
                  Parameter.Location := Start.Name.Location;
                  Push (Program, Start.Name);
            end case;
         else
            Parameter.Location := Link (Input);
            Get_List;
         end if;
         Get_Not_Null (Program, Input, Not_Null);
         if Get ("access") then
            if No_Access then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Access parameter is not allowed for " &
                  "task entries as found at "            &
                  Image (Link (Input))
               );
            end if;
            declare
               Item : constant Anonymous_Access_Definition :=
                               Get_Anonymous_Access_Definition
                               (  Context   => Context,
                                  Code      => Code,
                                  File      => File,
                                  Not_Null  => Not_Null,
                                  Parent    => Parent,
                                  To_Object => False
                               );
               Default : Boolean;
            begin
               Default := Get_Default (In_Mode);
               Specification :=
                  new Parameter_Specification
                      (  Mode              => Item.Mode,
                         Aliased_Parameter => False,
                         Defaulted         => Default,
                         Parameters_Count  => Count,
                         Aspects_Count     => Get_Aspects_Count
                      );
               declare
                  use Tokens.Arguments;
                  List : Frame (1..1);
                  This : Parameter_Specification renames
                         Specification.all;
               begin
                  Pop (Program, This.Aspects);
                  if Default then
                     Pop (Program, List);
                     This.Default.Item := List (1);
                  end if;
                  This.Pointer  := Item;
               end;
            end;
         else
            declare
               Aliased_Parameter : Boolean        := False;
               Mode              : Parameter_Mode := In_Mode;
            begin
               if not Not_Null then
                  Aliased_Parameter := Get ("aliased");
                  if Get ("in") then
                     if not Profile then
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "Unexpected 'in' mode is found in a " &
                           "discriminant specification at "      &
                           Image (Link (Input))
                        );
                     end if;
                     if Get ("out") then
                        Mode := Inout_Mode;
                     end if;
                  elsif Get ("out") then
                     if not Profile then
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "Unexpected 'out' mode is found in a " &
                           "discriminant specification at "       &
                           Image (Link (Input))
                        );
                     end if;
                     Mode := Out_Mode;
                  end if;
                  Get_Not_Null (Program, Input, Not_Null);
               end if;
               declare
                  Item    : Subtype_Mark;
                  Default : Boolean;
               begin
                  Get_Subtype_Mark
                  (  Context  => Program,
                     Code     => Input,
                     No_Range => True,
                     Not_Null => Not_Null,
                     Mark     => Item
                  );
                  Default := Get_Default (Mode);
                  Specification :=
                     new Parameter_Specification
                         (  Mode              => Mode,
                            Aliased_Parameter => Aliased_Parameter,
                            Defaulted         => Default,
                            Parameters_Count  => Count,
                            Aspects_Count     => Get_Aspects_Count
                         );
                  declare
                     use Tokens.Arguments;
                     List : Frame (1..1);
                     This : Parameter_Specification renames
                            Specification.all;
                  begin
                     This.Not_Null := Not_Null;
                     Pop (Program, This.Aspects);
                     if Default then
                        Pop (Program, List);
                        This.Default.Item := List (1);
                     end if;
                     This.Value := Item;
                  end;
               end;
            end;
         end if;
         declare
            use Tokens.Arguments;
            List : Frame (1..1);
            This : Parameter_Specification renames Specification.all;
         begin
            for Index in reverse This.Parameters'Range loop
               Pop (Program, List);
               This.Parameters (Index).Term := List (1);
               declare
                  Identifier : Defining_Identifier renames
                               This.Parameters (Index);
               begin
                  Identifier.Name :=
                     Named_Term (Identifier.Term.Value.all)'Access;
               end;
            end loop;
            Parameter.Location := Parameter.Location & Link (Input);
            This.Location := Parameter.Location;
         end;
         Push
         (  Program,
            Tokens.Argument_Token'
            (  Specification.all'Unchecked_Access,
               Parameter.Location
         )  );
      end;
      Length := Length + 1;
      Get_Blank (Program, Input);
      Get_Delimited (Input, ";", False, Got_It);
      exit when not Got_It;
      Get_Blank (Program, Input);
   end loop;
   Get_Delimited (Input, ")", False, Got_It);
   if not Got_It then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "Either ';' or closing ')' matching " &
         "'(' at "                             &
         Image (Where)                         &
         " is expected after a parameter at "  &
         Image (Link (Input))
      );
   end if;
   declare
      use Tokens.Arguments;
      Result  : constant Parameter_Profile_Ref :=
                     new Parameter_Profile (Length);
      Profile : Parameter_Profile renames Result.all;
      List    : Frame (1..1);
   begin
      Profile.Location := Where & Link (Input);
      Profile.Parent   := Parent;
      for Parameter in reverse Profile.List'Range loop
         Pop (Program, List);
         Profile.List (Parameter) :=
            Parameter_Specification
            (  List (1).Value.all
            ) 'Unchecked_Access;
         declare
            Item : Parameter_Specification renames
                   Ref (Profile.List (Parameter)).all;
         begin
            Item.Profile := Profile'Unchecked_Access;
            if Item.Mode in Access_Mode then
               Add_Outer
               (  Item.Pointer,
                  Item,
                  (Result.all'Unchecked_Access, Parameter - 1)
               );
            end if;
            for Index in Item.Parameters'Range loop
               declare
                  This : Defining_Identifier renames
                         Ref
                         (  Item.Parameters (Index)'Unchecked_Access
                         ) .all;
               begin
                  Set
                  (  Program,
                     This.Term,
                     (  Context => Profile'Unchecked_Access,
                        After   => Parameter - 1
                     ),
                     File,
                     Item,
                     This'Access
                  );
               end;
            end loop;
         end;
      end loop;
      return Profile'Unchecked_Access;
   end;
end Get_Procedure_Profile;
