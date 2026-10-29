--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Parsers.Ada_Syntax_Analyzer.                Luebeck            --
--        Get_Sequence.Get_Exception               Spring, 2026       --
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
   function Get_Exception return Positive is

   type Exception_Handler_Ref is access Exception_Handler;
   for Exception_Handler_Ref'Storage_Pool use Context.Pool.all;

   Name          : Tokens.Argument_Token;
   Has_Parameter : Boolean := False;

   procedure Create_Alternative (Choices_Count : Natural) is
      use Tokens.Arguments;
      Handler   : constant Exception_Handler_Ref :=
                       new Exception_Handler
                           (  Has_Parameter => Has_Parameter,
                              Choices_Count => Choices_Count
                           );
      This     : Exception_Handler renames Handler.all;
      Actual   : Context_Location;
      Sequence : Statement_Sequence_Ref;
      List     : Frame (1..1);
   begin
      Pop (Context, This.Choices);
      if This.Has_Parameter then
         This.Parameter.Parent := Parent;
         Actual := Ref (This.Parameter'Access);
         Pop (Context, List);
         This.Parameter.Location := List (1).Location;
         Set
         (  Context  => Context,
            Name     => List (1),
            Location => Parent,
            File     => File,
            Node     => Handler.all,
            Item     => This.Parameter.Name'Access
         );
         This.Parameter.Scope := Link (Code);
         This.Parameter.File  := File;
      else
         Actual := Parent;
      end if;
      Get_Sequence
      (  Context   => Context,
         Code      => Code,
         File      => File,
         Parent    => Actual,
         Handled   => Handler_Sequence,
         Enclosing => Enclosing,
         Keyword   => Keyword,
         Result    => Sequence
      );
      if Sequence /= null then
         Sequence.Outer := This'Unchecked_Access;
         This.Sequence  := Statement_Sequence (Sequence.all)'Access;
      end if;
      if This.Has_Parameter then
         Add (Context, This.Parameter, Before (Code), File);
      end if;
      List (1).Value := Handler.all'Unchecked_Access;
      Push (Context, List (1));
   end Create_Alternative;

   procedure Get_Others is
      Others_At : constant Location := Link (Code);
   begin
      if not Get ("=>") then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "'=>' is expected after 'others' at " & Image (Link (Code))
         );
      end if;
      Create_Alternative (0);
      if Keyword = When_Word then
         Raise_Exception
         (  Parsers.Syntax_Error'Identity,
            "Others handler is not the last exception handler at " &
            Image (Others_At)
         );
      end if;
   end Get_Others;

begin
   for Alternative in Positive'Range loop
      Has_Parameter := False;
      if Get ("others") then
         Get_Others;
         return Alternative;
      end if;
      Get_Expanded_Name (Context, Code, True, Name);
      if not Get (":=", False) and then Get (":", False) then
         Has_Parameter := True;
         Check_Identifier (Name);
         Push (Context, Name); -- Push the choice parameter
         if Get ("others") then
            Get_Others;
            return Alternative;
         end if;
         Get_Expanded_Name (Context, Code, True, Name);
      end if;
      for Choices_Count in Positive'Range loop
         Push (Context, Name); -- Push the choice
         if Get ("=>", False) then
            Create_Alternative (Choices_Count);
            case Keyword is
               when End_Word =>
                  return Alternative;
               when When_Word =>
                  exit;
               when No_Reserved_Word =>
                  null;
               when others =>
                  Reset_Pointer (Code);
            end case;
               Raise_Exception
               (  Parsers.Syntax_Error'Identity,
                  "'|' or '=>' is expected at " &
                  Image (Link (Code))
               );
         end if;
         if not Get ("|", False) then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "'|' or '=>' is expected at " & Image (Link (Code))
            );
         end if;
         if Get ("others") then
            Raise_Exception
            (  Parsers.Syntax_Error'Identity,
               "The others choice is not the single choice at " &
               Image (Link (Code))
            );
         end if;
         Get_Expanded_Name (Context, Code, True, Name);
      end loop;
   end loop;
   return 1;
end Get_Exception;
