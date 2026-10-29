--                                                                    --
--  package                         Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Serialization.Restore.Get_Node           Summer, 2026       --
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

separate (Parsers.Ada_Syntax_Analyzer.Serialization.Restore)
   function Get_Node (Node_Type : Term_Class) return Node_Ptr is
    procedure Get (This : out Case_Expression) is
    begin
       This.Selector := Get (Parent);
       for Index in This.Alternatives'Range loop
          This.Alternatives (Index).Choice := Get (Parent);
          This.Alternatives (Index).Value  := Get (Parent);
       end loop;
       if This.Has_Others then
          This.Others_Alternative := Get (Parent);
       end if;
    end Get;

   Tag    : Integer;
   Result : Node_Ref;
begin
   if Trace /= null then
      Put (Trace.all, Prefix & Image (Offset));
      Put (Trace.all, Term_Class'Image (Node_Type));
      Put (Trace.all, Integer'Image (Term_Class'Pos (Node_Type)));
      New_Line (Trace.all);
   end if;
   case Node_Type is
      when Box_Choice_Term =>
         Result := new Box_Choice;
      when Target_Name_Term =>
         Result := new Target_Name;
      when Character_Literal_Term =>
         Tag := Get;
         Result := new Character_Literal (Tag / 2);
         Get_Named_Term (Result, Tag mod 2 /= 0);
      when Identifier_Term =>
         Tag := Get;
         Result := new Identifier (Tag / 2);
         Get_Named_Term (Result, Tag mod 2 /= 0);
      when Integer_Literal_Term =>
         Tag := Get;
         Result := new Integer_Literal (Tag / 2);
         Get_Numeric_Term (Result, Tag mod 2 /= 0);
      when Null_Aggregate_Term =>
         Result := new Null_Aggregate;
      when Real_Literal_Term =>
         Tag := Get;
         Result := new Real_Literal (Tag / 2);
         Get_Numeric_Term (Result, Tag mod 2 /= 0);
      when String_Literal_Term =>
         Tag := Get;
         Result := new String_Literal (Tag / 2);
         Get_Named_Term (Result, Tag mod 2 /= 0);
      when Universal_Boolean_Term =>
         Tag := Get;
         Result := new Universal_Boolean'(Value => Tag /= 0);
      when Universal_Integer_Term =>
         return Create (Get_Integer, Pool'Access);
      when Universal_Real_Term =>
         return Create (Get_Rational, Pool'Access);
      when Expression_Node_Term =>
         Tag := Get;
         Result := new Expression
                       (  Count     => Tag,
                          Operation => Get
                       );
         Get (Expression (Result.all).Operands, Parent);
      when Case_Node_Term =>
         Tag := Get;
         Result := new Case_Expression
                       (  Count      => Tag / 2,
                          Has_Others => Tag mod 2 /= 0
                       );
         Get (Case_Expression (Result.all));
      when Declare_Node_Term =>
         Result := new Declare_Expression (Count => Get);
         declare
            Item : Declare_Expression renames
                   Declare_Expression (Result.all);
         begin
            Item.Expression := Get (Parent);
            for Index in Item.Items'Range loop
               Tag := Get;
               Item.Items (Index).Value :=
                  Abstract_Declare_Item'Class
                  (  Get_Node (Term_Class'Val (Tag)).all
                  ) 'Unchecked_Access;
               Get (Item.Items (Index).Location);
            end loop;
         end;
      when Declare_Renaming_Item_Term =>
         Tag := Get;
         Result := new Declare_Renaming_Item
                       (  Has_Mark      => Tag mod 2 /= 0,
                          Aspects_Count => Tag / 2
                       );
         declare
            Item : Declare_Renaming_Item renames
                   Declare_Renaming_Item (Result.all);
         begin
            Item.Name   := Get (Parent);
            Item.Object := Get (Parent);
            if Item.Has_Mark then
               Item.Mark := Get (Parent);
            end if;
            Get (Item.Aspects);
         end;
      when Declare_Object_Item_Term =>
         Tag := Get;
         Result := new Declare_Object_Item
                       (  Array_Object  => Tag mod 2 /= 0,
                          Names_Count   => Tag / 2,
                          Aspects_Count => Get
                       );
         declare
            Item : Declare_Object_Item renames
                   Declare_Object_Item (Result.all);
         begin
            Item.Value := Get (Parent);
            Get (Item.Names, Parent);
            if Item.Array_Object then
               Item.Definition := Get (Parent);
            else
               Item.Object := Get (Parent);
            end if;
            Get (Item.Aspects);
         end;
      when For_Node_Term =>
         Tag := Get;
         Result :=
            new For_Expression
                (  Qualifier => For_Qualifier'Val
                                (  Tag mod For_Qualifier_Mod
                                ),
                   Options   => For_Optional'Val
                                (  Tag / For_Qualifier_Mod
                                ),
                   Aspects_Count => Get
                );
         declare
            Item : For_Expression renames
                   For_Expression (Result.all);
         begin
            Item.Identifier := Get (Parent);
            if 0 /= (Item.Options and For_Range) then
               Item.Range_Type := Get (Parent);
            end if;
            Item.Iterator   := Get (Parent);
            Item.Expression := Get (Parent);
            if 0 /= (Item.Options and For_Condition) then
               Item.Condition := Get (Parent);
            end if;
            if 0 /= (Item.Options and For_Key) then
               Item.Key := Get (Parent);
            end if;
            if 0 /= (Item.Options and For_Chunk) then
               Item.Chunk := Get (Parent);
            end if;
            Get (Item.Aspects, Parent);
         end;
      when If_Node_Term =>
         Tag := Get;
         Result := new If_Expression
                       (  Count    => Tag / 2,
                          Has_Else => Tag mod 2 /= 0
                       );
         declare
            Item : If_Expression renames
                   If_Expression (Result.all);
         begin
            Get (Item.Alternatives, Parent);
            if Item.Has_Else then
               Item.Else_Alternative := Get (Parent);
            end if;
         end;
      when Raise_Node_Term =>
         Tag := Get;
         Result := new Raise_Expression (Has_Message => 0 /= Tag);
         declare
            Item : Raise_Expression renames
                   Raise_Expression (Result.all);
         begin
            Item.Name := Get (Parent);
            if Item.Has_Message then
               Item.Message := Get (Parent);
            end if;
         end;
   end case;
   if Trace /= null then
      Put (Trace.all, Prefix & Image (Offset));
      Put (Trace.all, "= ");
      Put_Line (Trace.all, Image (Result.all));
   end if;
   return Result.all'Unchecked_Access;
end Get_Node;
