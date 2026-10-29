--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Context.Get_For_Clause               Spring, 2026       --
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
   function Get_For_Clause return Tokens.Argument_Token is
   Result         : Tokens.Argument_Token;
   Name           : Tokens.Argument_Token;
   Attribute      : Tokens.Argument_Token;
   Representation : Boolean := False;
   Start          : constant Location := Before (Code);
begin
   Get_Simple_Name (Context, Code, True, Name);
   if Get ("'", False) then
      Representation := True;
      Get_Simple_Name (Context, Code, True, Attribute);
   end if;
   if not Get ("use") then
      Raise_Exception
      (  Parsers.Syntax_Error'Identity,
         "'use' is expected at " & Image (Link (Code))
      );
   end if;
   if Representation then -- Representation for X'Attribute use
      declare
         Value : Tokens.Argument_Token;
      begin
         Lexers.Parse (Context, Code, Value);
         Get_Semicolon (Context, Code);
         Result.Location := Start & Link (Code);
         Result.Value    := new Attribute_Definition_Clause'
                                (  Name      => Name,
                                   Attribute => Attribute,
                                   Value     => Value,
                                   Location  => Result.Location
                                );
      end;
   elsif Get ("at") then -- At clause
      Lexers.Parse (Context, Code, Result);
      Get_Semicolon (Context, Code);
      Result.Location := Start & Link (Code);
      Result.Value    := new At_Clause'
                             (  Name     => Name,
                                Address  => Result,
                                Location => Result.Location
                             );
   elsif Get ("record") then -- Record representation clause
      declare
         Has_Modulus : constant Boolean := Get ("at");
         Modulus     : Tokens.Argument_Token;
         Item        : Tokens.Argument_Token;
         Count       : Natural := 0;
      begin
         if Has_Modulus then
            if not Get ("mod") then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'mod' is expected after 'at' at " &
                  Image (Link (Code))
               );
            end if;
            Lexers.Parse (Context, Code, Modulus);
            Get_Semicolon (Context, Code);
         end if;
         while not Get ("end") loop
            Count := Count + 1;
            Get_Simple_Name (Context, Code, True, Item);
            Push (Context, Item);
            if not Get ("at") then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'at' is expected at " & Image (Link (Code))
               );
            end if;
            Lexers.Parse (Context, Code, Item);
            Push (Context, Item);
            if not Get ("range") then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'range' is expected at " & Image (Link (Code))
               );
            end if;
            Lexers.Parse (Context, Code, Item);
            if Item.Value.all not in Expression then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "Bit range is expected at " & Image (Item.Location)
               );
            end if;
            declare
               This : Expression renames Expression (Item.Value.all);
            begin
               if This.Operation /= Ellipsis then
                  Raise_Exception
                  (  Parsers.Syntax_Error'Identity,
                     "'..' is expected at " & Image (This.Location)
                  );
               end if;
            end;
            Push (Context, Item);
            Get_Semicolon (Context, Code);
         end loop;
         if not Get ("record") then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'record' is expected after 'end' at " &
               Image (Link (Code))
            );
         end if;
         declare
            use Tokens.Arguments;
            type Arena_Ptr is access Record_Representation_Clause;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Record_Representation_Clause
                            (  Components_Count => Count,
                               Has_Modulus      => Has_Modulus
                            );
            This : Record_Representation_Clause renames Ptr.all;
            List : Frame (1..3);
         begin
            This.Name := Name;
            if This.Modulus.Present then
               This.Modulus.Item := Modulus;
            end if;
            for Index in reverse This.Components'Range loop
               Pop (Context, List);
               declare
                  Clause : Component_Clause renames
                           This.Components (Index);
               begin
                  Clause.Name      := List (1);
                  Clause.Position  := List (2);
                  Clause.Bit_Range := List (3);
               end;
            end loop;
            Get_Semicolon (Context, Code);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Start & Link (Code);
            This.Location   := Result.Location;
         end;
      end;
   elsif Get ("(", False) then -- Enumeration representation clause
      declare
         Open_At : constant Location := Link (Code);
         Count   : Positive := 1;
      begin
         loop
            Get_Enumeration_Literal (Context, Code, Result);
            if not Get ("=>",False) then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'=>' is expected at " & Image (Link (Code))
               );
            end if;
            Push (Context, Result);
            Lexers.Parse (Context, Code, Result);
            Push (Context, Result);
            exit when not Get (",", False);
            Count := Count + 1;
         end loop;
         if not Get (")", False) then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "')' matching '(' at "                           &
               Image (Open_At)                                  &
               " is expected to end the array indices list at " &
               Image (Link (Code))
            );
         end if;
         declare
            type Arena_Ptr is access Enumeration_Representation_Clause;
            for Arena_Ptr'Storage_Pool use Context.Pool.all;
            Ptr  : constant Arena_Ptr :=
                        new Enumeration_Representation_Clause (Count);
            This : Enumeration_Representation_Clause renames Ptr.all;
         begin
            Get_Semicolon (Context, Code);
            This.Name := Name;
            Pop (Context, This.Enumeration);
            Result.Value    := This'Unchecked_Access;
            Result.Location := Start & Link (Code);
            This.Location   := Result.Location;
         end;
      end;
   end if;
   return Result;
end Get_For_Clause;
