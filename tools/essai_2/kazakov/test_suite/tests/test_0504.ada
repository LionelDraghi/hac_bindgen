--
-- ARM 6.5 Return Statements
--
-- Success: 15:1..23:12
--
-- function ARM_6_5 return X is
-- begin
--    return Key_Value (Last_Index);
--    return Node : Cell do
--       Node.Value := Result;
--       Node.Succ := Next_Node;
--    end return;
-- end ARM_6_5;
--
function ARM_6_5 return X is
begin
   return Key_Value(Last_Index);   -- in a function body

   return Node : Cell do           -- in a function body, see 3.10.1 for Cell
      Node.Value := Result;
      Node.Succ := Next_Node;
   end return;
end ARM_6_5;