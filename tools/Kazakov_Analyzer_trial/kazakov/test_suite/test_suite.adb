--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Test_Suite                                  Luebeck            --
--  Main program                                   Spring, 2026       --
--                                                                    --
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

with Ada.Command_Line;             use Ada.Command_Line;
with Ada.Directories;              use Ada.Directories;
with Ada.Exceptions;               use Ada.Exceptions;
with Ada.Strings.Maps.Constants;   use Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded;        use Ada.Strings.Unbounded;
with Ada.Text_IO;                  use Ada.Text_IO;
with Strings_Edit.Integers;        use Strings_Edit;
with Parsers.Ada_Syntax_Analyzer;  use Parsers.Ada_Syntax_Analyzer;
with Parsers.Multiline_Source;     use Parsers.Multiline_Source;
with Storage_Streams;              use Storage_Streams;

with Parsers.Ada_Syntax_Analyzer.Text_IO;
use  Parsers.Ada_Syntax_Analyzer.Text_IO;

with Parsers.Ada_Syntax_Analyzer.Serialization;
use  Parsers.Ada_Syntax_Analyzer.Serialization;

with Parsers.Multiline_Source.Location_Text_IO;
use  Parsers.Multiline_Source.Location_Text_IO;

with Ada.Unchecked_Deallocation;
with Generic_Set;
with Parsers.Multiline_Source.Text_IO;
with Stack_Storage;
with Strings_Edit.Lexicographical_Order;

procedure Test_Suite is
   File_No    : Natural := 0;
   Exit_Error : exception;
   Stop_Error : exception;
   Test_Error : exception;

   procedure Check
             (  Xref   : Cross_Reference;
                Path_1 : Source_Description_Ptr;
                Path_2 : Source_Description_Ptr
             )  is
      function Image (Item : Source_Description_Ptr) return String is
      begin
         if Item = null then
            return "the test file";
         else
            return Image (Item.all);
         end if;
      end Image;

      Entry_1 : Context_Entry := Get_First (Xref);
      Entry_2 : Context_Entry;
   begin
      while Entry_1 /= No_Context loop
         declare
            Scope  : Location;
            File_1 : Source_Description_Ptr;
            File_2 : Source_Description_Ptr;
         begin
            Get_Scope (Entry_1, File_1, Scope);
            if File_1 = Path_1 then
               File_2 := Path_2;
            elsif File_1 = Path_2 then
               File_2 := Path_1;
            else
               Raise_Exception
               (  Data_Error'Identity,
                  Image (File_1) & " is unexpected in cross-reference"
               );
            end if;
            Entry_2 := Get (Xref, Scope, File_2);
            if Entry_2 = No_Context then
               Raise_Exception
               (  Data_Error'Identity,
                  "Context with the scope " &
                  Image (Scope)             &
                  " is not found in "       &
                  Image (File_2)
               );
            end if;
            if not Equal
                   (  Get_Context (Entry_1).all,
                      Get_Context (Entry_2).all
                   )  then
               Raise_Exception
               (  Data_Error'Identity,
                  "Inequal contexts with the scope " &
                  Image (Scope)                      &
                  " in "                             &
                  Image (Path_1)                     &
                  " and "                            &
                  Image (Path_2)
               );
            end if;
         end;
         Entry_1 := Get_Next (Entry_1);
      end loop;
   end Check;

   type Storage_Stream_Ptr is access Storage_Stream;
   procedure Free is
      new Ada.Unchecked_Deallocation
          (  Storage_Stream,
             Storage_Stream_Ptr
          );
   Storage    : Storage_Stream_Ptr := new Storage_Stream (40_000);
   Arena      : aliased Stack_Storage.Pool (2048, 128);
   Xref       : aliased Cross_Reference (Arena'Access);
   Context    : aliased Ada_Program
                        (  Arena'Access,
                           Xref'Unchecked_Access
                        );

   type Location_Array is array (Positive range <>) of Location;
   type Location_Place is record
      Context : Location; -- Definition of
      After   : Natural;
   end record;

   function "<" (Left, Right : Location_Place) return Boolean is
   begin
      return Left.Context < Right.Context
          or else
             (  Left.Context = Right.Context
             and then
                Left.After < Right.After
             );
   end "<";

   package Location_Places_Sets is
      new Generic_Set (Location_Place, (((1, 1), (1, 0)), 0));

   type Resolution is record
      Name  : Unbounded_String;
      Where : Location;
      List  : Location_Places_Sets.Set;
   end record;
   type Resulution_Array is array (Positive range <>) of Resolution;

   procedure Add (S : in out Unbounded_String; V : String) is
      From : Integer := V'First;
      To   : Integer;
   begin
      while From <= V'Last loop
         case V (From) is
            when '"' =>
               To := From + 1;
               while To <= V'Last and then V (To) /= '"' loop
                  To := To + 1;
               end loop;
               if To <= V'Last then
                  To := To + 1;
               end if;
               Append (S, V (From..To - 1));
            when ' ' =>
               To := From + 1;
               while To <= V'Last and then V (To) = ' ' loop
                  To := To + 1;
               end loop;
               if Length (S) > 0             and then
                  Element (S, Length (S)) /= ' ' then
                  Append (S, ' ');
               end if;
            when others =>
               To := From + 1;
               while To <= V'Last   and then
                     V (To) /= ' '  and then V (To) /= '"'
               loop
                  To := To + 1;
               end loop;
               Append (S, V (From..To - 1));
         end case;
         From := To;
      end loop;
   end Add;

   procedure Run_Test
             (  Code      : in out Parsers.Multiline_Source.
                                   Text_IO.Source;
                File_Name : String
             )  is
      Space   : constant String := (File_Name'Range => ' ');
      Stop    : Boolean;
      Line    : Line_Ptr;
      Pointer : Integer;
      Last    : Integer;
      Path    : aliased File_Path := (File_Name'Length, File_Name);
      Stub    : Tree_Stub (Context'Access);

      procedure File_Error (Message : String) is
      begin
         Raise_Exception
         (  Test_Error'Identity,
            File_Name & ": " & Message & " at " & Image (Link (Code))
         );
      end File_Error;

      procedure Get_Prefix is
      begin
         loop
            Get_Line (Code, Line, Pointer, Last);
            Get (Line (Pointer..Last), Pointer, SpaceAndTab);
            if not Is_Prefix ("--", Line (Pointer..Last), Pointer) then
               File_Error ("'--' is expected");
            end if;
            Pointer := Pointer + 2;
            Get (Line (Pointer..Last), Pointer, SpaceAndTab);
            exit when Pointer <= Last;
            Next_Line (Code);
         end loop;
         Set_Pointer (Code, Pointer);
      end Get_Prefix;

      procedure Get_Blank is
      begin
          loop
             Get_Line (Code, Line, Pointer, Last);
             Get (Line (Pointer..Last), Pointer, SpaceAndTab);
             exit when Pointer <= Last;
             Next_Line (Code);
             Get_Prefix;
          end loop;
          Set_Pointer (Code, Pointer);
      end Get_Blank;

      function Get (Text : String) return Boolean is
      begin
         Get_Blank;
         Set_Pointer (Code, Pointer);
         if Is_Prefix (Text, Line (Pointer..Last), Lower_Case_Map) then
            Pointer := Pointer + Text'Length;
            Get (Line (Pointer..Last), Pointer, SpaceAndTab);
            Set_Pointer (Code, Pointer);
            return True;
         else
            return False;
         end if;
      end Get;

      function Get return Integer is
         use Strings_Edit.Integers;
         Result : Integer;
      begin
         Get_Blank;
         Get_Line (Code, Line, Pointer, Last);
         Get
         (  Source  => Line (Pointer..Last),
            Pointer => Pointer,
            Value   => Result
         );
         Set_Pointer (Code, Pointer);
         return Result;
      exception
         when Constraint_Error | Data_Error | End_Error =>
            File_Error ("Integer is expected");
            return Result;
      end Get;

      function Get return Location is
         Result : Location;
      begin
         Get_Blank;
         Get
         (  Source  => Line (Pointer..Last),
            Pointer => Pointer,
            Value   => Result
         );
         Set_Pointer (Code, Pointer);
         return Result;
      exception
         when Constraint_Error | Data_Error | End_Error =>
            File_Error ("Source location is expected");
            return Result;
      end Get;

      function Get return Location_Array is
         This : Location;

         function Inner (Prefix : Location_Array)
            return Location_Array is
         begin
            This := Get;
            if Is_Prefix (",", Line (Pointer..Last)) then
               Pointer := Pointer + 1;
               Set_Pointer (Code, Pointer);
               return Inner (Prefix & This);
            else
               return Prefix & This;
            end if;
         end Inner;
      begin
         return Inner ((1..0 => This));
      end Get;

      function Get return Location_Places_Sets.Set is
         use Location_Places_Sets;
         Result : Set;
         This   : Location_Place;
      begin
         if not Get ("empty") then
            loop
               This.Context := Get;
               if not Get ("(") then
                  File_Error ("'(' is expected");
               end if;
               This.After := Get - 1;
               if not Get (")") then
                  File_Error ("')' is expected");
               end if;
               Add (Result, This);
               exit when not Get (",");
            end loop;
         end if;
         return Result;
      end Get;

      function Get return Resulution_Array is
         use Location_Places_Sets;
         This  : Resolution;
         Start : Integer;

         function Inner (Prefix : Resulution_Array)
            return Resulution_Array is
         begin
            Get_Blank;
            Start := Pointer;
            while Pointer <= Last loop
               exit when Line (Pointer) = ' ' or else
                         Line (Pointer) = Character'Val (9);
               Pointer := Pointer + 1;
            end loop;
            if Start = Pointer then
               File_Error ("name is expected");
            end if;
            This.Name :=
               To_Unbounded_String (Line (Start..Pointer - 1));
            Set_Pointer (Code, Pointer);
            if not Get ("at") then
               File_Error ("'at' is expected");
            end if;
            This.Where := Get;
            if not Get ("=") then
               File_Error ("'=' is expected");
            end if;
            This.List := Get;
            if Get ("find") then
               return Inner (Prefix & This);
            else
               return Prefix & This;
            end if;
         end Inner;
      begin
         if Get ("find") then
            return Inner ((1..0 => This));
         else
            return (1..0 => This);
         end if;
      end Get;

      function Get_Tree_Name return String is
      begin
         if Get ("tree") then
            if Get (":") then
               Get_Line (Code, Line, Pointer, Last);
               Get (Line (Pointer..Last), Pointer, SpaceAndTab);
               declare
                  Start : constant Integer := Pointer;
               begin
                  while Pointer <= Last                     and then
                        Line (Pointer) /= ' '               and then
                        Line (Pointer) /= Character'Val (9)
                  loop
                     Pointer := Pointer + 1;
                  end loop;
                  Set_Pointer (Code, Pointer);
                  if Pointer = Start then
                     File_Error ("':' is expected");
                  end if;
                  return Line (Start..Pointer - 1);
               end;
            elsif Get ("*") then
               return File_Name & ".tree";
            else
               File_Error ("':' or '*' is expected");
            end if;
         end if;
         return "";
      end Get_Tree_Name;

      procedure Compare
                (  Got, Expected : Unbounded_String;
                   Title         : String := "Parsed"
                )  is
         What : String := ">>>>>>>>>";
      begin
         if Got /= Expected then
            What (1..Title'Last) := Title;
            for I in 1..Length (Got) loop
               if Element (Got, I) /= Element (Expected, I) then
                  Put_Line
                  (  File_Name & ": " & What & "..." &
                     Slice (Got, I, Length (Got))
                  );
                  Put_Line
                  (  Space     & "  Expected>..." &
                     Slice (Expected, I, Length (Expected))
                  );
                  Put_Line
                  (  Space     & "  Matched>>" &
                     Slice (Got, 1, I - 1)     & "<<"
                  );
                  raise Exit_Error;
               elsif I = Length (Expected) then
                  Put_Line
                  (  File_Name & ": Unexpected>" &
                     Slice (Got, I + 1, Length (Got))
                  );
                  raise Exit_Error;
               end if;
            end loop;
            Put_Line
            (  File_Name & ": Unmatched>" &
               Slice
               (  Expected,
                  Length (Got) + 1,
                  Length (Expected)
            )  );
            raise Exit_Error;
         end if;
      end Compare;
   begin
      File_No := File_No + 1;
      Stop    := False;
      while not Stop loop
         Get_Prefix;
         Stop := Get ("!");
         if Get ("folding") then
            Set_Constant_Folding (Context, True);
         else
            Set_Constant_Folding (Context, False);
         end if;
         if Get ("failure") then
            if not Get (":") then
               File_Error ("':' is expected");
            end if;
            declare
               Message : constant String := Line (Pointer..Last);
               Result  : Ada_Expression_Parser.Tokens.Argument_Token;
            begin
               Next_Line (Code);
               Result := Parse (Context'Access, Code'Access);
               Put_Line
               (  File_Name                      &
                  ": Was expected to fail with>" &
                  Message
               );
               raise Exit_Error;
            exception
               when Error : Parsers.Syntax_Error =>
                  if Exception_Message (Error) /= Message then
                     Put_Line
                     (  File_Name         &
                        ": Failed with >" &
                        Exception_Message (Error)
                     );
                     Put_Line
                     (  Space             &
                        "  Expected was>" &
                        Message
                     );
                     raise Exit_Error;
                  end if;
            end;
            exit;
         elsif Get ("success") then
            if not Get (":") then
               File_Error ("':' is expected");
            end if;
            declare
               use Ada_Expression_Parser;
               Where       : constant Location_Array := Get;
               Tree_Name   : constant String         := Get_Tree_Name;
               Tree_File   : File_Type;
               To_Be_Found : Resulution_Array        := Get;
               Result      : Ada_Expression_Parser.
                                Argument_List (Where'Range);
               Expected    : Unbounded_String;
               Got         : Unbounded_String;
            begin
               if Tree_Name'Length > 0 then
                  Create (Tree_File, Out_File, Tree_Name);
               end if;
               Add (Expected, Line (Pointer..Last));
               loop
                  Next_Line (Code);
                  Get_Line (Code, Line, Pointer, Last);
                  Get (Line (Pointer..Last), Pointer, SpaceAndTab);
                  exit when not Is_Prefix ("--", Line (Pointer..Last));
                  Pointer := Pointer + 1;
                  Add (Expected, Line (Pointer + 1..Last));
               end loop;
               Trim (Expected, Ada.Strings.Right);
               for Index in Where'Range loop
                  Result (Index) := Parse (Context'Access, Code'Access);
                  if Result (Index).Location /= Where (Index) then
                     Put_Line
                     (  File_Name                       &
                        ": Parsed location "            &
                        Image (Result (Index).Location) &
                        " does not match expected "     &
                        Image (Where (Index))           &
                        " [unit"                        &
                        Integer'Image (Index)           &
                        "]"
                     );
                     raise Exit_Error;
                  end if;
                  if Index > Where'First then
                     Append (Got, " ");
                  end if;
                  Append
                  (  Got,
                     Ada_Expression_Parser.Image
                     (  Result (Index).Value.all
                  )  );
               end loop;
               Compare (Got, Expected);
               Put_Line ("Identifier           Locations");
               Put_Line ("----------           ---------");
               Put_Defining_Identifiers (Xref, 20);
               Put_Line ("Scopes         Defining identifiers context");
               Put_Line ("------         ----------------------------");
               Put_Contexts (Xref);
               for I in To_Be_Found'Range loop
                  declare
                     use Strings_Edit.Integers;
                     use Location_Places_Sets;
                     use Context_Location_Sets;
                     Have_Title : Boolean := False;
                     Expected   : Resolution renames To_Be_Found (I);
                     List       : Location_Places_Sets.Set renames
                                     Expected.List;
                     Got        : Context_Location_Sets.Set :=
                                     Find
                                     (  Xref,
                                        To_String (Expected.Name),
                                        Expected.Where
                                     );
                     procedure Title is
                     begin
                        if not Have_Title then
                           Have_Title := True;
                           Put (File_Name & ": Identifier ");
                           Put (To_String (Expected.Name));
                           Put (" at " & Image (Expected.Where));
                           Put_Line (":");
                        end if;
                     end Title;
                  begin
                     while not Is_Empty (Got) loop
                        declare
                           This  : constant Defining_Identifier_Ptr :=
                                            Get (Got, 1);
                           Index : constant Integer :=
                                   Find
                                   (  List,
                                      Location_Place'
                                      (  This.Declared.Context.Location,
                                         This.Declared.After
                                   )  );
                        begin
                           if Index > 0 then
                              Remove (List, Index);
                           else
                              declare
                                 This : constant Defining_Identifier_Ptr
                                              := Get (Got, 1);
                              begin
                                 Title;
                                 Put ("   unexpectedly found in ");
                                 Put
                                 (  Image
                                    (  This.Declared.Context.Location
                                 )  );
                                 Put ("(");
                                 Put (Image (This.Declared.After + 1));
                                 Put (") declared at ");
                                 Put_Line
                                 (  Image
                                    (  Get_Item
                                       (  This.Declared.Context.all,
                                          This.Declared.After + 1
                                       ) .Location
                                 )  );
                              end;
                           end if;
                           Remove (Got, 1);
                        end;
                     end loop;
                     while not Is_Empty (List) loop
                        declare
                           This : constant Location_Place :=
                                           Get (List, 1);
                        begin
                           Title;
                           Put ("   was not found in ");
                           Put (Image (This.Context));
                           Put ("(");
                           Put (Image (This.After + 1));
                           Put_Line (")");
                        end;
                        Remove (List, 1);
                     end loop;
                     if Have_Title then
                        raise Exit_Error;
                     end if;
                  end;
               end loop;
               for Index in Result'Range loop
                  Erase (Storage.all);
                  if not Equal
                         (  Result (Index),
                            Result (Index),
                            not (  Location_Independent
                                or Source_Independent
                         )      )
                  then
                     Put_Line
                     (  File_Name                           &
                        ": Self-equality test failed [unit" &
                        Integer'Image (Index)               &
                        "]"
                     );
                     raise Exit_Error;
                  end if;
                  Store
                  (  Stream => Storage.all,
                     Tree   => Result (Index),
                     Trace  => Get_Trace_File (Context),
                     Prefix => "<"
                  );
                  declare
                     Other : constant Tokens.Argument_Token :=
                             Restore
                             (  Stream => Storage,
                                Pool   => Context.Pool,
                                Trace  => Get_Trace_File (Context),
                                Prefix => ">",
                                Xref   => Xref'Unchecked_Access,
                                File   => Path'Unchecked_Access
                             );
                  begin
                     if not Equal
                            (  Result (Index),
                               Other,
                               not Source_Independent
                            )  then
                        Put_Line
                        (  File_Name                            &
                           ": Store->Restore test failed [unit" &
                           Integer'Image (Index)                &
                           "]"
                        );
                        raise Exit_Error;
                     end if;
                  exception
                     when Exit_Error =>
                        raise;
                     when Error : others =>
                        Put_Line
                        (  File_Name                 &
                           ": "                      &
                           Exception_Message (Error) &
                           " [unit"                  &
                           Integer'Image (Index)     &
                           "]"
                        );
                        raise Exit_Error;
                  end;
               end loop;
               if Is_Open (Tree_File) then
                  for Index in Where'Range loop
                     if Index > Where'First then
                        Put_Line
                        (  Tree_File,
                           "-------------------------------------------"
                        );
                     end if;
                     Put (Result (Index), Tree_File);
                  end loop;
                  Close (Tree_File);
               end if;
            exception
               when Error : Parsers.Syntax_Error =>
                  if Is_Open (Tree_File) then
                     Close (Tree_File);
                  end if;
                  Put_Line
                  (  File_Name                     &
                     ": Unexpectedly failed with>" &
                     Exception_Message (Error)
                  );
                  Put_Line (Code);
                  raise Exit_Error;
            end;
            exit;
         else
            Next_Line (Code);
         end if;
      end loop;
      Put_Line (File_Name & ": passed");
      if Stop then
         raise Stop_Error;
      end if;
   exception
      when Error : Test_Error =>
         Put_Line (Code, Message => Exception_Message (Error));
         raise Exit_Error;
      when End_Error =>
         Put_Line
         (  File_Name                &
            ": end of file reached " &
            Image (Link (Code))
         );
         raise Exit_Error;
      when Exit_Error | Stop_Error =>
         raise;
      when Error : others =>
         Put_Line
         (  File_Name           &
            ": fatal error at " &
            Image (Link (Code)) &
            ": "                &
            Exception_Information (Error)
         );
         raise Exit_Error;
   end Run_Test;

   Tests_Count : Natural := 0;

   procedure Test_File (Path : String) is
      File : aliased File_Type;
   begin
      Open (File, In_File, Path);
      declare
         Code : Parsers.Multiline_Source.Text_IO.
                Source (File'Access);
      begin
         Tests_Count := Tests_Count + 1;
         Run_Test (Code, Simple_Name (Path));
      end;
      Close (File);
   exception
      when others =>
         Close (File);
         raise;
   end Test_File;

   procedure Scan_Directory (Name : String) is
      procedure Do_File (Item : Directory_Entry_Type) is
      begin
         Test_File (Full_Name (Item));
      end Do_File;
   begin
      Search
      (  Directory => Name,
         Pattern   => "*.ada",
         Process   => Do_File'Access
      );
      Search
      (  Directory => Name,
         Pattern   => "*.adb",
         Process   => Do_File'Access
      );
      Search
      (  Directory => Name,
         Pattern   => "*.ads",
         Process   => Do_File'Access
      );
   exception
      when Ada.Text_IO.Name_Error =>
         Put_Line ("Invalid test directory: " & Name);
         raise Exit_Error;
   end Scan_Directory;

   procedure Do_Argument (Argument : String) is
      use Strings_Edit.Lexicographical_Order;
   begin
      if Equal = Ada_Expression_Parser.Compare (Argument, "trace") then
         Set_Trace_File (Context, Standard_Output);
      elsif Exists (Argument) then
         case Kind (Argument) is
            when Directory =>
               Scan_Directory (Argument);
            when Ordinary_File =>
               Test_File (Argument);
            when Special_File =>
               Put_Line (Argument & ": Ignoring a special file");
         end case;
      else
         Put_Line (Argument & ": does not exist");
         raise Exit_Error;
      end if;
   end Do_Argument;

begin
   if Argument_Count = 0 then
      Do_Argument ("tests");
   else
      for Index in 1..Argument_Count loop
         Do_Argument (Argument (Index));
      end loop;
   end if;
   Free (Storage);
   if Tests_Count = 0 then
       Put_Line ("No tests found");
       raise Exit_Error;
   end if;
   Set_Exit_Status (Success);
exception
   when Stop_Error =>
      Free (Storage);
      Set_Exit_Status (Success);
   when Exit_Error =>
      Free (Storage);
      Set_Exit_Status (Failure);
   when Error : others =>
      Put_Line ("Error: " & Exception_Information (Error));
      Free (Storage);
      Set_Exit_Status (Failure);
end Test_Suite;

