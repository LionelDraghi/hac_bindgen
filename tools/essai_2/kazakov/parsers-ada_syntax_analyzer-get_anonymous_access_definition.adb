--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Anonymous_Access_Definition          Spring, 2026       --
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
   function Get_Anonymous_Access_Definition
            (  Context   : access Ada_Program;
               Code      : access Source'Class;
               File      : Source_Description_Ptr;
               Not_Null  : Boolean;
               Parent    : Context_Location;
               To_Object : Boolean
            )  return Anonymous_Access_Definition is
   use Object_Specification_Stack;
   Keyword : Reserved_Word;
begin
   Get_Blank (Context.all, Code.all);
   Get_Reserved_Word (Code.all, Keyword);
   case Keyword is
      when All_Word =>
         if To_Object then
            declare
               Object          : Subtype_Indication;
               Not_Null_Object : Boolean := False;
            begin
               Get_Subtype_Indication
               (  Context   => Context.all,
                  Code      => Code.all,
                  Composite => True,
                  Not_Null  => Not_Null_Object,
                  Argument  => Object
               );
               return
               (  Mode     => Access_To_All,
                  Not_Null => Not_Null,
                  Object   => Object
               );
            end;
         end if;
      when Constant_Word =>
         declare
            Object          : Subtype_Indication;
            Not_Null_Object : Boolean := False;
         begin
            Get_Subtype_Indication
            (  Context   => Context.all,
               Code      => Code.all,
               Composite => True,
               Not_Null  => Not_Null_Object,
               Argument  => Object
            );
            return
            (  Mode     => Access_To_Constant,
               Not_Null => Not_Null,
               Object   => Object
            );
         end;
      when Protected_Word =>
         Get_Blank (Context.all, Code.all);
         Get_Reserved_Word (Code.all, Keyword);
         case Keyword is
            when Function_Word =>
               declare
                  Result : Object_Specification_Ptr;
                  Where  : Location;
               begin
                  Pop (Context.all, Result, Where);
                  return
                  (  Mode     => Access_To_Protected_Function,
                     Not_Null => Not_Null,
                     Result   => Result,
                     Profile  => Get_Function_Profile
                                 (  Context => Context,
                                    Code    => Code,
                                    File    => File,
                                    Parent  => Parent
                                 ) .all'Unchecked_Access
                  );
               end;
            when Procedure_Word =>
               return
               (  Mode     => Access_To_Protected_Procedure,
                  Not_Null => Not_Null,
                  Profile  => Get_Procedure_Profile
                              (  Context   => Context,
                                 Code      => Code,
                                 File      => File,
                                 Parent    => Parent,
                                 Unknown   => False,
                                 No_Access => False,
                                 Profile   => True
                              ) .all'Unchecked_Access
               );
            when others =>
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'function' or 'procedure' is expected " &
                  "after 'protected' at "                  &
                  Image (Link (Code.all))
               );
         end case;
      when Function_Word =>
         declare
            Result  : Object_Specification_Ptr;
            Where   : Location;
            Profile : constant Parameter_Profile_Ref :=
                               Get_Function_Profile
                               (  Context => Context,
                                  Code    => Code,
                                  File    => File,
                                  Parent  => Parent
                               );
         begin
            Pop (Context.all, Result, Where);
            return
            (  Mode     => Access_To_Function,
               Not_Null => Not_Null,
               Result   => Result,
               Profile  => Profile.all'Unchecked_Access
            );
         end;
      when Procedure_Word =>
         return
         (  Mode     => Access_To_Procedure,
            Not_Null => Not_Null,
            Profile  => Get_Procedure_Profile
                        (  Context   => Context,
                           Code      => Code,
                           File      => File,
                           Parent    => Parent,
                           Unknown   => False,
                           No_Access => False,
                           Profile   => True
                        ) .all'Unchecked_Access
         );
      when No_Reserved_Word =>
         declare
            Object          : Subtype_Indication;
            Not_Null_Object : Boolean := False;
         begin
            Get_Subtype_Indication
            (  Context   => Context.all,
               Code      => Code.all,
               Composite => True,
               Not_Null  => Not_Null_Object,
               Argument  => Object
            );
            return
            (  Mode     => Access_To_Variable,
               Not_Null => Not_Null,
               Object   => Object
            );
         end;
      when others =>
         null;
   end case;
   Raise_Exception
   (  Parsers.Syntax_Error'Identity,
      "Unexpected '"   &
      Image (Keyword)  &
      "' is found at " &
      Image (Link (Code.all))
   );
end Get_Anonymous_Access_Definition;
