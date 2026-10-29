--
-- ARM 5.7 Exit Statements
--
-- Success: 20:1..34:12
--
-- package body ARM_5_7 is
-- begin
-- for N in 1..Max_Num_Items loop
--    Get_New_Item (New_Item);
--    Merge_Item (New_Item, Storage_File);
--    exit when (New_Item = Terminal_Item);
-- end loop;
--
-- Main_Cycle :
--    loop
--       exit Main_Cycle when Found;
--    end loop Main_Cycle;
-- end ARM_5_7;
--
package body ARM_5_7 is
begin
for N in 1 .. Max_Num_Items loop
   Get_New_Item(New_Item);
   Merge_Item(New_Item, Storage_File);
   exit when New_Item = Terminal_Item;
end loop;

Main_Cycle:
   loop
      --  initial statements
      exit Main_Cycle when Found;
      --  final statements
   end loop Main_Cycle;
end ARM_5_7;