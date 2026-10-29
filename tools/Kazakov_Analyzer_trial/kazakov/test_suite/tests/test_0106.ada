--
-- ARM 9.5.2(13) Entries and Accept Statements
--
-- Failure: Access parameter is not allowed for task entries as found at 8:19..24
--
package ARM_9_5_2 is
   task T is
      entry E(Z : access Integer); -- Illegal!
   end T;
end ARM_9_5_2;