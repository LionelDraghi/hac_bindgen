--
-- ARM 3.3.1(27-33) Subtype Predicates
--
-- Success: 26:1..50:34 Tree *
--
-- with Ada.IO_Exceptions;
-- package ARM_3_3_1.Object_Declarations is
--    John, Paul : not null Person_Name := new (Person (Sex => M));
--    John : not null Person_Name := new (Person (Sex => M));
--    Paul : not null Person_Name := new (Person (Sex => M));
--    Count, Sum  : Integer;
--    Size        : Integer range 0..10000 := 0;
--    Sorted      : Boolean := False;
--    Color_Table : array (1..Max) of Color;
--    Option      : Bit_Vector (1..10) := (others => True);
--    Hello       : aliased String := "Hi, world.";
--    θ, φ        : Float range -(π)..+(π);
--    Limit     : constant Integer := 10000;
--    Low_Limit : constant Integer := (Limit / 10);
--    Tolerance : constant Real := Dispersion (1.15);
--    A_String  : constant String := "A";
--    Hello_Msg : constant access String := Hello'Access;
-- end ARM_3_3_1.Object_Declarations;
--
with Ada.IO_Exceptions;
package ARM_3_3_1.Object_Declarations is
   John, Paul : not null Person_Name := new Person(Sex => M); -- see 3.10.1

-- is equivalent to the two single object declarations in the order given

   John : not null Person_Name := new Person(Sex => M);
   Paul : not null Person_Name := new Person(Sex => M);

-- Examples of variable declarations: 
   Count, Sum  : Integer;
   Size        : Integer range 0 .. 10_000 := 0;
   Sorted      : Boolean := False;
   Color_Table : array(1 .. Max) of Color;
   Option      : Bit_Vector(1 .. 10) := (others => True); -- see 3.6
   Hello       : aliased String := "Hi, world.";
   θ, φ        : Float range -π .. +π;

-- Examples of constant declarations: 
   Limit     : constant Integer := 10_000;
   Low_Limit : constant Integer := Limit/10;
   Tolerance : constant Real := Dispersion(1.15);
   A_String  : constant String := "A";
   Hello_Msg : constant access String := Hello'Access;

end ARM_3_3_1.Object_Declarations;