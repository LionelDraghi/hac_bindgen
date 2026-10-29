--
-- Requeue Statement
--
-- Failure: The accept statement's innermost enclosing body is not a task body at 27:4..9
--
--
procedure Accept_Statement is
   task T is
      entry A;
      entry B;
   end T;

   task body T is
   begin
      select
         accept A do
            requeue B;
         end A;
      or accept B do
            begin
               requeue A;
            end;
         end B;
      end select;
   end;
begin
   accept A;
end Accept_Statement;