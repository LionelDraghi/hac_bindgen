--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Context.Get_Object_Declaration       Spring, 2026       --
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

with Parsers.Ada_Syntax_Analyzer.Declarations.Renamings;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Renamings;

separate (Parsers.Ada_Syntax_Analyzer.Get_Context)
   function Get_Object_Declaration return Tokens.Argument_Token is
   type Specification_Ptr is access Object_Specification;
   for Specification_Ptr'Storage_Pool use Context.Pool.all;

   Result      : Tokens.Argument_Token;
   Mode        : Mode_Type := Array_Mode;
   Immutable   : Boolean   := False;
   Is_Aliased  : Boolean   := False;
   Initialized : Boolean   := False;
   Count       : Positive  := 1;
   Object      : Specification_Ptr;
   Parameter   : Parameter_Type;
   Initial     : Tokens.Argument_Token;
   Aliased_At  : Location;
   Constant_At : Location;
   Mark_At     : Location;

   procedure Get_Renaming is
      Target : Tokens.Argument_Token;
   begin
      if Kind_Of = Generic_Formal_Parameters_Context then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "A formal object cannot be a renaming as found at " &
            Image (Link (Code))
         );
      elsif Count > 1 then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "More than one identifier is given in a renaming at " &
            Image (Link (Code))
         );
      end if;
      if Parameter.Present then
         if Parameter.Aliased_Parameter then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'aliased' is not allowed in renaming at " &
               Image (Aliased_At)
            );
         elsif Parameter.Constant_Parameter then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'constant' is not allowed in renaming at " &
               Image (Constant_At)
            );
         end if;
         case Parameter.Mode is
            when Object_Mode =>
               case Parameter.Object_Parameter.Mode is
                  when Subtype_Range_Mode =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "Range constraint is not allowed in " &
                        "renaming at "                        &
                        Image (Mark_At & Link (Code))
                     );
                  when Range_Mode =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "Range is not allowed in renaming at " &
                        Image (Mark_At & Link (Code))
                     );
                  when Subtype_Mode =>
                     null;
                  when Unconstrained_Mode =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "Unknown range is not allowed in " &
                        "renaming at "                     &
                        Image (Mark_At & Link (Code))
                     );
               end case;
               case Parameter.Object_Parameter.Constraint.Mode is
                  when Fixed_Point_Constraint =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "Fixed-point constraint is not allowed " &
                        "in renaming at "                        &
                        Image (Mark_At & Link (Code))
                     );
                  when Floating_Point_Constraint =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "Floating-point constraint is not allowed " &
                        "in renaming at "                           &
                        Image (Mark_At & Link (Code))
                     );
                  when Index_Constraint =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "Index constraint is not allowed " &
                        "in renaming at "                  &
                        Image (Mark_At & Link (Code))
                     );
                  when Discriminant_Constraint =>
                     Raise_Exception
                     (  Parsers.Syntax_Error'Identity,
                        "Discriminant constraint is not allowed " &
                        "in renaming at "                         &
                        Image (Mark_At & Link (Code))
                     );
                  when No_Constraint =>
                     null;
               end case;
            when Access_Mode =>
               null;
         end case;
      end if;
      Lexers.Parse (Context, Code, Target);
      Check_Object (Target);
      declare
         use Tokens.Arguments;
         type Arena_Ptr is access Object_Renaming;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Ptr  : constant Arena_Ptr :=
                     new Object_Renaming (Get_Aspects_Count);
         This : Object_Renaming renames Ptr.all;
         List : Frame (1..1);
      begin
         Pop (Context, This.Aspects);
         Pop (Context, List);
         Set
         (  Context,
            List (1),
            Enclosing,
            File,
            This,
            This.Name'Access
         );
         This.Target     := Target;
         This.Type_Of    := Parameter;
         Get_Semicolon (Context, Code);
         Result.Value    := This'Unchecked_Access;
         Result.Location := Result.Location & Link (Code);
         This.Location   := Result.Location;
      end;
   end Get_Renaming;
begin
   Result.Location := Link (Code);
   loop
      Get_Simple_Name (Context, Code, True, Result);
      Push (Context, Result);
      exit when not Get (",", False);
      Count := Count + 1;
   end loop;
   if Get ("renames") then
      Get_Renaming;
      return Result;
   elsif Get (":=", False) or else not Get (":", False) then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "':' is expected at " & Image (Link (Code))
      );
   end if;
   if Get ("exception") then
      if Kind_Of = Generic_Formal_Parameters_Context then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Formal exception parameter is not as found at " &
            Image (Link (Code))
         );
      end if;
      if Get ("renames") then
         if Count > 1 then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "More than one identifier is given in a renaming at " &
               Image (Link (Code))
            );
         end if;
         Lexers.Parse (Context, Code, Initial);
         declare
            use Tokens.Arguments;
            type Arena_Ptr is access Exception_Renaming;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Exception_Renaming (Get_Aspects_Count);
            This : Exception_Renaming renames Ptr.all;
            List : Frame (1..1);
         begin
            This.Target := Initial;
            Pop (Context, This.Aspects);
            Pop (Context, List);
            Set
            (  Context,
               List (1),
               Enclosing,
               File,
               This,
               This.Name'Access
            );
            Get_Semicolon (Context, Code);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Result.Location & Link (Code);
            This.Location   := Result.Location;
         end;
      else
         declare
            type Arena_Ptr is access Exception_Declaration;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Exception_Declaration
                            (  Count,
                               Get_Aspects_Count
                            );
            This : Exception_Declaration renames Ptr.all;
         begin
            Pop (Context, This.Aspects);
            Pop (Context, Enclosing, File, This, This.Names);
            Get_Semicolon (Context, Code);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Result.Location & Link (Code);
            This.Location   := Result.Location;
         end;
      end if;
   else
      if Kind_Of = Generic_Formal_Parameters_Context then
         if Get ("in") then
            if Get ("out") then
               Mode := Inout_Mode;
            else
               Mode := In_Mode;
            end if;
         elsif Get ("out") then
            Mode := Out_Mode;
         else
            Mode := In_Mode;
         end if;
      end if;
      if Get ("aliased") then
         Is_Aliased := True;
         Aliased_At := Link (Code);
      end if;
      if Get ("constant") then
         Immutable   := True;
         Constant_At := Link (Code);
      end if;
      if Get ("access") then
         if Kind_Of = Generic_Formal_Parameters_Context then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Null exclusion is not allowed for " &
               "formal access objects as found at " &
               Image (Link (Code))
            );
         end if;
         Reset_Pointer (Code);
         Mark_At := Link (Code);
         Parameter := Get_Parameter_Type
                      (  Context            => Context'Access,
                         Code               => Code'Access,
                         File               => File,
                         Parent             => Parent,
                         Composite          => True,
                         Aliased_Parameter  => Is_Aliased,
                         Constant_Parameter => Immutable
                      );
         if Get ("renames") then
            Get_Renaming;
            return Result;
         end if;
         Object := new Object_Specification (Parameter.Mode);
         Object.Pointer := Parameter.Access_Parameter;
         Initialized := Get (":=", False);
      elsif Get ("array") then
         case Kind_Of is
            when Record_Component_Context =>
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Record component cannot be "     &
                  "an anonymous array as found at " &
                  Image (Link (Code))
               );
            when Generic_Formal_Parameters_Context =>
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Generic formal object cannot be " &
                  "an anonymous array as found at "  &
                  Image (Link (Code))
               );
            when Protected_Private_Context =>
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Protected object component cannot be " &
                  "an anonymous array as found at "       &
                  Image (Link (Code))
               );
            when others =>
               null;
         end case;
         Object := new Object_Specification (Array_Mode);
         Object.Array_Object := Get_Array_Type_Definition
                                (  Context => Context'Access,
                                   Code    => Code'Access,
                                   File    => File,
                                   Parent  => Enclosing
                                );
         Initialized := Get (":=", False);
      elsif Get (":=") then
         if Kind_Of = Generic_Formal_Parameters_Context then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "Generic formal object cannot be " &
               "a number as found at "            &
               Image (Link (Code))
            );
         end if;
         Initialized := True;
         Object := new Object_Specification (Constant_Mode);
      elsif Kind_Of = Generic_Formal_Parameters_Context then
         declare
            Not_Null : Boolean;
         begin
            Get_Not_Null (Context, Code, Not_Null);
            Object := new Object_Specification (Mode);
            Get_Subtype_Mark
            (  Context  => Context,
               Code     => Code,
               No_Range => True,
               Not_Null => Not_Null,
               Mark     => Object.Result
            );
            Object.Not_Null := Not_Null;
         end;
         Initialized := Get (":=", False);
      else
         Mark_At := Link (Code);
         Parameter := Get_Parameter_Type
                      (  Context            => Context'Access,
                         Code               => Code'Access,
                         File               => File,
                         Parent             => Parent,
                         Composite          => True,
                         Aliased_Parameter  => Is_Aliased,
                         Constant_Parameter => Immutable
                      );
         if Get ("renames") then
            Get_Renaming;
            return Result;
         end if;
         Object := new Object_Specification (Parameter.Mode);
         Object.Variable := Parameter.Object_Parameter;
         Initialized := Get (":=", False);
      end if;
      if Initialized then
         Lexers.Parse (Context, Code, Initial);
      end if;
      declare
         type Arena_Ptr is access Object_Declaration;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Ptr  : constant Arena_Ptr :=
                new Object_Declaration
                    (  Count          => Count,
                       Immutable      => Immutable,
                       Initialized    => Initialized,
                       Aliased_Object => Is_Aliased,
                       Aspects_Count  => Get_Aspects_Count,
                       Definition     => Object.all'Unchecked_Access
                    );
         This : Object_Declaration renames Ptr.all;
      begin
         Add_Outer (This.Definition.all, This, Enclosing);
         if This.Initial.Present then
            This.Initial.Item := Initial;
         end if;
         Pop (Context, This.Aspects);
         Pop (Context, Enclosing, File, This, This.Names);
         Get_Semicolon (Context, Code);
         Result.Value    := This'Unchecked_Access;
         Result.Location := Result.Location & Link (Code);
         This.Location   := Result.Location;
      end;
   end if;
   return Result;
end Get_Object_Declaration;
