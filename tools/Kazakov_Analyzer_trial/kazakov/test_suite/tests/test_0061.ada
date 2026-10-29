--
-- ARM 5.5(28-31) Loop Statements
--
-- Success: 31:1..55:12 Tree *
--
-- package body ARM_5_5 is
--    subtype Chunk_Number is Natural range 1..8;
--    Partial_Sum,
--    Partial_Max : array (Chunk_Number) of Natural := (others => 0);
--    Partial_Min : array (Chunk_Number) of Natural :=
--                        (others => Natural'Last);
-- begin
--    parallel (Chunk in Chunk_Number)
--    for I in Grid'Range (1) loop
--       declare
--          True_Count : constant Natural :=
--            [for J in Grid'Range (2) =>
--               (if Grid (I, J) then 1 else 0)]'Reduce ("+", 0);
--       begin
--          Partial_Sum (Chunk) := (@ + True_Count);
--          Partial_Min (Chunk) := Natural'Min (@, True_Count);
--          Partial_Max (Chunk) := Natural'Max (@, True_Count);
--       end;
--    end loop;
--    Put_Line
--      (("Total=" & Partial_Sum'Reduce ("+", 0)'Image &
--       ", Min=" & Partial_Min'Reduce (Natural'Min, Natural'Last)'Image &
--       ", Max=" & Partial_Max'Reduce (Natural'Max, 0)'Image));
-- end ARM_5_5;
--
package body ARM_5_5 is
   subtype Chunk_Number is Natural range 1 .. 8;

   Partial_Sum,
   Partial_Max : array (Chunk_Number) of Natural := (others => 0);
   Partial_Min : array (Chunk_Number) of Natural :=
                       (others => Natural'Last);
begin
   parallel (Chunk in Chunk_Number)
   for I in Grid'Range(1) loop
      declare
         True_Count : constant Natural :=
           [for J in Grid'Range(2) =>
              (if Grid (I, J) then 1 else 0)]'Reduce("+",0);
      begin
         Partial_Sum (Chunk) := @ + True_Count;
         Partial_Min (Chunk) := Natural'Min(@, True_Count);
         Partial_Max (Chunk) := Natural'Max(@, True_Count);
      end;
   end loop;
   Put_Line
     ("Total=" & Partial_Sum'Reduce("+", 0)'Image &
      ", Min=" & Partial_Min'Reduce(Natural'Min, Natural'Last)'Image &
      ", Max=" & Partial_Max'Reduce(Natural'Max, 0)'Image);
end ARM_5_5;