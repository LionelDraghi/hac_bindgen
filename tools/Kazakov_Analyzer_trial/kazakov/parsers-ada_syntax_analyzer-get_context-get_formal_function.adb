--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Context.Get_Formal_Function          Spring, 2026       --
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

with Parsers.Ada_Syntax_Analyzer.Declarations.Formal_Parameters;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Formal_Parameters;

separate (Parsers.Ada_Syntax_Analyzer.Get_Context)
   function Get_Formal_Function return Tokens.Argument_Token is
   use Object_Specification_Stack;

   Result            : Tokens.Argument_Token;
   Default           : Formal_Function_Default_Type := No_Default;
   Name              : Tokens.Argument_Token;
   Default_Name      : Tokens.Argument_Token;
   Profile           : Parameter_Profile_Ref;
   Abstract_Function : Boolean;
begin
   Result.Location := Before (Code);
   Get_Simple_Name (Context, Code, False, Name);
   Get_Blank (Context, Code);
   Profile := Get_Function_Profile
              (  Context => Context'Access,
                 Code    => Code'Access,
                 File    => File,
                 Parent  => Parent
              );
   if Get ("is") then
      Get_Blank (Context, Code);
      Abstract_Function := Get ("abstract");
      if Get ("<>", False) then
         Default := Box_Default;
      elsif not Has_Semicolon (Code) then
         Default := Name_Default;
         Lexers.Parse (Context, Code, Default_Name);
         Check_Name (Default_Name, False);
      end if;
   end if;
   declare
      type Arena_Ptr is access Formal_Function_Parameter;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Ptr   : constant Arena_Ptr :=
                   new Formal_Function_Parameter
                       (  Abstract_Subprogram => Abstract_Function,
                          Aspects_Count       => Get_Aspects_Count,
                          Default             => Default
                       );
      This  : Formal_Function_Parameter renames Ptr.all;
      Where : Location;
   begin
      if Profile /= null then
         Profile.Outer := This'Unchecked_Access;
         This.Profile  := Profile.all'Unchecked_Access;
      end if;
      Set (Context, Name, Enclosing, File, This, This.Name'Access);
      Pop (Context, This.Aspects);
      if This.Default = Name_Default then
         This.Default_Name := Default_Name;
      end if;
      Pop (Context, This.Result, Where);
      Get_Semicolon (Context, Code);
      Result.Value    := This'Unchecked_Access;
      Result.Location := Result.Location & Link (Code);
      This.Location   := Result.Location;
   end;
   return Result;
end Get_Formal_Function;
