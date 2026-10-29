--
-- ARM 3.8.1(24) Variant Parts and Discrete Choices
--
-- Success: 35:1..56:6 Tree *
--
-- with Ada.Text_IO;
-- generic
--    type T is new Integer;
-- package G is
--    type Device is (Printer, Disk, Drum);
--    type State  is (Open, Closed);
-- 
--    type Peripheral (Unit : Device := Disk) is
--       record
--          Status : State;
--          case Unit is
--             when Printer =>
--                Line_Count : Integer range 1..Page_Size;
--             when others =>
--                Cylinder   : Cylinder_Index;
--                Track      : Track_Number;
--          end case;
--       end record;
-- 
--    subtype Drum_Unit is Peripheral (Drum);
--    subtype Disk_Unit is Peripheral (Disk);
-- 
--    Writer   : Peripheral (Unit => Printer);
--    Archive  : Disk_Unit;
-- end G;
--
with Ada.Text_IO;
generic
   type T is new Integer;
package G is
   type Device is (Printer, Disk, Drum);
   type State  is (Open, Closed);

   type Peripheral(Unit : Device := Disk) is
      record
         Status : State;
         case Unit is
            when Printer =>
               Line_Count : Integer range 1 .. Page_Size;
            when others =>
               Cylinder   : Cylinder_Index;
               Track      : Track_Number;
         end case;
      end record;

   subtype Drum_Unit is Peripheral(Drum);
   subtype Disk_Unit is Peripheral(Disk);

   Writer   : Peripheral(Unit  => Printer);
   Archive  : Disk_Unit;
end G;