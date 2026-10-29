--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Context.Get_Type                     Spring, 2026       --
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

with Parsers.Ada_Syntax_Analyzer.Declarations.Types;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Types;

separate (Parsers.Ada_Syntax_Analyzer.Get_Context)
   function Get_Type return Tokens.Argument_Token is

   Start         : constant Location := Before (Code);
   Result        : Tokens.Argument_Token;
   Name          : Tokens.Argument_Token;
   Discriminants : Parameter_Profile_Ref;
   Keyword       : Reserved_Word;

   procedure Get_Access (Not_Null : Boolean) is
   begin
      if Discriminants /= null then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Access type is not alloved to have " &
            "discriminants found at "             &
            Image (Discriminants.Location)
         );
      end if;
      declare
         Definition : constant Anonymous_Access_Definition :=
                               Get_Anonymous_Access_Definition
                               (  Context   => Context'Access,
                                  Code      => Code'Access,
                                  File      => File,
                                  Not_Null  => Not_Null,
                                  Parent    => Enclosing,
                                  To_Object => True
                               );
      begin
         declare
            type Arena_Ptr is access Access_Type_Declaration;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Access_Type_Declaration
                            (  Mode          => Definition.Mode,
                               Aspects_Count => Get_Aspects_Count
                            );
            This : Access_Type_Declaration renames Ptr.all;
         begin
            Set
            (  Context,
               Name,
               Enclosing,
               File,
               This,
               This.Name'Access
            );
            This.Pointer := Definition;
            Add_Outer (This.Pointer, This, Enclosing);
            Pop (Context, This.Aspects);
            Get_Semicolon (Context, Code);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Start & Link (Code);
            This.Location   := Result.Location;
         end;
      end;
   end Get_Access;

   procedure Get_Derived_Type
             (  Abstract_Type : Boolean;
                Mode          : Derived_Interface_Type
             )  is
      Not_Null         : Boolean := False;
      Extension_Record : Boolean := False;
      Aspects_Count    : Natural := 0;
      Parent_Type      : Subtype_Indication;
      Private_Unit     : Boolean;
      Interfaces_Count : Natural;
      Extension        : Declaration_Context_Ref;
   begin
      Get_Subtype_Indication
      (  Context   => Context,
         Code      => Code,
         Composite => True,
         Not_Null  => Not_Null,
         Argument  => Parent_Type
      );
      if Mode = Synchronized_Interface then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Derived type cannot be synchronized as found at " &
            Image (Link (Code))
         );
      end if;
      case Parent_Type.Mode is
         when Subtype_Mode | Subtype_Range_Mode =>
            null;
         when Range_Mode =>
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Illegal derived type parent is a range at " &
               Image (Start & Link (Code))
            );
         when Unconstrained_Mode =>
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Illegal derived type parent is an unconstrained " &
               "range at "                                        &
               Image (Start & Link (Code))
            );
      end case;
      Interfaces_Count :=
         Get_Interfaces_List (Context'Access, Code'Access, "and");
      if Interfaces_Count > 0 and then not Get ("with") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'and' or 'with' is expected at " & Image (Link (Code))
         );
      end if;
      if Interfaces_Count > 0 or else Get ("with") then
         if Get ("private") then
            declare
               type Arena_Ptr is
                  access Private_Extension_Type_Declaration;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr  : constant Arena_Ptr :=
                           new Private_Extension_Type_Declaration
                               (  Abstract_Type    => Abstract_Type,
                                  Mode             => Mode,
                                  Interfaces_Count => Interfaces_Count,
                                  Aspects_Count    => Get_Aspects_Count
                               );
               This : Private_Extension_Type_Declaration renames
                      Ptr.all;
            begin
               Set
               (  Context,
                  Name,
                  Enclosing,
                  File,
                  This,
                  This.Name'Access
               );
               This.Parent_Type := Parent_Type;
               if Discriminants /= null then
                  Discriminants.Outer := This'Unchecked_Access;
                  This.Discriminants :=
                     Discriminants.all'Unchecked_Access;
               end if;
               Pop (Context, This.Aspects);
               Pop (Context, This.Interfaces);
               Get_Semicolon (Context, Code);
               Result.Value    := This'Unchecked_Access;
               Result.Location := Start & Link (Code);
               This.Location   := Result.Location;
            end;
            return;
         elsif Get ("null") then
            if not Get ("record") then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'record' is expected after 'null' at " &
                  Image (Link (Code))
               );
            end if;
            Extension_Record := True;
         elsif Get ("record") then
            if Discriminants /= null then
               Discriminants.Scope := Before (Code);
               Discriminants.File  := File;
            end if;
            Get_Context
            (  Context      => Context,
               Code         => Code,
               File         => File,
               Kind_Of      => Record_Component_Context,
               Parent       => Discriminants or Enclosing,
               Private_Unit => Private_Unit,
               Keyword      => Keyword,
               Result       => Extension
            );
            if Keyword /= End_Word then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'end record' is expected at " & Image (Link (Code))
               );
            end if;
            declare
               Ends : constant Location := Before (Code);
            begin
               if Discriminants /= null then
                  Add (Context, Discriminants.all, Ends, File);
               end if;
               if Extension /= null then
                  Add (Context, Extension.all, Ends, File);
               end if;
            end;
            if not Get ("record") then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'record' is expected after 'end' at " &
                  Image (Link (Code))
               );
            elsif not Has_Semicolon (Code) then
               Check (Context, Code, Name);
            end if;
            Extension_Record := True;
         else
            Get_Aspect (Context, Code, Aspects_Count);
         end if;
      end if;
      if Discriminants /= null and then not Extension_Record then
         case Parent_Type.Constraint.Mode is
            when No_Constraint           |
                 Index_Constraint        |
                 Discriminant_Constraint =>
               null;
            when Fixed_Point_Constraint =>
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "An anonymous fixed-point parent subtype "       &
                  "is not alloved to have discriminants found at " &
                  Image (Discriminants.Location)
               );
            when Floating_Point_Constraint =>
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "An anonymous floating-point parent subtype "    &
                  "is not alloved to have discriminants found at " &
                  Image (Start & Link (Code))
               );
            end case;
      end if;
      declare
         type Arena_Ptr is access Derived_Type_Declaration;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Ptr  : constant Arena_Ptr :=
                new Derived_Type_Declaration
                    (  Abstract_Type    => Abstract_Type,
                       Limited_Type     => Mode = Limited_Interface,
                       Extension_Record => Extension_Record,
                       Interfaces_Count => Interfaces_Count,
                       Aspects_Count    => Aspects_Count
                    );
         This : Derived_Type_Declaration renames Ptr.all;
      begin
         Set (Context, Name, Enclosing, File, This, This.Name'Access);
         This.Parent_Type   := Parent_Type;
         if Discriminants /= null then
            Discriminants.Outer := This'Unchecked_Access;
            This.Discriminants  := Discriminants.all'Unchecked_Access;
         end if;
         if This.Extension_Record and then Extension /= null then
            This.Extension := Extension.all'Unchecked_Access;
         end if;
         Pop (Context, This.Aspects);
         Pop (Context, This.Interfaces);
         Get_Semicolon (Context, Code);
         Result.Value    := This'Unchecked_Access;
         Result.Location := Start & Link (Code);
         This.Location   := Result.Location;
      end;
   end Get_Derived_Type;

   procedure Get_Incomplete_Type (Tagged_Type : Boolean) is
      type Arena_Ptr is access Incomplete_Type_Declaration;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Ptr  : constant Arena_Ptr :=
                  new Incomplete_Type_Declaration (Tagged_Type);
      This : Incomplete_Type_Declaration renames Ptr.all;
   begin
      Set (Context, Name, Enclosing, File, This, This.Name'Access);
      if Discriminants /= null then
         Discriminants.Outer := This'Unchecked_Access;
         This.Discriminants  := Discriminants.all'Unchecked_Access;
      end if;
      Get_Semicolon (Context, Code);
      Result.Value    := This'Unchecked_Access;
      Result.Location := Start & Link (Code);
      This.Location   := Result.Location;
   end Get_Incomplete_Type;

   procedure Get_Interface_Type (Mode : Interface_Type) is
      Interfaces_Count : constant Natural :=
                                  Get_Interfaces_List
                                  (  Context => Context'Access,
                                     Code    => Code'Access,
                                     Prefix  => "and"
                                  );
      type Arena_Ptr is access Interface_Type_Declaration;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Ptr  : constant Arena_Ptr :=
                  new Interface_Type_Declaration
                      (  Mode             => Mode,
                         Interfaces_Count => Interfaces_Count,
                         Aspects_Count    => Get_Aspects_Count
                      );
      This : Interface_Type_Declaration renames Ptr.all;
   begin
      Set (Context, Name, Enclosing, File, This, This.Name'Access);
      if Discriminants /= null then
         Discriminants.Outer := This'Unchecked_Access;
         This.Discriminants  := Discriminants.all'Unchecked_Access;
      end if;
      Pop (Context, This.Aspects);
      Pop (Context, This.Interfaces);
      Get_Semicolon (Context, Code);
      Result.Value    := This'Unchecked_Access;
      Result.Location := Start & Link (Code);
      This.Location   := Result.Location;
   end Get_Interface_Type;

   procedure Get_Null_Record_Type
             (  Abstract_Type : Boolean;
                Tagged_Type   : Boolean;
                Limited_Type  : Boolean
             )  is
   begin
      if not Get ("record") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'record' is expected after 'null' at " &
            Image (Link (Code))
         );
      end if;
      declare
         type Arena_Ptr is access Record_Type_Declaration;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Ptr  : constant Arena_Ptr :=
                     new Record_Type_Declaration
                         (  Abstract_Type => Abstract_Type,
                            Tagged_Type   => Tagged_Type,
                            Limited_Type  => Limited_Type,
                            Aspects_Count => Get_Aspects_Count
                         );
         This : Record_Type_Declaration renames Ptr.all;
      begin
         Set (Context, Name, Enclosing, File, This, This.Name'Access);
         if Discriminants /= null then
            Discriminants.Outer := This'Unchecked_Access;
            This.Discriminants  := Discriminants.all'Unchecked_Access;
         end if;
         Pop (Context, This.Aspects);
         Get_Semicolon (Context, Code);
         Result.Value    := This'Unchecked_Access;
         Result.Location := Start & Link (Code);
         This.Location   := Result.Location;
      end;
   end Get_Null_Record_Type;

   procedure Get_Private_Type
             (  Abstract_Type : Boolean;
                Tagged_Type   : Boolean;
                Limited_Type  : Boolean
             )  is
      type Arena_Ptr is access Private_Type_Declaration;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Ptr  : constant Arena_Ptr :=
                  new Private_Type_Declaration
                      (  Abstract_Type => Abstract_Type,
                         Tagged_Type   => Tagged_Type,
                         Limited_Type  => Limited_Type,
                         Aspects_Count => Get_Aspects_Count
                      );
      This : Private_Type_Declaration renames Ptr.all;
   begin
      Set (Context, Name, Enclosing, File, This, This.Name'Access);
      if Discriminants /= null then
         Discriminants.Outer := This'Unchecked_Access;
         This.Discriminants  := Discriminants.all'Unchecked_Access;
      end if;
      Pop (Context, This.Aspects);
      Get_Semicolon (Context, Code);
      Result.Value    := This'Unchecked_Access;
      Result.Location := Start & Link (Code);
      This.Location   := Result.Location;
   end Get_Private_Type;

   procedure Get_Range
             (  Result : out Tokens.Argument_Token;
                Got_It : out Boolean
             )  is
   begin
      Got_It := Get ("range");
      if Got_It then
         Lexers.Parse (Context, Code, Result);
         if Result.Value.all not in Expression then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "A values range is expected at " &
               Image (Result.Location)
            );
         elsif Expression (Result.Value.all).Operation /= Ellipsis then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'..' is expected in values range at " &
               Image (Expression (Result.Value.all).Location)
            );
         end if;
      end if;
   end Get_Range;

   procedure Get_Record_Type
             (  Abstract_Type : Boolean;
                Tagged_Type   : Boolean;
                Limited_Type  : Boolean
             )  is
      Private_Unit : Boolean;
      Components   : Declaration_Context_Ref;
   begin
      Get_Context
      (  Context      => Context,
         Code         => Code,
         File         => File,
         Kind_Of      => Record_Component_Context,
         Parent       => Discriminants or Enclosing,
         Private_Unit => Private_Unit,
         Keyword      => Keyword,
         Result       => Components
      );
      if Keyword /= End_Word then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'end record' is expected at " & Image (Link (Code))
         );
      end if;
      Add (Context, Components.all, Components.Scope, File);
      if not Get ("record") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'record' is expected after 'end' at " & Image (Link (Code))
         );
      end if;
      declare
         type Arena_Ptr is access Record_Type_Declaration;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Ptr  : constant Arena_Ptr :=
                     new Record_Type_Declaration
                         (  Abstract_Type => Abstract_Type,
                            Tagged_Type   => Tagged_Type,
                            Limited_Type  => Limited_Type,
                            Aspects_Count => Get_Aspects_Count
                         );
         This : Record_Type_Declaration renames Ptr.all;
      begin
         if not Has_Semicolon (Code) then
            Check (Context, Code, Name);
         end if;
         Set (Context, Name, Enclosing, File, This, This.Name'Access);
         if Discriminants /= null then
            Discriminants.Outer := This'Unchecked_Access;
            This.Discriminants  := Discriminants.all'Unchecked_Access;
         end if;
         This.Components := Components.all'Unchecked_Access;
         Pop (Context, This.Aspects);
         Get_Semicolon (Context, Code);
         Result.Value    := This'Unchecked_Access;
         Result.Location := Start & Link (Code);
         This.Location   := Result.Location;
      end;
   end Get_Record_Type;

begin
   Get_Simple_Name (Context, Code, True, Name);
   Get_Blank (Context, Code);
   Discriminants := Get_Procedure_Profile
                    (  Context   => Context'Access,
                       Code      => Code'Access,
                       File      => File,
                       Parent    => Enclosing,
                       Unknown   => True,
                       No_Access => False,
                       Profile   => False
                    );
   if Get ("is") then
      if Get ("(", False) then -- Enumeration type definition
         if Discriminants /= null then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Enumeration type is not alloved to have " &
               "discriminant part as found at "           &
               Image (Discriminants.Location)
            );
         end if;
         declare
            Open_At : constant Location := Link (Code);
            Length  : Positive := 1;
         begin
            loop
               Get_Enumeration_Literal (Context, Code, Result);
               Push (Context, Result);
               exit when not Get (",", False);
               Length := Length + 1;
            end loop;
            if not Get (")", False) then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "')' matching '(' at "                  &
                  Image (Open_At)                         &
                  " is expected to end enumeration type " &
                  "definition at "                        &
                  Image (Link (Code))
               );
            end if;
            declare
               type Arena_Ptr is access Enumeration_Type_Declaration;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr  : constant Arena_Ptr :=
                           new Enumeration_Type_Declaration
                               (  List_Length   => Length,
                                  Aspects_Count => Get_Aspects_Count
                               );
               This : Enumeration_Type_Declaration renames Ptr.all;
            begin
               Set
               (  Context,
                  Name,
                  Enclosing,
                  File,
                  This,
                  This.Name'Access
               );
               Pop (Context, This.Aspects);
               Pop (Context, This.List);
               Get_Semicolon (Context, Code);
               Result.Value    := This'Unchecked_Access;
               Result.Location := Start & Link (Code);
               This.Location   := Result.Location;
            end;
         end;
      else
         Get_Reserved_Word (Code, Keyword);
         if Context.Trace /= null then
            Parsers.Multiline_Source.Location_Text_IO.Put_Line
            (  Code    => Code,
               File    => Context.Trace.all,
               Message => " ---type-------------------" &
                          Reserved_Word'Image (Keyword) &
                          " in "                        &
                          Image (Kind_Of)               &
                          Natural'Image (Get_Arguments_Count (Context))
            );
         end if;
         case Keyword is
            when Abstract_Word =>
               Get_Blank (Context, Code);
               Get_Reserved_Word (Code, Keyword);
               case Keyword is
                  when Limited_Word =>
                     if not Get ("new") then
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "'new' is expected after " &
                           "'abstract limited' at "   &
                           Image (Link (Code))
                        );
                     end if;
                     Get_Derived_Type (True, Limited_Interface);
                  when Synchronized_Word =>
                     if not Get ("new") then
                        Raise_Exception
                        (  Parsers.Syntax_Error'Identity,
                           "'new' is expected after "     &
                           "'abstract synchronized at "   &
                           Image (Link (Code))
                        );
                     end if;
                     Get_Derived_Type (True, Synchronized_Interface);
                  when New_Word =>
                     Get_Derived_Type (True, Any_Interface);
                  when Tagged_Word =>
                     Get_Blank (Context, Code);
                     Get_Reserved_Word (Code, Keyword);
                     if Context.Trace /= null then
                        Parsers.Multiline_Source.Location_Text_IO.
                        Put_Line
                        (  Code    => Code,
                           File    => Context.Trace.all,
                           Message => " ---type-abstract-tagged---" &
                                      Reserved_Word'Image (Keyword) &
                                      " in "                        &
                                      Image (Kind_Of)               &
                                      Natural'Image
                                      (  Get_Arguments_Count (Context)
                        )             );
                     end if;
                     case Keyword is
                        when Limited_Word =>
                           Get_Blank (Context, Code);
                           Get_Reserved_Word (Code, Keyword);
                           case Keyword is
                              when Null_Word =>
                                 Get_Null_Record_Type (True, True, True);
                              when Private_Word =>
                                 Get_Private_Type (True, True, True);
                              when Record_Word =>
                                 Get_Record_Type (True, True, True);
                              when others =>
                                 Raise_Exception
                                 (  Parsers.Syntax_Error'Identity,
                                    "'record', 'null record' or "  &
                                    "'private' is expected after " &
                                    "'abstract tagged at "         &
                                    Image (Link (Code))
                                 );
                           end case;
                        when Null_Word =>
                           Get_Null_Record_Type (True, True, False);
                        when Private_Word =>
                           Get_Private_Type (True, True, False);
                        when Record_Word =>
                           Get_Record_Type (True, True, False);
                        when others =>
                           Raise_Exception
                           (  Parsers.Syntax_Error'Identity,
                              "'limited', 'null record', 'private' or " &
                              "'record' is expected after "             &
                              "'abstract tagged' at "                   &
                              Image (Link (Code))
                           );
                     end case;
                  when others =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'limited', 'new', 'synchronized', 'tagged' is " &
                        "expected after 'abstract' at "                  &
                        Image (Link (Code))
                     );
               end case;
            when Access_Word =>
               Get_Access (Not_Null => False);
            when Array_Word =>
               if Discriminants /= null then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Array type is not alloved to have " &
                     "discriminants as found at "         &
                     Image (Discriminants.Location)
                  );
               end if;
               declare
                  Definition : constant Array_Type_Specification_Ptr :=
                                        Get_Array_Type_Definition
                                        (  Context => Context'Access,
                                           Code    => Code'Access,
                                           File    => File,
                                           Parent  => Enclosing
                                        );
                  type Arena_Ptr is access Array_Type_Declaration;
                  for Arena_Ptr'Storage_Pool use Context.Pool.all;
                  Ptr  : constant Arena_Ptr :=
                              new Array_Type_Declaration
                                  (  Aspects_Count => Get_Aspects_Count
                                  );
                  This : Array_Type_Declaration renames Ptr.all;
               begin
                  Set
                  (  Context,
                     Name,
                     Enclosing,
                     File,
                     This,
                     This.Name'Access
                  );
                  This.Definition := Definition;
                  Add_Outer (This.Definition.all, This, Enclosing);
                  Pop (Context, This.Aspects);
                  Get_Semicolon (Context, Code);
                  Result.Value    := This'Unchecked_Access;
                  Result.Location := Start & Link (Code);
                  This.Location   := Result.Location;
               end;
            when Delta_Word =>
               if Discriminants /= null then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Fixed-point type is not alloved to have " &
                     "discriminants found at "                  &
                     Image (Discriminants.Location)
                  );
               end if;
               declare
                  Delta_Value  : Tokens.Argument_Token;
                  Digits_Value : Tokens.Argument_Token;
                  Constraint   : Tokens.Argument_Token;
                  Has_Digits   : Boolean;
                  Constrained  : Boolean;
               begin
                  Lexers.Parse (Context, Code, Delta_Value);
                  Has_Digits := Get ("digits");
                  if Has_Digits then
                     Lexers.Parse (Context, Code, Digits_Value);
                  end if;
                  Get_Range (Constraint, Constrained);
                  if not Has_Digits and then not Constrained then
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "Range of the ordinary fixed-point type is " &
                        "axpected at "                               &
                        Image (Link (Code))
                     );
                  end if;
                  if Has_Digits then
                     declare
                        type Arena_Ptr is
                           access Decimal_Fixed_Point_Type_Declaration;
                        for Arena_Ptr'Storage_Pool
                           use Context.Pool.all;
                        Ptr  : constant Arena_Ptr :=
                               new Decimal_Fixed_Point_Type_Declaration
                                   (  Constrained   => Constrained,
                                      Aspects_Count => Get_Aspects_Count
                                   );
                        This : Decimal_Fixed_Point_Type_Declaration
                                  renames Ptr.all;
                     begin
                        Set
                        (  Context,
                           Name,
                           Enclosing,
                           File,
                           This,
                           This.Name'Access
                        );
                        if This.Constrained then
                           This.Constraint.Item := Constraint;
                        end if;
                        This.Delta_Value  := Delta_Value;
                        This.Digits_Value := Digits_Value;
                        Pop (Context, This.Aspects);
                        Get_Semicolon (Context, Code);
                        Result.Value    := This'Unchecked_Access;
                        Result.Location := Start & Link (Code);
                        This.Location   := Result.Location;
                     end;
                  else
                     declare
                        type Arena_Ptr is
                           access Ordinary_Fixed_Point_Type_Declaration;
                        for Arena_Ptr'Storage_Pool
                           use Context.Pool.all;
                        Ptr  : constant Arena_Ptr :=
                               new Ordinary_Fixed_Point_Type_Declaration
                                   (  Constrained   => Constrained,
                                      Aspects_Count => Get_Aspects_Count
                                   );
                        This : Ordinary_Fixed_Point_Type_Declaration
                                  renames Ptr.all;
                     begin
                        Set
                        (  Context,
                           Name,
                           Enclosing,
                           File,
                           This,
                           This.Name'Access
                        );
                        if This.Constrained then
                           This.Constraint.Item := Constraint;
                        end if;
                        This.Delta_Value := Delta_Value;
                        Pop (Context, This.Aspects);
                        Get_Semicolon (Context, Code);
                        Result.Value    := This'Unchecked_Access;
                        Result.Location := Start & Link (Code);
                        This.Location   := Result.Location;
                     end;
                  end if;
               end;
            when Digits_Word =>
               if Discriminants /= null then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Floating-point type is not alloved to have " &
                     "discriminants found at "                     &
                     Image (Discriminants.Location)
                  );
               end if;
               declare
                  Digits_Value : Tokens.Argument_Token;
                  Constraint   : Tokens.Argument_Token;
                  Constrained  : Boolean;
               begin
                  Lexers.Parse (Context, Code, Digits_Value);
                  Get_Range (Constraint, Constrained);
                  declare
                     type Arena_Ptr is
                        access Floating_Point_Type_Declaration;
                     for Arena_Ptr'Storage_Pool
                        use Context.Pool.all;
                     Ptr  : constant Arena_Ptr :=
                            new Floating_Point_Type_Declaration
                                (  Constrained   => Constrained,
                                   Aspects_Count => Get_Aspects_Count
                                );
                     This : Floating_Point_Type_Declaration
                               renames Ptr.all;
                  begin
                     Set
                     (  Context,
                        Name,
                        Enclosing,
                        File,
                        This,
                        This.Name'Access
                     );
                     This.Digits_Value := Digits_Value;
                     if This.Constrained then
                        This.Constraint.Item := Constraint;
                     end if;
                     Pop (Context, This.Aspects);
                     Get_Semicolon (Context, Code);
                     Result.Value    := This'Unchecked_Access;
                     Result.Location := Start & Link (Code);
                     This.Location   := Result.Location;
                  end;
               end;
            when Interface_Word =>
               Get_Interface_Type (Any_Interface);
            when Limited_Word =>
               Get_Blank (Context, Code);
               Get_Reserved_Word (Code, Keyword);
               if Context.Trace /= null then
                  Parsers.Multiline_Source.Location_Text_IO.
                  Put_Line
                  (  Code    => Code,
                     File    => Context.Trace.all,
                     Message => " ---type-limited-----------" &
                                Reserved_Word'Image (Keyword) &
                                " in "                        &
                                Image (Kind_Of)               &
                                Natural'Image
                                (  Get_Arguments_Count (Context)
                  )             );
               end if;
               case Keyword is
                  when Interface_Word =>
                     Get_Interface_Type (Limited_Interface);
                  when New_Word =>
                     Get_Derived_Type (False, Limited_Interface);
                  when Null_Word =>
                     Get_Null_Record_Type (False, False, True);
                  when Private_Word =>
                     Get_Private_Type (False, False, True);
                  when Record_Word =>
                     Get_Record_Type (False, False, True);
                  when others =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'new', 'null record', 'record' or 'private' " &
                        "is expected after 'limited' at "              &
                        Image (Link (Code))
                     );
               end case;
            when Mod_Word =>
               if Discriminants /= null then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Modular type is not alloved to have " &
                     "discriminants found at "              &
                     Image (Discriminants.Location)
                  );
               end if;
               declare
                  Modulus     : Tokens.Argument_Token;
                  Constraint  : Tokens.Argument_Token;
                  Constrained : Boolean;
               begin
                  Lexers.Parse (Context, Code, Modulus);
                  Get_Range (Constraint, Constrained);
                  declare
                     type Arena_Ptr is access Modular_Type_Declaration;
                     for Arena_Ptr'Storage_Pool
                        use Context.Pool.all;
                     Ptr  : constant Arena_Ptr :=
                            new Modular_Type_Declaration
                                (  Constrained   => Constrained,
                                   Aspects_Count => Get_Aspects_Count
                                );
                     This : Modular_Type_Declaration renames Ptr.all;
                  begin
                     Set
                     (  Context,
                        Name,
                        Enclosing,
                        File,
                        This,
                        This.Name'Access
                     );
                     if This.Constrained then
                        This.Constraint.Item := Constraint;
                     end if;
                     This.Modulus := Modulus;
                     Pop (Context, This.Aspects);
                     Get_Semicolon (Context, Code);
                     Result.Value    := This'Unchecked_Access;
                     Result.Location := Start & Link (Code);
                     This.Location   := Result.Location;
                  end;
               end;
            when New_Word =>
               Get_Derived_Type (False, Any_Interface);
            when Not_Word =>
               if not Get ("null") then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'null' is expected after 'not' is expected " &
                     Image (Link (Code))
                  );
               elsif not Get ("access") then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'access' is expected after 'not null' " &
                     "is expected at "                        &
                     Image (Link (Code))
                  );
               end if;
               Get_Access (Not_Null => True);
            when Private_Word =>
               Get_Private_Type (False, False, False);
            when Protected_Word =>
               if not Get ("interface") then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'interface' is expected after 'protected' at " &
                     Image (Link (Code))
                  );
               end if;
               Get_Interface_Type (Protected_Interface);
            when Range_Word =>
               if Discriminants /= null then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "Integer type is not alloved to have " &
                     "discriminants found at "              &
                     Image (Discriminants.Location)
                  );
               end if;
               declare
                  Constraint  : Tokens.Argument_Token;
                  Constrained : Boolean;
               begin
                  Reset_Pointer (Code);
                  Get_Range (Constraint, Constrained);
                  declare
                     type Arena_Ptr is
                        access Signed_Integer_Type_Declaration;
                     for Arena_Ptr'Storage_Pool
                        use Context.Pool.all;
                     Ptr  : constant Arena_Ptr :=
                            new Signed_Integer_Type_Declaration
                                (  Aspects_Count => Get_Aspects_Count
                                );
                     This : Signed_Integer_Type_Declaration
                               renames Ptr.all;
                  begin
                     Set
                     (  Context,
                        Name,
                        Enclosing,
                        File,
                        This,
                        This.Name'Access
                     );
                     This.Constraint.Item := Constraint;
                     Pop (Context, This.Aspects);
                     Get_Semicolon (Context, Code);
                     Result.Value    := This'Unchecked_Access;
                     Result.Location := Start & Link (Code);
                     This.Location   := Result.Location;
                  end;
               end;
            when Null_Word =>
               Get_Null_Record_Type (False, False, False);
            when Record_Word =>
               Get_Record_Type (False, False, False);
            when Synchronized_Word =>
               Get_Blank (Context, Code);
               Get_Reserved_Word (Code, Keyword);
               if Context.Trace /= null then
                  Parsers.Multiline_Source.Location_Text_IO.
                  Put_Line
                  (  Code    => Code,
                     File    => Context.Trace.all,
                     Message => " ---type-synchronized------" &
                                Reserved_Word'Image (Keyword) &
                                " in "                        &
                                Image (Kind_Of)               &
                                Natural'Image
                                (  Get_Arguments_Count (Context)
                  )             );
               end if;
               case Keyword is
                  when New_Word =>
                     Get_Derived_Type (False, Synchronized_Interface);
                  when Interface_Word =>
                     Get_Interface_Type (Synchronized_Interface);
                  when others =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'interface' or 'new' is expected after " &
                        "'synchronized' at "                      &
                        Image (Link (Code))
                     );
               end case;
            when Tagged_Word =>
               Get_Blank (Context, Code);
               Get_Reserved_Word (Code, Keyword);
               if Context.Trace /= null then
                  Parsers.Multiline_Source.Location_Text_IO.
                  Put_Line
                  (  Code    => Code,
                     File    => Context.Trace.all,
                     Message => " ---type-tagged------------" &
                                Reserved_Word'Image (Keyword) &
                                " in "                        &
                                Image (Kind_Of)               &
                                Natural'Image
                                (  Get_Arguments_Count (Context)
                  )             );
               end if;
               case Keyword is
                  when Limited_Word =>
                     Get_Blank (Context, Code);
                     Get_Reserved_Word (Code, Keyword);
                     case Keyword is
                        when Record_Word =>
                           Get_Record_Type (False, True, True);
                        when Private_Word =>
                           Get_Private_Type (False, True, True);
                        when Null_Word =>
                           Get_Null_Record_Type (False, True, True);
                        when others =>
                           Raise_Exception
                           (  Parsers.Syntax_Error'Identity,
                              "'record' or 'private' is expected " &
                              "after 'tagged limited' at "         &
                              Image (Link (Code))
                           );
                     end case;
                  when Null_Word =>
                     Get_Null_Record_Type (False, True, False);
                  when Private_Word =>
                     Get_Private_Type (False, True, False);
                  when Record_Word =>
                     Get_Record_Type (False, True, False);
                  when No_Reserved_Word =>
                     Get_Incomplete_Type (True);
                  when others =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "'limited', 'null record', 'private' is " &
                        "expected after 'tagged' at "             &
                        Image (Link (Code))
                     );
               end case;
            when Task_Word =>
               if not Get ("interface") then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'interface' is expected after 'task' at " &
                     Image (Link (Code))
                  );
               end if;
               Get_Interface_Type (Task_Interface);
            when No_Reserved_Word =>
               Get_Incomplete_Type (False);
            when others =>
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "A type definition after 'is' is expected at " &
                  Image (Link (Code))
               );
         end case;
      end if;
   else
      Get_Incomplete_Type (False);
   end if;
   return Result;
end Get_Type;
