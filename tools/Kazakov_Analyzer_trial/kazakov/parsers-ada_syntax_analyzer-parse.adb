--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Parse                                    Spring, 2026       --
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
   function Parse
            (  Context : access Ada_Program;
               Code    : access Source'Class;
               File    : Source_Description_Ptr := null
            )  return Tokens.Argument_Token is
   Program      : Ada_Program  renames Context.all;
   Input        : Source'Class renames Code.all;
   Private_Unit : Boolean;
   Keyword      : Reserved_Word;
   Unit_Context : Declaration_Context_Ref;
   Result       : Tokens.Argument_Token;
begin
   Mark (Program);
   Get_Context
   (  Context      => Program,
      Code         => Input,
      File         => File,
      Kind_Of      => Library_Unit_Context,
      Parent       => (null, 0),
      Private_Unit => Private_Unit,
      Keyword      => Keyword,
      Result       => Unit_Context
   );
   case Keyword is
      when Function_Word =>
         Get_Function
         (  Context      => Program,
            Code         => Input,
            File         => File,
            Parent       => Ref (Unit_Context),
            Separated    => (Separate_Body => False),
            Private_Unit => Private_Unit,
            Generic_Unit => False,
            Overrides    => No_Indicator,
            Result       => Result
         );
      when Generic_Word =>
         Get_Generic
         (  Context      => Program,
            Code         => Input,
            File         => File,
            Parent       => Ref (Unit_Context),
            Result       => Result
         );
      when Package_Word =>
         Get_Package
         (  Context      => Program,
            Code         => Input,
            File         => File,
            Parent       => Ref (Unit_Context),
            Separated    => (Separate_Body => False),
            Private_Unit => Private_Unit,
            Generic_Unit => False,
            Result       => Result
         );
      when Procedure_Word =>
         Get_Procedure
         (  Context      => Program,
            Code         => Input,
            File         => File,
            Parent       => Ref (Unit_Context),
            Separated    => (Separate_Body => False),
            Private_Unit => Private_Unit,
            Generic_Unit => False,
            Overrides    => No_Indicator,
            Result       => Result
         );
      when Separate_Word =>
         Get_Separate
         (  Context      => Program,
            File         => File,
            Code         => Input,
            Parent       => Ref (Unit_Context),
            Result       => Result
         );
      when others =>
         Raise_Exception
         (  Syntax_Error'Identity,
            "'function', 'generic', 'package', 'procedure', " &
            "'separate' is expected at "                      &
            Image (Link (Input))
         );
   end case;
   Add (Program, Unit_Context.all, Link (Input), File);
   Release (Program);
   return Result;
exception
   when End_Error =>
      Raise_Exception
      (  Syntax_Error'Identity,
         "File end is reached prematurely at " & Image (Link (Input))
      );
   when others =>
      Release (Program);
      raise;
end Parse;
