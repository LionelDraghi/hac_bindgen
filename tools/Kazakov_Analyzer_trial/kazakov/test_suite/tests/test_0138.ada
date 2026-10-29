--
-- ARM 13.11.4 Storage Subpools
--
-- Success: 51:1..116:34 Tree *
--
-- package System.Storage_Pools.Subpools
--    with Preelaborate, Global => in out synchronized is
--    type Root_Storage_Pool_With_Subpools is
--       abstract new Root_Storage_Pool with private
--       with Preelaborable_Initialization;
--    type Root_Subpool is abstract tagged limited private
--       with Preelaborable_Initialization;
--    type Subpool_Handle is access all Root_Subpool'Class;
--    for Subpool_Handle'Storage_Size use 0;
--    function Create_Subpool (Pool : in out Root_Storage_Pool_With_Subpools)
--       return not null Subpool_Handle is abstract;
--    function Pool_of_Subpool (Subpool : not null Subpool_Handle)
--       return access Root_Storage_Pool_With_Subpools'Class;
--    procedure Set_Pool_of_Subpool (Subpool : not null Subpool_Handle;
--       To : in out Root_Storage_Pool_With_Subpools'Class)
--          with Global => overriding in out Subpool;
--    procedure Allocate_From_Subpool (Pool : in out Root_Storage_Pool_With_Subpools;
--       Storage_Address : out Address;
--       Size_In_Storage_Elements : Storage_Elements.Storage_Count;
--       Alignment : Storage_Elements.Storage_Count;
--       Subpool : not null Subpool_Handle) is abstract
--          with Pre'Class => (Pool_of_Subpool (Subpool) = Pool'Access),
--               Global => overriding in out Subpool;
--    procedure Deallocate_Subpool (Pool : in out Root_Storage_Pool_With_Subpools;
--       Subpool : in out Subpool_Handle) is abstract
--          with Pre'Class => (Pool_of_Subpool (Subpool) = Pool'Access);
--    function Default_Subpool_for_Pool (Pool : in out Root_Storage_Pool_With_Subpools)
--          return not null Subpool_Handle;
--    overriding
--    procedure Allocate (Pool : in out Root_Storage_Pool_With_Subpools;
--       Storage_Address : out Address;
--       Size_In_Storage_Elements : Storage_Elements.Storage_Count;
--       Alignment : Storage_Elements.Storage_Count);
--    overriding
--    procedure Deallocate (Pool : in out Root_Storage_Pool_With_Subpools;
--       Storage_Address : Address;
--       Size_In_Storage_Elements : Storage_Elements.Storage_Count;
--       Alignment : Storage_Elements.Storage_Count) is null;
--    overriding
--    function Storage_Size (Pool : Root_Storage_Pool_With_Subpools)
--       return Storage_Elements.Storage_Count
--           is (Storage_Elements.Storage_Count'Last);
-- private
-- end System.Storage_Pools.Subpools;
--
package System.Storage_Pools.Subpools
   with Preelaborate, Global => in out synchronized is

   type Root_Storage_Pool_With_Subpools is
      abstract new Root_Storage_Pool with private
      with Preelaborable_Initialization;

   type Root_Subpool is abstract tagged limited private
      with Preelaborable_Initialization;

   type Subpool_Handle is access all Root_Subpool'Class;
   for Subpool_Handle'Storage_Size use 0;

   function Create_Subpool (Pool : in out Root_Storage_Pool_With_Subpools)
      return not null Subpool_Handle is abstract;

    -- The following operations are intended for pool implementers:

   function Pool_of_Subpool (Subpool : not null Subpool_Handle)
      return access Root_Storage_Pool_With_Subpools'Class;

   procedure Set_Pool_of_Subpool (
      Subpool : in not null Subpool_Handle;
      To : in out Root_Storage_Pool_With_Subpools'Class)
         with Global => overriding in out Subpool;

   procedure Allocate_From_Subpool (
      Pool : in out Root_Storage_Pool_With_Subpools;
      Storage_Address : out Address;
      Size_In_Storage_Elements : in Storage_Elements.Storage_Count;
      Alignment : in Storage_Elements.Storage_Count;
      Subpool : in not null Subpool_Handle) is abstract
         with Pre'Class => Pool_of_Subpool(Subpool) = Pool'Access,
              Global => overriding in out Subpool;

   procedure Deallocate_Subpool (
      Pool : in out Root_Storage_Pool_With_Subpools;
      Subpool : in out Subpool_Handle) is abstract
         with Pre'Class => Pool_of_Subpool(Subpool) = Pool'Access;

   function Default_Subpool_for_Pool (
      Pool : in out Root_Storage_Pool_With_Subpools)
         return not null Subpool_Handle;

   overriding
   procedure Allocate (
      Pool : in out Root_Storage_Pool_With_Subpools;
      Storage_Address : out Address;
      Size_In_Storage_Elements : in Storage_Elements.Storage_Count;
      Alignment : in Storage_Elements.Storage_Count);

   overriding
   procedure Deallocate (
      Pool : in out Root_Storage_Pool_With_Subpools;
      Storage_Address : in Address;
      Size_In_Storage_Elements : in Storage_Elements.Storage_Count;
      Alignment : in Storage_Elements.Storage_Count) is null;

   overriding
   function Storage_Size (Pool : Root_Storage_Pool_With_Subpools)
      return Storage_Elements.Storage_Count
          is (Storage_Elements.Storage_Count'Last);

private
   -- not specified by the language
end System.Storage_Pools.Subpools;