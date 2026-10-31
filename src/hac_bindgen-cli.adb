-- -----------------------------------------------------------------------------
--  hac_bindgen, binding generator for embedded HAC
--  (https://github.com/LionelDraghi/hac_bindgen)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Characters.Handling;
with Ada.Command_Line;
with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Hac_Bindgen.Analysis;
with Hac_Bindgen.Generation;
with Hac_Bindgen.Model;
with Hac_Bindgen.Traversal;

package body Hac_Bindgen.CLI is

   package CL    renames Ada.Command_Line;
   package Dir   renames Ada.Directories;
   package Hand  renames Ada.Characters.Handling;
   package SU    renames Ada.Strings.Unbounded;
   package TIO   renames Ada.Text_IO;

   use Hac_Bindgen.Model;

   use type Dir.File_Kind;

   package Model_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Model.Package_Model);

   Run_Error : exception;

   procedure Fail (Message : String; With_Usage : Boolean := True);

   procedure Put_Usage (Stream : TIO.File_Type);

   function File_Exists (Name : String) return Boolean;

   ---------------------------------------------------------------------

   procedure Fail (Message : String; With_Usage : Boolean := True) is
   begin
      TIO.Put_Line (TIO.Standard_Error, "error: " & Message);
      if With_Usage then
         Put_Usage (TIO.Standard_Error);
      end if;
      CL.Set_Exit_Status (CL.Failure);
      raise Run_Error;
   end Fail;

   ---------------------------------------------------------------------

   procedure Put_Usage (Stream : TIO.File_Type) is
   begin
      TIO.Put_Line
        (Stream,
         "usage: hac-bindgen generate SOURCE... [--output-dir DIR]"
         & " [--hac-package NAME]");
      TIO.Put_Line (Stream, "       hac-bindgen check SOURCE...");
      TIO.Put_Line (Stream, "       hac-bindgen --version");
      TIO.Put_Line (Stream, "       hac-bindgen --help");
   end Put_Usage;

   ---------------------------------------------------------------------

   function File_Exists (Name : String) return Boolean is
   begin
      return Dir.Exists (Name)
             and then Dir.Kind (Name) = Dir.Ordinary_File;
   exception
      when Dir.Name_Error =>
         return False;
   end File_Exists;

   ---------------------------------------------------------------------

   procedure Run is
   begin
      if CL.Argument_Count = 0 then
         --  No argument: same behavior as --help ([A001]).
         Put_Usage (TIO.Standard_Output);
         CL.Set_Exit_Status (CL.Success);
         return;
      end if;

      declare
         Command : constant String := CL.Argument (1);
      begin
         if Command = "--version" then
            TIO.Put_Line (Hac_Bindgen.Tool_Name & " " & Hac_Bindgen.Version);
            return;

         elsif Command = "--help" then
            Put_Usage (TIO.Standard_Output);
            CL.Set_Exit_Status (CL.Success);
            return;

         elsif Command = "generate"
           or else Command = "check"
         then
            declare
               use SU;

               Output_Dir  : Unbounded_String;
               Hac_Package : Unbounded_String;
               Sources     : Unbounded_String;

               --  Options and sources, in any order ([S010]): the
               --  arguments are parsed first, the sources are
               --  processed afterwards.
               procedure Parse_Arguments is
                  I : Positive := 2;
               begin
                  while I <= CL.Argument_Count loop
                     declare
                        Arg : constant String := CL.Argument (I);
                     begin
                        if Arg = "--output-dir"
                          or else Arg = "--hac-package"
                        then
                           if Command = "check" then
                              Fail ("option '" & Arg
                                    & "' applies to generate only");
                           end if;
                           if I = CL.Argument_Count then
                              Fail ("option '" & Arg & "' needs a value");
                           end if;
                           if Arg = "--output-dir" then
                              Output_Dir := To_Unbounded_String
                                (CL.Argument (I + 1));
                           else
                              Hac_Package := To_Unbounded_String
                                (CL.Argument (I + 1));
                           end if;
                           I := I + 2;

                        elsif Arg (Arg'First) = '-' then
                           Fail ("unknown option '" & Arg & "'");

                        else
                           Sources := Sources & Arg & " ";
                           I := I + 1;
                        end if;
                     end;
                  end loop;

                  if Sources = Null_Unbounded_String then
                     Fail ("missing source file");
                  end if;
               end Parse_Arguments;

               --  One source: the same analysis, classification and
               --  report for both commands ([S006]); generate adds
               --  the facade files ([A002]).
               procedure Process_Source (Arg : String) is
               begin
                  if not File_Exists (Arg) then
                     Fail ("cannot read '" & Arg & "'");
                  end if;

                  Analysis.Check (Arg);
               exception
                  when Error : Analysis.Analysis_Error =>
                     Fail (Ada.Exceptions.Exception_Message (Error),
                           With_Usage => False);
               end Process_Source;

               function Source_Count return Natural is
                  Count       : Natural := 0;
                  Source_List : constant String := To_String (Sources);
               begin
                  --  Sources are space-joined with one trailing space;
                  --  one space per source.
                  for I in Source_List'Range loop
                     if Source_List (I) = ' ' then
                        Count := Count + 1;
                     end if;
                  end loop;
                  return Count;
               end Source_Count;

               procedure Process_All_Sources is
                  Source_List : constant String := To_String (Sources);
                  First : Positive := Source_List'First;

                  Models : Model_Vectors.Vector;

                  procedure Analyze_All is
                     --  Every source is analyzed before anything is
                     --  generated, so that a bad input or a duplicate
                     --  package name ([A007]) leaves no file behind.
                  begin
                     for I in Source_List'Range loop
                        if Source_List (I) = ' ' and then I > First then
                           declare
                              Arg : constant String :=
                                Source_List (First .. I - 1);
                           begin
                              if not File_Exists (Arg) then
                                 Fail ("cannot read '" & Arg & "'");
                              end if;

                              begin
                                 Models.Append (Analysis.Analyze (Arg));
                              exception
                                 when Error : Analysis.Analysis_Error =>
                                    Fail (Ada.Exceptions.Exception_Message
                                            (Error),
                                          With_Usage => False);
                              end;
                              First := I + 1;
                           end;
                        end if;
                     end loop;
                  end Analyze_All;

                  procedure Reject_Duplicate_Package_Names is
                     --  Two sources declaring the same package name
                     --  would generate two identical HAC-side units:
                     --  the second overwrites the first, one binding
                     --  silently lost ([A007]). Ada names are
                     --  case-insensitive.
                  begin
                     for I in Models.First_Index .. Models.Last_Index - 1
                     loop
                        for J in I + 1 .. Models.Last_Index loop
                           if Hand.To_Lower
                                (SU.To_String (Models (I).Canonical_Name))
                              = Hand.To_Lower
                                  (SU.To_String (Models (J).Canonical_Name))
                           then
                              Fail
                                ("duplicate package name '"
                                 & SU.To_String
                                     (Models (J).Canonical_Name)
                                 & "' in '"
                                 & SU.To_String (Models (J).Source_Name)
                                 & "'",
                                 With_Usage => False);
                           end if;
                        end loop;
                     end loop;
                  end Reject_Duplicate_Package_Names;

                  procedure Generate_All is
                  begin
                     for M of Models loop
                        declare
                           The_Result : constant Model.Analysis_Result :=
                             Traversal.Classify (M);
                        begin
                           Traversal.Report (M, The_Result);
                           Generation.Generate
                             (M,
                              The_Result,
                              To_String (Hac_Package),
                              To_String (Output_Dir));
                        exception
                           when Error : Generation.Generation_Error =>
                              Fail (Ada.Exceptions.Exception_Message
                                      (Error),
                                    With_Usage => False);
                        end;
                     end loop;
                  end Generate_All;

               begin
                  if Command = "check" then
                     for I in Source_List'Range loop
                        if Source_List (I) = ' ' then
                           if I > First then
                              Process_Source (Source_List (First .. I - 1));
                           end if;
                           First := I + 1;
                        end if;
                     end loop;
                  else
                     Analyze_All;
                     Reject_Duplicate_Package_Names;
                     Generate_All;
                  end if;
               end Process_All_Sources;

            begin
               Parse_Arguments;

               --  [A007]: --hac-package renames the HAC-side package
               --  of one API; on several sources it would rename every
               --  package identically, one binding silently shadowing
               --  the other: rejected.
               if Command = "generate"
                 and then Hac_Package /= Null_Unbounded_String
                 and then Source_Count > 1
               then
                  Fail ("option '--hac-package' applies to a single source");
               end if;

               Process_All_Sources;
            end;

            --  Every source processed; the warnings were reported
            --  above, the exit status stays success.
            CL.Set_Exit_Status (CL.Success);

         else
            Fail ("invalid command '" & Command & "'");
         end if;
      exception
         when Run_Error =>
            null;  --  message and status already emitted by Fail
      end;
   end Run;

end Hac_Bindgen.CLI;
