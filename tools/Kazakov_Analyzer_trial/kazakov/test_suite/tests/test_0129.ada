--
-- ARM 11.2 Exception Handlers
--
-- Success: 16:1..24:20
--
-- procedure Exceptions_Test is
-- begin
--    null;
-- exception
--    when E : Constraint_Error =>
--       null;
--    when E : others =>
--       null;
-- end Exceptions_Test;
--
procedure Exceptions_Test is
begin
   null;
exception
   when E : Constraint_Error =>
      null;
   when E : others =>
      null;
end Exceptions_Test;