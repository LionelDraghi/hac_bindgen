--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Context.Get_Variant_Part             Spring, 2026       --
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

separate (Parsers.Ada_Syntax_Analyzer.Get_Context)
   function Get_Variant_Part return Tokens.Argument_Token is
   Result             : Tokens.Argument_Token;
   Discriminant       : Tokens.Argument_Token;
   Private_Unit       : Boolean;
   Keyword            : Reserved_Word;
   Components         : Declaration_Context_Ref;
   Choice             : Subtype_Indication;
   Alternatives_Count : Positive := 1;
   Choices_Count      : Positive;
   Start              : constant Location := Link (Code);
begin
   Get_Simple_Name (Context, Code, True, Discriminant);
   if not Get ("is") then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'is' is expected after identifier at " &
         Image (Link (Code))
      );
   end if;
   if not Get ("when") then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'when' is expected after 'is' at " & Image (Link (Code))
      );
   end if;

Alternatives :
   loop
      Choices_Count   := 1;
      Result.Location := Link (Code);
      loop
         if Get ("others") then
            if Choices_Count > 1 then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Others choice is not the single choice at " &
                  Image (Link (Code))
               );
            elsif not Get ("=>") then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'=>' is expected after 'others' at " &
                  Image (Link (Code))
               );
            end if;
            Get_Context
            (  Context      => Context,
               Code         => Code,
               File         => File,
               Kind_Of      => Record_Component_Context,
               Parent       => Enclosing,
               Private_Unit => Private_Unit,
               Keyword      => Keyword,
               Result       => Components
            );
            if Keyword = When_Word then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Others choice is not the last choice at " &
                  Image (Link (Code))
               );
            elsif not Get ("case") then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'case' is expected after 'end' at " &
                  Image (Link (Code))
               );
            end if;
            declare
               type Arena_Ptr is access Variant_Part_Item;
               for Arena_Ptr'Storage_Pool use Context.Pool.all;
               Ptr  : constant Arena_Ptr :=
                           new Variant_Part_Item
                               (  Choices_Count => 0,
                                  Components    => Components
                               );
            begin
               Result.Value    := Ptr.all'Unchecked_Access;
               Result.Location := Result.Location & Link (Code);
               Ptr.Location    := Result.Location;
            end;
            Push (Context, Result);
            exit Alternatives;
         end if;
         Get_Range
         (  Context     => Context,
            Code        => Code,
            Constrained => True,
            Any_Name    => False,
            Argument    => Choice
         );
         Push (Context, Choice);
         exit when not Get ("|");
         Choices_Count := Choices_Count + 1;
      end loop;
      if not Get ("=>") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'|' or '=>' is expected at " & Image (Link (Code))
         );
      end if;
      Get_Context
      (  Context      => Context,
         Code         => Code,
         File         => File,
         Kind_Of      => Record_Component_Context,
         Parent       => Enclosing,
         Private_Unit => Private_Unit,
         Keyword      => Keyword,
         Result       => Components
      );
      declare
         type Arena_Ptr is access Variant_Part_Item;
         for Arena_Ptr'Storage_Pool use Context.Pool.all;
         Ptr  : constant Arena_Ptr :=
                     new Variant_Part_Item
                         (  Choices_Count => Choices_Count,
                            Components    => Components
                         );
         This : Variant_Part_Item renames Ptr.all;
      begin
         Pop (Context, This.Choices);
         Result.Value := This'Unchecked_Access;
      end;
      Push (Context, Result);
      if Keyword = End_Word then
         if not Get ("case") then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'case' is expected after 'end' at " &
               Image (Link (Code))
            );
         end if;
         exit Alternatives;
      end if;
      Alternatives_Count := Alternatives_Count + 1;
   end loop Alternatives;
   Add (Context, Components.all, Components.Scope, File);
   declare
      use Tokens.Arguments;
      type Arena_Ptr is access Variant_Part;
      for Arena_Ptr'Storage_Pool use Context.Pool.all;
      Ptr  : constant Arena_Ptr :=
                  new Variant_Part (Count => Alternatives_Count);
      This : Variant_Part renames Ptr.all;
      List : Frame (1..1);
   begin
      This.Discriminant := Discriminant;
      for Index in reverse This.Alternatives'Range loop
         Pop (Context, List);
         This.Alternatives (Index) :=
            Variant_Part_Item (List (1).Value.all)'Access;
      end loop;
      Get_Semicolon (Context, Code);
      Result.Value    := This'Unchecked_Access;
      Result.Location := Start & Link (Code);
      This.Location   := Result.Location;
   end;
   return Result;
end Get_Variant_Part;
