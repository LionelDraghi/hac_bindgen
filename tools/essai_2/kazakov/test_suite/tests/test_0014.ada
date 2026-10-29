--
-- ARM 3.3.2 Number Declarations
--
-- Success: 13:1..18:38 Tree *
--
-- package ARM_3_4.Derived_Types_And_Classes is
--   type Local_Coordinate is new Coordinate;
--   type Midweek is new Day range Tue..Thu;
--   type Counter is new Positive;
--   type Special_Key is new Key_Manager.Key;
-- end ARM_3_4.Derived_Types_And_Classes;
--
package ARM_3_4.Derived_Types_And_Classes is
   type Local_Coordinate is new Coordinate;  -- two different types
   type Midweek is new Day range Tue .. Thu; -- see 3.5.1
   type Counter is new Positive;             -- same range as Positive 
   type Special_Key is new Key_Manager.Key;  -- see 7.3.1
end ARM_3_4.Derived_Types_And_Classes;