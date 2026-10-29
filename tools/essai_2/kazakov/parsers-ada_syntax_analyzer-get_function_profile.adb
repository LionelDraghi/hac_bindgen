--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Function_Profile                     Spring, 2026       --
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
   function Get_Function_Profile
            (  Context : access Ada_Program;
               Code    : access Source'Class;
               File    : Source_Description_Ptr;
               Parent  : Context_Location
            )  return Parameter_Profile_Ref is
   use Object_Specification_Stack;

   Program  : Ada_Program  renames Context.all;
   Input    : Source'Class renames Code.all;
   Profile  : Parameter_Profile_Ref;
   Not_Null : Boolean;
   Got_It   : Boolean;
   Result   : Object_Specification_Ptr;
   Where    : Location;
begin
   Get_Blank (Program, Input);
   Where   := Link (Input);
   Profile := Get_Procedure_Profile
              (  Context   => Context,
                 Code      => Code,
                 File      => File,
                 Parent    => Parent,
                 Unknown   => False,
                 No_Access => False,
                 Profile   => True
              );
   Get_Blank (Program, Input);
   Get_Delimited (Input, "return", True, Got_It);
   if not Got_It then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'return' is expected after function parameter profile at " &
         Image (Link (Input))
      );
   end if;
   Get_Not_Null (Program, Input, Not_Null);
   Get_Blank (Program, Input);
   Get_Delimited (Input, "access", True, Got_It);
   if Got_It then
      declare
         type Ref is access Object_Specification;
         for Ref'Storage_Pool use Context.Pool.all;
         Ptr  : Ref;
         Item : constant Anonymous_Access_Definition :=
                         Get_Anonymous_Access_Definition
                         (  Context   => Context,
                            Code      => Code,
                            File      => File,
                            Not_Null  => Not_Null,
                            Parent    => Parent,
                            To_Object => False
                         );
      begin
          Ptr := new Object_Specification (Item.Mode);
          Ptr.Pointer := Item;
          Result := Ptr.all'Unchecked_Access;
      end;
   else
      declare
         Item : Subtype_Mark;
      begin
         Get_Subtype_Mark
         (  Context  => Program,
            Code     => Input,
            No_Range => True,
            Not_Null => Not_Null,
            Mark     => Item
         );
         Result := new Object_Specification'
                       (  Mode     => In_Mode,
                          Not_Null => Not_Null,
                          Result   => Item
                       );
      end;
   end if;
   Push (Program, Result, Where & Link (Input));
   return Profile;
end Get_Function_Profile;
