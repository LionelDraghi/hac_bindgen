--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Sequence.Get_Parallel_Chunk          Spring, 2026       --
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

separate (Parsers.Ada_Syntax_Analyzer.Get_Sequence)
   procedure Get_Parallel_Chunk
             (  Parent : in out Context_Location;
                Chunk  : out Chunk_Specification_Ref
             )  is
   type Chunk_Ref is access Chunk_Specification;
   for Chunk_Ref'Storage_Pool use Context.Pool.all;
   Result : Chunk_Ref;
begin
   if Get ("(", False) then
      declare
         Open_At : constant Location := Link (Code);
         Name    : Tokens.Argument_Token;
         Got_It  : Boolean;

         procedure Close is
         begin
            if not Get (")", False) then
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "')' matching '(' at "           &
                  Image (Open_At)                  &
                  " is expected to end the chunk " &
                  "specification at "              &
                  Image (Link (Code))
               );
            end if;
         end Close;

         procedure Get_Chunk_Identifier is
            Line    : Line_Ptr;
            Pointer : Integer;
            Last    : Integer;
         begin
            Get_Blank (Context, Code);
            Get_Line (Code, Line, Pointer, Last);
            if Pointer > Last then
               Got_It := False;
               return;
            end if;
            declare
               Index  : Integer := Pointer;
               Symbol : UTF8_Code_Point;
            begin
               Get (Line (Pointer..Last), Index, Symbol);
               if not Is_Identifier_Start (Symbol) then
                  Got_It := False;
                  return;
               end if;
            exception
               when Data_Error =>
                  Set_Pointer (Code, Pointer);
                  Set_Pointer (Code, Pointer);
                  Raise_Exception
                  (  Syntax_Error'Identity,
                     Encoding_Error & Image (Link (Code))
                  );
            end;
            Get_Identifier
            (  Context,
               Code,
               Line (Pointer..Last),
               Pointer,
               Name
            );
            Got_It := True;
         end Get_Chunk_Identifier;

      begin
         Get_Chunk_Identifier;
         if Got_It and then Get ("in") then
            Check_Identifier (Name);
            Result := new Chunk_Specification (Chunk_Parameter);
            declare
               Type_Of  : Subtype_Indication;
               Not_Null : Boolean := False;
            begin
               Get_Subtype_Indication
               (  Context   => Context,
                  Code      => Code,
                  Composite => False,
                  Not_Null  => Not_Null,
                  Argument  => Type_Of
               );
               Result.Name.Type_Of :=
                  (  Present            => True,
                     Aliased_Parameter  => False,
                     Constant_Parameter => False,
                     Mode               => Object_Mode,
                     Object_Parameter   => Type_Of
                  );
            end;
            Set
            (  Context,
               Name,
               Parent,
               File,
               Result.all,
               Result.Name.Name'Access
            );
            Result.Name.Location := Name.Location;
            Result.Name.Parent   := Parent;
            Parent               := Ref (Result.Name'Access);
            Close;
         else
            Result := new Chunk_Specification (Chunk_Expression);
            Lexers.Parse
            (  Context => Context,
               Code    => Code,
               Operand => Name,
               Result  => Result.Value
            );
            Close;
         end if;
      end;
   else
      Result := new Chunk_Specification (Chunk_Any);
   end if;
   Chunk  := Result.all'Unchecked_Access;
end Get_Parallel_Chunk;
