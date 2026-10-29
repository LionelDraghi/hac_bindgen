--
-- ARM 4.3.5(77-76) Container Aggregates
--
-- Success: 35:1..73:14 Tree *
--
-- procedure ARM_4_3_5 is
--    M : Map_Type;
--    Keys : constant array (Positive range <>) of Integer := [2, 3, 5, 7, 11];
-- begin
--    M := Empty_Map;
--    Add_To_Map (M, 12, "house");
--    Add_To_Map (M, 14, "beige");
--    declare
--       type Pair is record
--          Key : Integer;
--          Value : access constant String;
--       end record;
--       Table : constant array (Positive range <>) of Pair :=
--          [(Key => 33, Value => new (String'("a nice string"))),
--           (Key => 44, Value => new (String'("an even better string")))];
--    begin
--       M := [for P of Table use P.Key => P.Value.all];
--       M := Empty_Map;
--       for P of Table loop
--          Add_To_Map (M, P.Key, P.Value.all);
--       end loop;
--       M := [for Key of Keys => Integer'Image (Key)];
--       M := Empty_Map;
--       for Key of Keys loop
--          Add_To_Map (M, Key, Integer'Image (Key));
--       end loop;
--    end;
-- end ARM_4_3_5;
--
procedure ARM_4_3_5 is
   --  A simple named map aggregate:
   M : Map_Type;
      --  Create an image table for an array of integers:
   Keys : constant array(Positive range <>) of Integer := [2, 3, 5, 7, 11];
begin
   --  Is equivalent to:
   M := Empty_Map;
   Add_To_Map (M, 12, "house");
   Add_To_Map (M, 14, "beige");
   declare
      --  Define a table of pairs:
      type Pair is record
         Key : Integer;
         Value : access constant String;
      end record;
      Table : constant array(Positive range <>) of Pair :=
         [(Key => 33, Value => new String'("a nice string")),
          (Key => 44, Value => new String'("an even better string"))];
   begin
      --  A map aggregate using an iterated_element_association
      --  and a key_expression, built from from a table of key/value pairs:
      M := [for P of Table use P.Key => P.Value.all];
      --  Is equivalent to:
      M := Empty_Map;
      for P of Table loop
         Add_To_Map (M, P.Key, P.Value.all);
      end loop;
      --  A map aggregate where the values produced by the
      --  iterated_element_association are of the same type as the key
      --  (hence a separate key_expression is unnecessary):
      M := [for Key of Keys => Integer'Image (Key)];
      --  Is equivalent to:
      M := Empty_Map;
      for Key of Keys loop
         Add_To_Map (M, Key, Integer'Image (Key));
      end loop;
   end;
end ARM_4_3_5;