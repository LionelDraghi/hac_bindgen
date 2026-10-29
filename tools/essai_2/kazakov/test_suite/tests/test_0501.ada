--
-- Requeue Statement
--
-- Failure: Requeue statement is specified in a body that is neither an entry or an accept statement  at 8:4..10
--
function Requeue_Statement return Boolean is
begin
   requeue T;
end Requeue_Statement;