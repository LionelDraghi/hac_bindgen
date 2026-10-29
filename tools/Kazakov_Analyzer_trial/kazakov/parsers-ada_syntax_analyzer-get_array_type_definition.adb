--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Array_Type_Definition                Spring, 2026       --
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
   function Get_Array_Type_Definition
            (  Context : access Ada_Program;
               Code    : access Source'Class;
               File    : Source_Description_Ptr;
               Parent  : Context_Location
            )  return Array_Type_Specification_Ptr is
   type Specification_Ref is access Array_Type_Specification;
   for Specification_Ref'Storage_Pool use Context.Pool.all;

   Got_It     : Boolean;
   Is_Aliased : Boolean := True;
   Not_Null   : Boolean := False;
   Dimension  : Natural := 1;
   Result     : Specification_Ref;
begin
   Get_Ranges_List
   (  Context   => Context.all,
      Code      => Code.all,
      Prefix    => "(",
      Delimiter => ",",
      Suffix    => ")",
      Any_Name  => False,
      Count     => Dimension
   );
   Get_Blank (Context.all, Code.all);
   Get_Delimited (Code.all, "of", True, Got_It);
   if not Got_It then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'of' is expected at " & Image (Link (Code.all))
      );
   end if;
   Get_Blank (Context.all, Code.all);
   Get_Delimited (Code.all, "aliased", True, Is_Aliased);
   Get_Not_Null (Context.all, Code.all, Not_Null);
   Get_Blank (Context.all, Code.all);
   Get_Delimited (Code.all, "access", True, Got_It);
   if Got_It then
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
      begin
         Result := new Array_Type_Specification
                       (  Mode              => Item.Mode,
                          Dimension         => Dimension,
                          Aliased_Component => Is_Aliased
                       );
         declare
            This : Array_Type_Specification renames Result.all;
         begin
            Pop (Context.all, This.Indices);
            This.Access_Component := Item;
         end;
      end;
   else
      declare
         Object : Subtype_Indication;
      begin
         Get_Subtype_Indication
         (  Context   => Context.all,
            Code      => Code.all,
            Composite => True,
            Not_Null  => Not_Null,
            Argument  => Object
         );
         Result := new Array_Type_Specification
                       (  Mode              => Object_Mode,
                          Dimension         => Dimension,
                          Aliased_Component => Is_Aliased
                       );
         declare
            This : Array_Type_Specification renames Result.all;
         begin
            This.Object_Component := Object;
            Pop (Context.all, This.Indices);
         end;
      end;
   end if;
   return Result.all'Unchecked_Access;
end Get_Array_Type_Definition;
