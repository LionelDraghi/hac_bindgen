--
-- Requeue Statement
--
-- Failure: 'requeue' is unexpected inside a declarative part as found at 7:4..10
--
function Requeue_Statement return Boolean is
   requeue T;
begin
   null;
end Requeue_Statement;