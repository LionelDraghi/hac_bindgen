--
-- ARM 9.3 Task Dependence - Termination of Tasks
--
-- Success: 24:1..42:12 Tree *
--
-- package body ARM_9_3 is
-- begin
--    declare
--       type Global is access Server;
--       A, B : Server;
--       G    : Global;
--    begin
--       declare
--          type Local is access Server;
--          X : Global := new (Server);
--          L : Local  := new (Server);
--          C : Server;
--       begin
--          G := X;
--       end;
--    end;
-- end ARM_9_3;
--
package body ARM_9_3 is
begin
   declare
      type Global is access Server;        --  see 9.1
      A, B : Server;
      G    : Global;
   begin
      --  activation of A and B
      declare
         type Local is access Server;
         X : Global := new Server;  --  activation of X.all
         L : Local  := new Server;  --  activation of L.all
         C : Server;
      begin
         --  activation of C
         G := X;  --  both G and X designate the same task object
      end;  --  await termination of C and L.all (but not X.all)
   end;  --  await termination of A, B, and G.all
end ARM_9_3;