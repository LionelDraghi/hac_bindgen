--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer                 Luebeck            --
--        Text_IO                                  Summer, 2026       --
--  Implementation                                                         --
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

with Parsers.Ada_Syntax_Analyzer.Declarations;
use  Parsers.Ada_Syntax_Analyzer.Declarations;

with Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;
use  Parsers.Ada_Syntax_Analyzer.Declarations.Specifications;

with Strings_Edit.Integers;  use Strings_Edit.Integers;

package body Parsers.Ada_Syntax_Analyzer.Text_IO is

   Tab : constant := 8;

   function Get_Name (Name : String) return String is
   begin
      for Index in reverse Name'Range loop
         if Name (Index) = '.' then
            return Name;
         end if;
      end loop;
      return Name & ".txt";
   end Get_Name;

   procedure Put
             (  Tree   : Tokens.Argument_Token;
                Output : File_Type := Standard_Output;
                Prefix : String    := "";
                Nested : Nesting   := Top
             )  is separate;

   procedure Put
             (  Tree   : Tokens.Argument_Token;
                Name   : String;
                Prefix : String  := "";
                Nested : Nesting := Top
             )  is
      File   : constant String := Get_Name (Name);
      Output : File_Type;
   begin
      Create (Output, Out_File, File);
      begin
         Put (Tree, Output, Prefix, Nested);
         Close (Output);
      exception
         when others =>
            Close (Output);
            raise;
      end;
   end Put;

   procedure Put
             (  Destination : in out String;
                Pointer     : in out Integer;
                Item        : String
             )  is
   begin
      Strings_Edit.Put (Destination, Pointer, Item);
   end Put;

   procedure Put_Contexts (File : File_Type; Xref  : Cross_Reference) is
      procedure Put_Information (Context : Compilation_Context'Class) is
      begin
         if Context in Declaration_Context then
            declare
               This   : Declaration_Context renames
                        Declaration_Context (Context);
               Clause : Use_Clause_Ptr := This.Last_Use_Clause;
            begin
               Put (File, Image (This.Kind_Of));
               if Clause /= null then
                  Put (File, " (use clauses ");
                  loop
                     Put (File, Image (Clause.Enclosing.After + 1));
                     Clause := Clause.Previous;
                     exit when Clause = null;
                     Put (File, ", ");
                  end loop;
                  Put (File, ") ");
               end if;
            end;
         elsif Context in Parameter_Profile then
            Put (File, "parameter profile");
         elsif Context in Singleton_Parameter then
            Put (File, "identifier");
         elsif Context in Identifier_List then
            Put (File, "identifier list");
         end if;
         Put (File, " at " & Image (Context.Location) & " (");
         Put (File, Image (Get_Items_Number (Context)) & " items)");
      end Put_Information;

      Item     : Context_Entry := Get_First (Xref);
      Column   : Count;
      Source   : Source_Description_Ptr;
      Location : Parsers.Multiline_Source.Location;
   begin
      while Item /= No_Context loop
         Get_Scope (Item, Source, Location);
         Put (File, Image (File_Location'(Source, Location)));
         Column := Col (File) + Tab - Col (File) mod Tab;
         Set_Col (File, Column);
         declare
            This : Compilation_Context'Class renames
                   Get_Context (Item).all;
         begin
            Put_Information (This);
            New_Line (File);
            declare
               Parent : Context_Location := This.Parent;
            begin
               while Parent.Context /= null loop
                  Column := Column + 3;
                  Set_Col (File, Column);
                  if Get_Items_Number (Parent.Context.all) =
                     Parent.After
                  then -- Attached at the context end
                     Put (File, "after ");
                  else
                     Put
                     (  File,
                        "#" & Image (Parent.After + 1) & " in "
                     );
                  end if;
                  Put_Information (Parent.Context.all);
                  New_Line (File);
                  Parent := Parent.Context.Parent;
               end loop;
            end;
         end;
         Item := Get_Next (Item);
      end loop;
   end Put_Contexts;

   procedure Put_Contexts (Xref  : Cross_Reference) is
   begin
      Put_Contexts (Standard_Output, Xref);
   end Put_Contexts;

   procedure Put_Defining_Identifiers
             (  File  : File_Type;
                Xref  : Cross_Reference;
                Field : Output_Length := 50
             )  is
      This : Identifier_Entry := Get_First (Xref);
      Item : Defining_Identifier_Ptr;
   begin
      while This /= No_Identifier loop
         Put (File, Image (Get_Name (This), Field));
         Set_Col
         (  File,
            Count'Max (Count (Field) + 2, Col (File) + 1)
         );
         Item := Get_First (This);
         for Index in Positive'Range loop
            if Index > 1 then
               Put (File, ", ");
            end if;
            Put
            (  File,
               Image (File_Location'(Item.File, Item.Term.Location))
            );
            Item := Item.Next;
            exit when Item = null;
         end loop;
         New_Line (File);
         This := Get_Next (This);
      end loop;
   end Put_Defining_Identifiers;

   procedure Put_Defining_Identifiers
             (  Xref  : Cross_Reference;
                Field : Output_Length := 50
             )  is
   begin
      Put_Defining_Identifiers (Standard_Output, Xref, Field);
   end Put_Defining_Identifiers;

end Parsers.Ada_Syntax_Analyzer.Text_IO;
