--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Separate                             Spring, 2026       --
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
   procedure Get_Separate
             (  Context : in out Ada_Program;
                Code    : in out Source'Class;
                File    : Source_Description_Ptr;
                Parent  : Context_Location;
                Result  : out Tokens.Argument_Token
             )  is
   function Get (Text : String; Delimited : Boolean := True)
      return Boolean is
      pragma Inline (Get);
      Got_It : Boolean;
   begin
      Get_Blank (Context, Code);
      Get_Delimited (Code, Text, Delimited, Got_It);
      return Got_It;
   end Get;

   Keyword   : Reserved_Word;
   Separated : Parent_Unit (True);
begin
   if not Get ("(", False) then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'(' is expected after 'separate' at " &
         Image (Link (Code))
      );
   end if;
   declare
      Open_At   : constant Location := Link (Code);
   begin
      Get_Blank (Context, Code);
      Get_Expanded_Name (Context, Code, False, Separated.Parent);
      if not Get (")", False) then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "')' corresponding to '(' at " &
            Image (Open_At)                &
            "is expected at "              &
            Image (Link (Code))
         );
      end if;
   end;
   Get_Blank (Context, Code);
   Get_Reserved_Word (Code, Keyword);
   case Keyword is
      when Function_Word =>
         Get_Function
         (  Context      => Context,
            Code         => Code,
            File         => File,
            Parent       => Parent,
            Separated    => Separated,
            Private_Unit => False,
            Generic_Unit => False,
            Overrides    => No_Indicator,
            Result       => Result
         );
      when Package_Word =>
         Get_Package
         (  Context      => Context,
            Code         => Code,
            File         => File,
            Parent       => Parent,
            Separated    => Separated,
            Private_Unit => False,
            Generic_Unit => False,
            Result       => Result
         );
      when Procedure_Word =>
         Get_Procedure
         (  Context      => Context,
            Code         => Code,
            File         => File,
            Parent       => Parent,
            Separated    => Separated,
            Private_Unit => False,
            Generic_Unit => False,
            Overrides    => No_Indicator,
            Result       => Result
         );
      when Protected_Word =>
         Get_Protected
         (  Context      => Context,
            Code         => Code,
            File         => File,
            Parent       => Parent,
            Separated    => Separated,
            Result       => Result
         );
      when Task_Word =>
         Get_Task
         (  Context      => Context,
            Code         => Code,
            File         => File,
            Parent       => Parent,
            Separated    => Separated,
            Result       => Result
         );
      when No_Reserved_Word =>
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'function', 'package', 'procedure', 'protected', " &
            "'task' is expected after ')' at "                  &
            Image (Link (Code))
         );
      when others =>
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            ''' & Image (Keyword) & "' is unexpected after " &
            "')' at "                                        &
            Image (Link (Code))
         );
   end case;
end Get_Separate;
