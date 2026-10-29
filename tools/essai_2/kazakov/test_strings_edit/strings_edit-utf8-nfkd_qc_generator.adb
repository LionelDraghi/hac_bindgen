--                                                                    --
--  procedure                       Copyright (c)  Dmitry A. Kazakov  --
--     Strings_Edit.UTF8.NFKD_QC_Generator         Luebeck            --
--  NFKD_QC generation                             Winter, 2026       --
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
--
--  This  procedure  adjusts  Strings_Edit.UTF8.Mapping.adb according to
--  the file unicodedata.txt. It is used as follows:
--
--      Strings_Edit-UTF8-NFKD_QC_Generator <source-file> <data-file>
--
--   Here:
--
--      <source-file> is strings_edit.utf8.nfkd_qc.adb
--      <data-file>   is DerivedNormalizationProps.txt
--
--  The file UnicodeData.txt can be obtained from:
--
--     https://www.unicode.org/Public/UNIDATA/
--        DerivedNormalizationProps.txt
--
--  It is distributed by Unicode, Inc.
--
--     http://www.unicode.org
--
with Ada.Characters.Latin_1;  use Ada.Characters.Latin_1;
with Ada.Command_Line;        use Ada.Command_Line;
with Ada.Exceptions;          use Ada.Exceptions;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Ada.Text_IO;             use Ada.Text_IO;
with Strings_Edit.Quoted;     use Strings_Edit.Quoted;

with Strings_Edit.Integer_Edit;

procedure Strings_Edit.UTF8.NFKD_QC_Generator is

   File    : File_Type;
   Line    : String (1..2048);
   Line_No : Natural := 0;
   Length  : Integer;
   Pointer : Integer;

   type Text_Buffer_State is (Prologue, Has_Data, Epilogue);
   type Text_Buffer_Index is range 1..4096;
   type Text_Buffer is array (Text_Buffer_Index) of Unbounded_String;

   Buffer  : Text_Buffer;
   Data_At : Text_Buffer_Index;
   Free    : Text_Buffer_Index := Text_Buffer_Index'First;

   type Code_Position is range Code_Point'First..Code_Point'Last;
   package Code_Point_Edit is
      new Strings_Edit.Integer_Edit (Code_Position);
   use Code_Point_Edit;

   type Item;
   type Item_Ptr is access Item;
   type Item is record
      Lower : Code_Position;
      Upper : Code_Position;
      No    : Boolean;
      Next  : Item_Ptr;
   end record;

   procedure Add_Line is
   begin
      if Free = Text_Buffer_Index'Last then
         Raise_Exception (Data_Error'Identity, "File is too long");
      end if;
      Buffer (Free) := To_Unbounded_String (Line (1..Length));
      Free := Free + 1;
   end Add_Line;

   procedure Read_Line is
   begin
      Get_Line (File, Line, Length);
      Line_No := Line_No + 1;
      if Length = Line'Last then
         Raise_Exception
         (  Data_Error'Identity,
            "Too long line" & Integer'Image (Line_No)
         );
      end if;
      while (  Length > Line'First
            and then
               (  Line (Length) = LF
               or else
                  Line (Length) = CR
            )  )
      loop
         Length := Length - 1;
      end loop;
      Line (Length + 1) := Character'Val (0);
      Pointer := Line'First;
   end Read_Line;

   procedure Get (Point : out Code_Position) is
   begin
      Get (Line, Pointer, SpaceAndTab);
      Get (Line, Pointer, Point, 16);
   exception
      when End_Error | Data_Error =>
         Raise_Exception
         (  Data_Error'Identity,
            (  "Hexadecimal code point number is expected at"
            &  Integer'Image (Pointer)
         )  );
      when Constraint_Error =>
         Raise_Exception
         (  Data_Error'Identity,
            (  "Hexadecimal code point number at"
            &  Integer'Image (Pointer)
            &  " is out of range"
         )  );
   end Get;

   procedure Get_Semicolon is
   begin
      Get (Line, Pointer, SpaceAndTab);
      if Pointer <= Length then
         if Line (Pointer) = ';' then
            Pointer := Pointer + 1;
         else
            Raise_Exception
            (  Data_Error'Identity,
               (  "Semicolon is expected at"
               &  Integer'Image (Pointer)
            )  );
         end if;
      end if;
   end Get_Semicolon;

   Head : Item_Ptr;
   Tail : Item_Ptr;

begin
   if Argument_Count /= 2 then
      Put_Line
      (  Standard_Error,
         (  "Use: strings_edit-utf8-nfcd_qc_generator "
         &  "../strings_edit-utf8-nfkd_quick_check.adb "
         &  "DerivedNormalizationProps.txt"
      )  );
      Set_Exit_Status (Failure);
      return;
   end if;
   declare
      Output : constant String := Argument (1);
      Input  : constant String := Argument (2);
   begin
      begin
         Open (File, In_File, Output);
      exception
         when Name_Error =>
            Put_Line ("Cannot open " & Quote (Output));
            Set_Exit_Status (Failure);
            return;
         when Error : others =>
            Put_Line
            (  "Cannot open "
            &  Quote (Output)
            &  ": "
            &  Exception_Information (Error)
            );
            Set_Exit_Status (Failure);
            return;
      end;
      declare
         State : Text_Buffer_State := Prologue;
      begin
         --
         -- Reading the Strings_Edit.UTF8.Mappings file
         --
         Line_No := 0;
         loop
            Read_Line;
            case State is
               when Prologue =>
                  Get (Line, Pointer, SpaceAndTab);
                  Add_Line;
                  if Is_Prefix
                     (  "Data : constant Code_Point_Range_Array :=",
                        Line,
                        Pointer
                     )
                  then
                     State   := Has_Data;
                     Data_At := Free;
                  end if;
               when Has_Data =>
                  Get (Line, Pointer, SpaceAndTab);
                  if Is_Prefix (");", Line, Pointer) then
                     State := Epilogue;
                  end if;
               when Epilogue =>
                  Add_Line;
            end case;
         end loop;
      exception
         when End_Error =>
            Close (File);
            if State /= Epilogue then
               Put_Line
               (  "File "
               &  Quote (Output)
               &  " is not recognized as "
               &  "Strings_Edit.UTF8.Mapping source"
               );
               return;
            end if;
         when Error : Data_Error =>
            Put_Line
            (  "Malformed "
            &  Quote (Output)
            &  " (Line"
            &  Integer'Image (Line_No)
            &  ") "
            &  Exception_Message (Error)
            );
            Set_Exit_Status (Failure);
            return;
         when Error : others =>
            Put_Line
            (  "Internal error while reading "
            &  Quote (Output)
            &  " (Line"
            &  Integer'Image (Line_No)
            &  ") "
            &  Exception_Information (Error)
            );
            Set_Exit_Status (Failure);
            return;
      end;
      --
      -- Dealing with DerivedNormalizationProps.txt
      --
      begin
         Open (File, In_File, Input);
      exception
         when Name_Error =>
            Put_Line ("Cannot open " & Quote (Input));
            Set_Exit_Status (Failure);
            return;
         when Error : others =>
            Put_Line
            (  "Cannot open "
            &  Quote (Input)
            &  ": "
            &  Exception_Information (Error)
            );
            Set_Exit_Status (Failure);
            return;
      end;
      declare
         Data : Item;
      begin
         --
         -- Reading the DerivedNormalizationProps file
         --
         Line_No := 0;
         loop
            Read_Line;
            Get (Line, Pointer, SpaceAndTab);
            if Pointer <= Length then
               case Line (Pointer) is
                  when '0'..'9' | 'a'..'f' | 'A'..'F' =>
                     Get (Data.Lower);
                     Get (Line, Pointer, SpaceAndTab);
                     if Is_Prefix ("..", Line, Pointer) then
                        Pointer := Pointer + 2;
                        Get (Data.Upper);
                     else
                        Data.Upper := Data.Lower;
                     end if;
                     Get (Line, Pointer, SpaceAndTab);
                     if Is_Prefix (";", Line, Pointer) then
                        Pointer := Pointer + 1;
                        Get (Line, Pointer, SpaceAndTab);
                        if Is_Prefix ("NFKD_QC", Line, Pointer) then
                           Pointer := Pointer + 7;
                           Get_Semicolon;
                           if Data.Upper < Data.Lower then
                              Raise_Exception
                              (  Data_Error'Identity,
                                 (  "Invalid code position range at"
                                 &  Integer'Image (Pointer)
                              )  );
                           elsif Tail /= null    and then
                                 Tail.Upper >= Data.Lower then
                              Raise_Exception
                              (  Data_Error'Identity,
                                 (  "Descending code position at"
                                 &  Integer'Image (Pointer)
                              )  );
                           end if;
                           Get (Line, Pointer, SpaceAndTab);
                           case Line (Pointer) is
                              when 'n' | 'N' =>
                                 Data.No := True;
                              when 'm' | 'M' =>
                                 Data.No := False;
                              when others =>
                                 Raise_Exception
                                 (  Data_Error'Identity,
                                    (  "Invalid NFKD_QC value at"
                                    &  Integer'Image (Pointer)
                                 )  );
                           end case;
                           if Head = null then
                              Head := new Item'(Data);
                              Tail := Head;
                           elsif Tail.Upper + 1 = Data.Lower then
                              Tail.Upper := Data.Upper;
                           else
                              Tail.Next := new Item'(Data);
                              Tail := Tail.Next;
                           end if;
                        end if;
                     end if;
                  when others =>
                     null;
               end case;
            end if;
         end loop;
      exception
         when End_Error =>
            Close (File);
            if Head = null then
               Raise_Exception
               (  Data_Error'Identity,
                  "No NFKD_QC entries found"
               );
            end if;
         when Error : Data_Error =>
            Put_Line
            (  "Malformed "
            &  Quote (Input)
            &  " (Line"
            &  Integer'Image (Line_No)
            &  ") "
            &  Exception_Message (Error)
            );
            Set_Exit_Status (Failure);
            return;
         when Error : others =>
            Put_Line
            (  "Internal error while reading "
            &  Quote (Input)
            &  " (Line"
            &  Integer'Image (Line_No)
            &  ") "
            &  Integer'Image (Line_No)
            &  Exception_Information (Error)
            );
            Set_Exit_Status (Failure);
            return;
      end;
      --
      -- Writing the output
      --
      begin
         Open (File, Out_File, Output);
      exception
         when Name_Error =>
            Put_Line ("Cannot open " & Quote (Output) & " for write");
            Set_Exit_Status (Failure);
            return;
         when Error : others =>
            Put_Line
            (  "Cannot open "
            &  Quote (Output)
            &  ": "
            &  Exception_Information (Error)
            );
            Set_Exit_Status (Failure);
            return;
      end;
      begin
         for Line in 1..Data_At - 1 loop
            Put_Line (File, To_String (Buffer (Line)));
         end loop;
         Put_Line (File, "   (");
         while Head /= null loop
            Put (File, "      ");
            Put (File, "(16#");
            Put (File, Image (Head.Lower, 16));
            Put (File, "#,16#");
            Put (File, Image (Head.Upper, 16));
            Put (File, "#,");
            if Head.No then
              Put (File, "No)");
            else
              Put (File, "Maybe)");
            end if;
            if Head.Next = null then
               New_Line (File);
               Put_Line (File, "   );");
               exit;
            end if;
            Put_Line (File, ",");
            Head := Head.Next;
         end loop;
         for Line in Data_At..Free - 1 loop
            Put_Line (File, To_String (Buffer (Line)));
         end loop;
         Close (File);
      exception
         when Error : others =>
            Put_Line
            (  "Cannot write "
            &  Quote (Output)
            &  ": "
            &  Exception_Information (Error)
            );
            Set_Exit_Status (Failure);
            return;
      end;
   end;
   Set_Exit_Status (Success);
exception
   when Error : others =>
      Put ("Error :");
      Put_Line (Exception_Information (Error));
end Strings_Edit.UTF8.NFKD_QC_Generator;
