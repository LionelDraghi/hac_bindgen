--
-- ARM 7.5 Limited Types
--
-- Success: 19:1..31:15 Tree *
--
-- package IO_Package is
--    type File_Name is limited private;
--    procedure Open (F : in out File_Name);
--    procedure Close (F : in out File_Name);
--    procedure Read (F : File_Name; Item : out Integer);
--    procedure Write (F : File_Name; Item : Integer);
-- private
--    type File_Name is
--       limited record
--          Internal_Name : Integer := 0;
--       end record;
-- end IO_Package;
--
package IO_Package is
   type File_Name is limited private;

   procedure Open (F : in out File_Name);
   procedure Close(F : in out File_Name);
   procedure Read (F : in File_Name; Item : out Integer);
   procedure Write(F : in File_Name; Item : in  Integer);
private
   type File_Name is
      limited record
         Internal_Name : Integer := 0;
      end record;
end IO_Package;