--                                                                    --
--  package Parsers.                Copyright (c)  Dmitry A. Kazakov  --
--     Ada_Syntax_Analyzer.Serialization.Restore.  Luebeck            --
--     Get_Program_Node.Get_Declaration_Context    Summer, 2026       --
--  Separate body                                                     --
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

with Ada.Unchecked_Conversion;

with Strings_Edit.Integers;  use Strings_Edit.Integers;

separate (  Parsers.Ada_Syntax_Analyzer.Serialization.
            Restore.Get_Program_Node
         )
   function Get_Declaration_Context
            (  Parent : Context_Location;
               Tag    : Natural
            )  return Node_Ref is
   type Declaration_Ptr_Array_Ref is access Declaration_Ptr_Array;
   for Declaration_Ptr_Array_Ref'Storage_Pool use Pool;

   type Use_Clause_Ref is access all Use_Clause'Class;

   Length  : constant Natural :=
                      Tag / (2 * Compilation_Context_Type_Mod);
   Result  : constant Node_Ref :=
                  new Declaration_Context
                      (  Compilation_Context_Type'Val
                         (  (Tag / 2) mod Compilation_Context_Type_Mod
                      )  );
   This    : Declaration_Context renames
             Declaration_Context (Result.all);
   Context : constant Compilation_Context_Ptr := This'Unchecked_Access;
begin
   if Tag mod 2 /= 0 then
      This.Parent.Context :=
         Compilation_Context
         (  Get_Declaration_Context ((null, 0), Get).all
         ) 'Unchecked_Access;
      This.Parent.After := Get_Items_Number (This.Parent.Context.all);
   else
      This.Parent := Parent;
   end if;
   if Trace /= null then
      Put (Trace.all, Prefix & Image (Offset));
      Put_Line
      (  Trace.all,
         "Declaration_Context " &
         Image (This.Kind_Of)   &
         ", items "             &
         Image (Length)
      );
   end if;
   if Length > 0 then
      declare
         Ptr  : constant Declaration_Ptr_Array_Ref :=
                     new Declaration_Ptr_Array (1..Length);
         List : Declaration_Ptr_Array renames Ptr.all;
         Item : Node_Ref;
         Last : Use_Clause_Ref;
         Tag  : Natural;
      begin
         This.Declarations := Ptr.all'Unchecked_Access;
         for Index in List'Range loop
            Tag  := Get;
            Item := Get_Program_Node (Tag, (Context, Index - 1), null);
            List (Index) :=
               Declaration_Node (Item.all)'Unchecked_Access;
            if Item.all in Use_Clause'Class then
               declare
                  Clause : Use_Clause'Class renames
                           Use_Clause'Class (Item.all);
               begin
                  if Last /= null then
                     Clause.Previous := Last.all'Unchecked_Access;
                  end if;
                  Last := Clause'Unchecked_Access;
               end;
            end if;
         end loop;
         if Last /= null then
            This.Last_Use_Clause := Last.all'Unchecked_Access;
         end if;
      end;
   end if;
   Get (This.Location);
   Get (This.Scope);
   This.File := File;
   Add (This.Scope, This);
   return Result;
end Get_Declaration_Context;
