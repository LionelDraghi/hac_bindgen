--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Generic                              Spring, 2026       --
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
   procedure Get_Generic
             (  Context : in out Ada_Program;
                Code    : in out Source'Class;
                File    : Source_Description_Ptr;
                Parent  : Context_Location;
                Result  : out Tokens.Argument_Token
             )  is
   Keyword      : Reserved_Word;
   Private_Unit : Boolean;
   Formal_Part  : Declaration_Context_Ref;
begin
   Get_Context
   (  Context      => Context,
      Code         => Code,
      File         => File,
      Kind_Of      => Generic_Formal_Parameters_Context,
      Parent       => Parent,
      Private_Unit => Private_Unit,
      Keyword      => Keyword,
      Result       => Formal_Part
   );
   case Keyword is
      when Function_Word =>
         Get_Function
         (  Context      => Context,
            Code         => Code,
            File         => File,
            Parent       => Ref (Formal_Part),
            Separated    => (Separate_Body => False),
            Private_Unit => False,
            Generic_Unit => True,
            Overrides    => No_Indicator,
            Result       => Result
         );
      when Package_Word =>
         Get_Package
         (  Context      => Context,
            Code         => Code,
            File         => File,
            Parent       => Ref (Formal_Part),
            Separated    => (Separate_Body => False),
            Private_Unit => False,
            Generic_Unit => True,
            Result       => Result
         );
      when Procedure_Word =>
         Get_Procedure
         (  Context      => Context,
            Code         => Code,
            File         => File,
            Parent       => Ref (Formal_Part),
            Separated    => (Separate_Body => False),
            Private_Unit => False,
            Generic_Unit => True,
            Overrides    => No_Indicator,
            Result       => Result
         );
      when others =>
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'function', 'package' or 'procedure' is expected at " &
            Image (Link (Code))
         );
   end case;
   Add (Context, Formal_Part.all, Before (Code), File);
end Get_Generic;
