--
-- ARM 9.11(2-6) Example of Tasking and Synchronization
--
-- Success: 27:1..53:13 Tree *
--
-- package body ARM_9_11 is
--    task Producer;
--    task body Producer is
--       Person : Person_Name;
--    begin
--       loop
--          Buffer.Append_Wait (Person);
--          exit when (Person = null);
--       end loop;
--    end Producer;
--    task Consumer;
--    task body Consumer is
--       Person : Person_Name;
--    begin
--       loop
--          Buffer.Remove_First_Wait (Person);
--          exit when (Person = null);
--       end loop;
--    end Consumer;
-- end ARM_9_11;
--
package body ARM_9_11 is

   task Producer;

   task body Producer is
      Person : Person_Name; -- see 3.10.1
   begin
      loop
         --  simulate arrival of the next customer
         Buffer.Append_Wait(Person);
         exit when Person = null;
      end loop;
   end Producer;

   task Consumer;

   task body Consumer is
      Person : Person_Name;
   begin
      loop
         Buffer.Remove_First_Wait(Person);
         exit when Person = null;
         --  simulate serving a customer
      end loop;
   end Consumer;

end ARM_9_11;