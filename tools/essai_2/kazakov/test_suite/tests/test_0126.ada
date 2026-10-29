--
-- ARM 11.2 Exception Handlers
--
-- Success: 14:1..20:20
--
-- procedure Exceptions_Test is
-- begin
--    null;
-- exception
--    when E : others =>
--       null;
-- end Exceptions_Test;
--
procedure Exceptions_Test is
begin
   null;
exception
   when E : others =>
      null;
end Exceptions_Test;