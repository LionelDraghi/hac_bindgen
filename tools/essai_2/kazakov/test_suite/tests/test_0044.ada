--
-- ARM 4.3.5(68-76) Container Aggregates
--
-- Success: 31:1..63:14 Tree *
--
-- procedure ARM_4_3_5 is
--    S : Set_Type;
-- begin
--    S := [];
--    S := Empty_Set;
--    S := [1, 2];
--    S := Empty_Set;
--    Include (S, 1);
--    Include (S, 2);
--    S := [for Item in 1..5 => (Item * 2)];
--    S := Empty_Set;
--    for Item in 1..5 loop
--       Include (S, (Item * 2));
--    end loop;
--    S := [for Item in 1..5 => Item,
--          for Item in 1..5 => -(Item)];
--    S := Empty_Set;
--    for Item in 1..5 loop
--       Include (S, Item);
--    end loop;
--    for Item in -(5)..-(1) loop
--       Include (S, Item);
--    end loop;
-- end ARM_4_3_5;
--
procedure ARM_4_3_5 is
   --  Example aggregates using Set_Type.
   S : Set_Type;
begin
   --  Assign the empty set to S:
   S := [];
   --  Is equivalent to:
   S := Empty_Set;
   --  A positional set aggregate:
   S := [1, 2];
   --  Is equivalent to:
   S := Empty_Set;
   Include (S, 1);
   Include (S, 2);
   --  A set aggregate with an iterated_element_association:
   S := [for Item in 1 .. 5 => Item * 2];
   --  Is equivalent to:
   S := Empty_Set;
   for Item in 1 .. 5 loop
      Include (S, Item * 2);
   end loop;
   --  A set aggregate consisting of two iterated_element_associations:
   S := [for Item in 1 .. 5 => Item,
         for Item in 1 .. 5 => -Item];
   --  Is equivalent (assuming set semantics) to:
   S := Empty_Set;
   for Item in 1 .. 5 loop
      Include (S, Item);
   end loop;
   for Item in -5 .. -1 loop
      Include (S, Item);
   end loop;
end ARM_4_3_5;