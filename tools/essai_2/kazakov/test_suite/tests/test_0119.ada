--
-- ARM 10.1.1(35) Compilation Units - Library Units
--
-- Success: 57:1..63:17, 66:1..73:35, 77:1..82:19, 85:1..110:17 Tree *
--
-- generic
--    type Element is private;
--    with function Image (E : Element) return String;
-- package Generic_Bags is
--    type Bag is limited private;
--    procedure Add (B : in out Bag; E : Element);
--    function Bag_Image (B : Bag) return String;
-- private
--    type Bag is limited null record;
-- end Generic_Bags;
-- generic
-- package Generic_Bags.Generic_Iterators is
--    generic
--       with procedure Use_Element (E : Element);
--    procedure Iterate (B : Bag);
-- end Generic_Bags.Generic_Iterators;
-- with Generic_Bags;
-- with Generic_Bags.Generic_Iterators;
-- package My_Abstraction is
--     type My_Type is null record;
--     function Image (X : My_Type) return String;
--     package Bags_Of_My_Type is new Generic_Bags (My_Type, Image);
--     package Iterators_Of_Bags_Of_My_Type is new Bags_Of_My_Type.Generic_Iterators;
-- end My_Abstraction;
-- with Generic_Bags.Generic_Iterators;
-- package body Generic_Bags is
--    procedure Add (B : in out Bag; E : Element) is begin null; end Add;
--    package Iters is new Generic_Iterators;
--    function Bag_Image (B : Bag) return String is
--       Buffer : String (1..10000);
--       Last : Integer := 0;
--       procedure Append_Image (E : Element) is
--          Im : constant String := Image (E);
--       begin
--          if (Last /= 0) then
--             Last := (Last + 1);
--             Buffer (Last) := ',';
--          end if;
--          Buffer ((Last + 1)..(Last + Im'Length)) := Im;
--          Last := (Last + Im'Length);
--       end Append_Image;
--       procedure Append_All is new Iters.Iterate (Append_Image);
--    begin
--       Append_All (B);
--       return Buffer (1..Last);
--    end Bag_Image;
-- end Generic_Bags;
--
generic
   type Element is private;
   with function Image(E : Element) return String;
package Generic_Bags is
   type Bag is limited private; -- A bag of Elements.
   procedure Add(B : in out Bag; E : Element);
   function Bag_Image(B : Bag) return String;
private
   type Bag is limited null record;
end Generic_Bags;

generic
package Generic_Bags.Generic_Iterators is
   -- various additional operations on Bags.

   generic
      with procedure Use_Element(E : in Element);
         -- Called once per bag element.
   procedure Iterate(B : in Bag);
end Generic_Bags.Generic_Iterators;

with Generic_Bags;
with Generic_Bags.Generic_Iterators;
package My_Abstraction is
    type My_Type is null record;
    function Image(X : My_Type) return String;
    package Bags_Of_My_Type is new Generic_Bags(My_Type, Image);
    package Iterators_Of_Bags_Of_My_Type is new Bags_Of_My_Type.Generic_Iterators;
end My_Abstraction;

with Generic_Bags.Generic_Iterators;
package body Generic_Bags is
   procedure Add(B : in out Bag; E : Element) is begin null; end Add;

   package Iters is new Generic_Iterators;

   function Bag_Image(B : Bag) return String is
      Buffer : String(1..10_000);
      Last : Integer := 0;

      procedure Append_Image(E : in Element) is
         Im : constant String := Image(E);
      begin
         if Last /= 0 then -- Insert a comma.
            Last := Last + 1;
            Buffer(Last) := ',';
         end if;
         Buffer(Last+1 .. Last+Im'Length) := Im;
         Last := Last + Im'Length;
      end Append_Image;

      procedure Append_All is new Iters.Iterate(Append_Image);
   begin
      Append_All(B);
      return Buffer(1..Last);
   end Bag_Image;
end Generic_Bags;