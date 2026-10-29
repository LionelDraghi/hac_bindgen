--
-- ARM 3.2.4(43-50) Subtype Predicates
--
-- Success: 31:1..52:16 Tree *
--
-- with Ada.IO_Exceptions;
-- package Ada.Text_IO is
--    type File_Type is limited private;
-- 
--    subtype Open_File_Type is File_Type
--       with Dynamic_Predicate => Is_Open (Open_File_Type),
--            Predicate_Failure => (raise Status_Error with "File not open");
--    subtype Input_File_Type is Open_File_Type
--       with Dynamic_Predicate => (Mode (Input_File_Type) = In_File),
--            Predicate_Failure => (raise Mode_Error
--               with ("Cannot read file: " & Name (Input_File_Type)));
--    subtype Output_File_Type is Open_File_Type
--       with Dynamic_Predicate => (Mode (Output_File_Type) /= In_File),
--            Predicate_Failure => (raise Mode_Error
--               with ("Cannot write file: " & Name (Output_File_Type)));
-- 
--    function Mode (File : Open_File_Type) return File_Mode;
--    function Name (File : Open_File_Type) return String;
--    function Form (File : Open_File_Type) return String;
-- 
--    procedure Get (File : Input_File_Type; Item : out Character);
--    procedure Put (File : Output_File_Type; Item : Character);
-- end Ada.Text_IO;
--
with Ada.IO_Exceptions;
package Ada.Text_IO is
   type File_Type is limited private;

   subtype Open_File_Type is File_Type
      with Dynamic_Predicate => Is_Open (Open_File_Type),
           Predicate_Failure => raise Status_Error with "File not open";
   subtype Input_File_Type is Open_File_Type
      with Dynamic_Predicate => Mode (Input_File_Type) = In_File,
           Predicate_Failure => raise Mode_Error
              with "Cannot read file: " & Name (Input_File_Type);
   subtype Output_File_Type is Open_File_Type
      with Dynamic_Predicate => Mode (Output_File_Type) /= In_File,
           Predicate_Failure => raise Mode_Error
              with "Cannot write file: " & Name (Output_File_Type);

   function Mode (File : in Open_File_Type) return File_Mode;
   function Name (File : in Open_File_Type) return String;
   function Form (File : in Open_File_Type) return String;

   procedure Get (File : in Input_File_Type; Item : out Character);
   procedure Put (File : in Output_File_Type; Item : in Character);
end Ada.Text_IO;