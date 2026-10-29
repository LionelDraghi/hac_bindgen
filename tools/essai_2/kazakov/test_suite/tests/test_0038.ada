--
-- ARM 3.10.1(15-23) Incomplete Type Declarations
--
-- Success: 43:1..84:15 Tree *
--
-- package body ARM_3_10_1 is
--    type Cell;
--    type Link is access Cell;
--    type Cell is
--       record
--          Value  : Integer;
--          Succ   : Link;
--          Pred   : Link;
--       end record;
--    Head   : Link  := new (Cell'(0, null, null));
--    Next   : Link  := Head.Succ;
--    type Person (<>);
--    type Car is tagged;
--    type Person_Name is access Person;
--    type Car_Name    is access all Car'Class;
--    type Car is tagged
--       record
--          Number  : Integer;
--          Owner   : Person_Name;
--       end record;
--    type Person (Sex : Gender) is
--       record
--          Name     : String (1..20);
--          Birth    : Date;
--          Age      : Integer range 0..130;
--          Vehicle  : Car_Name;
--          case Sex is
--             when M => Wife           : Person_Name (Sex => F);
--             when F => Husband        : Person_Name (Sex => M);
--          end case;
--       end record;
--    My_Car, Your_Car, Next_Car : Car_Name := new (Car);
--    Casey : Person_Name := new (Person (M));
-- begin
--    Casey.Vehicle := Your_Car;
-- end ARM_3_10_1;
--
package body ARM_3_10_1 is
   type Cell;  --  incomplete type declaration
   type Link is access Cell;

   type Cell is
      record
         Value  : Integer;
         Succ   : Link;
         Pred   : Link;
      end record;

   Head   : Link  := new Cell'(0, null, null);
   Next   : Link  := Head.Succ;

   type Person(<>);    -- incomplete type declaration
   type Car is tagged; -- incomplete type declaration
   type Person_Name is access Person;
   type Car_Name    is access all Car'Class;

   type Car is tagged
      record
         Number  : Integer;
         Owner   : Person_Name;
      end record;

   type Person(Sex : Gender) is
      record
         Name     : String(1 .. 20);
         Birth    : Date;
         Age      : Integer range 0 .. 130;
         Vehicle  : Car_Name;
         case Sex is
            when M => Wife           : Person_Name(Sex => F);
            when F => Husband        : Person_Name(Sex => M);
         end case;
      end record;

   My_Car, Your_Car, Next_Car : Car_Name := new Car;  -- see 4.8
   Casey : Person_Name := new Person(M);
begin
   Casey.Vehicle := Your_Car;
end ARM_3_10_1;