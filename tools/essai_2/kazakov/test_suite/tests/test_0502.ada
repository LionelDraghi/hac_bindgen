--
-- Requeue Statement
--
-- Success: 27:1..48:22
--
-- procedure Requeue_Statement is
--    task T is
--       entry A;
--       entry B;
--    end T;
--    task body T is
--    begin
--       select
--          accept A do
--             requeue B;
--          end A;
--       or accept B do
--             begin
--                requeue A;
--             end; end B;
--       end select;
--    end T;
-- begin
--    null;
-- end Requeue_Statement;
--
procedure Requeue_Statement is
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
   null;
end Requeue_Statement;