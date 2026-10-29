with Interfaces;
package Probe_Fixture is
   subtype Small is Integer range 1 .. 10;
   type Color is (Red, Green);
   procedure Mutate (X : in Integer; Y : in out Small; Z : out Boolean);
   function Add (Left, Right : Integer) return Integer;
   Value : constant Integer := 2;
private
   Internal : Integer;
end Probe_Fixture;
