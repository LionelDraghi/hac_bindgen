--
-- ARM 13.11.5 Subpool Reclamation
--
-- Success: 12:1..14:29 Tree *
--
-- with System.Storage_Pools.Subpools;
-- procedure Ada.Unchecked_Deallocate_Subpool
--    (Subpool : in out System.Storage_Pools.Subpools.Subpool_Handle)
--    with Global => in out all;
--
with System.Storage_Pools.Subpools;
procedure Ada.Unchecked_Deallocate_Subpool
   (Subpool : in out System.Storage_Pools.Subpools.Subpool_Handle)
   with Global => in out all;