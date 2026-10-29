--
-- Select statement
--
-- Success: 29:4..51:12 Tree *
--
--    procedure Wait
--              (Job     : in out Abstract_Job;
--                 Timeout : Duration := Duration'Last) is
--       Status : Job_Status;
--    begin
--       select
--          Job.State.Wait (Status);
--       or delay Timeout;
--          Cancel (Job);
--          Job.State.Wait (Status);
--       end select;
--       case Status is
--          when Cancelled =>
--             raise Cancelled_Error;
--          when Completed =>
--             null;
--          when Pending | In_Progress | Aborting =>
--             raise Program_Error;
--          when Failed =>
--             Reraise_Occurrence (Job.Error);
--       end case;
--    end Wait;
--
   procedure Wait
             (  Job     : in out Abstract_Job;
                Timeout : Duration := Duration'Last
             )  is
      Status : Job_Status;
   begin
      select
         Job.State.Wait (Status);
      or delay Timeout;
         Cancel (Job);
         Job.State.Wait (Status);
      end select;
      case Status is
         when Cancelled =>
            raise Cancelled_Error;
         when Completed =>
            null;
         when Pending | In_Progress | Aborting =>
            raise Program_Error;
         when Failed =>
            Reraise_Occurrence (Job.Error);
      end case;
   end Wait;