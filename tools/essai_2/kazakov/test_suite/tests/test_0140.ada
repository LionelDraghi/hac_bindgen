--
-- ARM 13.11.6 Storage Subpool Example
--
-- Success: 121:1..188:12, 190:1..269:12 Tree *
--
-- with System.Storage_Pools.Subpools;
-- with System.Storage_Elements;
-- with Ada.Unchecked_Deallocate_Subpool;
-- package MR_Pool is
--    use System.Storage_Pools;
--    use System.Storage_Elements;
--    subtype Subpool_Handle is Subpools.Subpool_Handle;
--    type Mark_Release_Pool_Type (Pool_Size : Storage_Count) is new
--       Subpools.Root_Storage_Pool_With_Subpools with private;
--    function Mark (Pool : in out Mark_Release_Pool_Type)
--       return not null Subpool_Handle;
--    procedure Release (Subpool : in out Subpool_Handle) renames
--       Ada.Unchecked_Deallocate_Subpool;
-- private
--    type MR_Subpool is new Subpools.Root_Subpool with record
--       Start : Storage_Count;
--    end record;
--    subtype Subpool_Indexes is Positive range 1..10;
--    type Subpool_Array is array (Subpool_Indexes) of aliased MR_Subpool;
--    type Mark_Release_Pool_Type (Pool_Size : Storage_Count) is new
--       Subpools.Root_Storage_Pool_With_Subpools with record
--       Storage         : Storage_Array (0..(Pool_Size - 1));
--       Next_Allocation : Storage_Count := 0;
--       Markers         : Subpool_Array;
--       Current_Pool    : Subpool_Indexes := 1;
--    end record;
--    overriding
--    function Create_Subpool (Pool : in out Mark_Release_Pool_Type)
--       return not null Subpool_Handle;
--    function Mark (Pool : in out Mark_Release_Pool_Type)
--       return not null Subpool_Handle renames Create_Subpool;
--    overriding
--    procedure Allocate_From_Subpool (Pool : in out Mark_Release_Pool_Type;
--       Storage_Address : out System.Address;
--       Size_In_Storage_Elements : Storage_Count;
--       Alignment : Storage_Count;
--       Subpool : not null Subpool_Handle);
-- overriding
--    procedure Deallocate_Subpool (Pool : in out Mark_Release_Pool_Type;
--       Subpool : in out Subpool_Handle);
--    overriding
--    function Default_Subpool_for_Pool (Pool : in out Mark_Release_Pool_Type)
--       return not null Subpool_Handle;
--    overriding
--    procedure Initialize (Pool : in out Mark_Release_Pool_Type);
-- end MR_Pool;
-- package body MR_Pool is
--    use type Subpool_Handle;
--    procedure Initialize (Pool : in out Mark_Release_Pool_Type) is
--    begin
--       Pool.Markers (1).Start := 1;
--       Subpools.Set_Pool_of_Subpool
--          (Pool.Markers (1)'Unchecked_Access, Pool);
--    end Initialize;
--    function Create_Subpool (Pool : in out Mark_Release_Pool_Type)
--       return not null Subpool_Handle is
--    begin
--       if (Pool.Current_Pool = Subpool_Indexes'Last) then
--          raise Storage_Error;
--       end if;
--       Pool.Current_Pool := (Pool.Current_Pool + 1);
--       return Result : constant not null Subpool_Handle :=
--          Pool.Markers (Pool.Current_Pool)'Unchecked_Access
--       do
--          Pool.Markers (Pool.Current_Pool).Start := Pool.Next_Allocation;
--          Subpools.Set_Pool_of_Subpool (Result, Pool);
--       end return;
--    end Create_Subpool;
--    procedure Deallocate_Subpool (Pool : in out Mark_Release_Pool_Type;
--       Subpool : in out Subpool_Handle) is
--    begin
--       if (Subpool /= Pool.Markers (Pool.Current_Pool)'Unchecked_Access) then
--          raise Program_Error;
--       end if;
--       if (Pool.Current_Pool /= 1) then
--          Pool.Next_Allocation := Pool.Markers (Pool.Current_Pool).Start;
--          Pool.Current_Pool := (Pool.Current_Pool - 1);
--       else
--          Pool.Next_Allocation := 1;
--          Subpools.Set_Pool_of_Subpool
--             (Pool.Markers (1)'Unchecked_Access, Pool);
--       end if;
--    end Deallocate_Subpool;
--    function Default_Subpool_for_Pool (Pool : in out Mark_Release_Pool_Type)
--       return not null Subpool_Handle is
--    begin
--       return Pool.Markers (Pool.Current_Pool)'Unchecked_Access;
--    end Default_Subpool_for_Pool;
--    procedure Allocate_From_Subpool (Pool : in out Mark_Release_Pool_Type;
--       Storage_Address : out System.Address;
--       Size_In_Storage_Elements : Storage_Count;
--       Alignment : Storage_Count;
--       Subpool : not null Subpool_Handle) is
--    begin
--       if (Subpool /= Pool.Markers (Pool.Current_Pool)'Unchecked_Access) then
--          raise Program_Error;
--       end if;
--       if (Alignment > Pool.Storage'Alignment) then
--          raise Program_Error;
--       end if;
--       Pool.Next_Allocation := (Pool.Next_Allocation +
--          (-(Pool.Next_Allocation) mod Alignment));
--       if ((Pool.Next_Allocation + Size_In_Storage_Elements) >
--          Pool.Pool_Size) then
--          raise Storage_Error;
--       end if;
--       Storage_Address := Pool.Storage (Pool.Next_Allocation)'Address;
--       Pool.Next_Allocation :=
--          (Pool.Next_Allocation + Size_In_Storage_Elements);
--    end Allocate_From_Subpool;
-- end MR_Pool;
--
with System.Storage_Pools.Subpools;
with System.Storage_Elements;
with Ada.Unchecked_Deallocate_Subpool;
package MR_Pool is

   use System.Storage_Pools;
      -- For uses of Subpools.
   use System.Storage_Elements;
      -- For uses of Storage_Count and Storage_Array.

   -- Mark and Release work in a stack fashion, and allocations are not allowed
   -- from a subpool other than the one at the top of the stack. This is also
   -- the default pool.

   subtype Subpool_Handle is Subpools.Subpool_Handle;

   type Mark_Release_Pool_Type (Pool_Size : Storage_Count) is new
      Subpools.Root_Storage_Pool_With_Subpools with private;

   function Mark (Pool : in out Mark_Release_Pool_Type)
      return not null Subpool_Handle;

   procedure Release (Subpool : in out Subpool_Handle) renames
      Ada.Unchecked_Deallocate_Subpool;

private

   type MR_Subpool is new Subpools.Root_Subpool with record
      Start : Storage_Count;
   end record;
   subtype Subpool_Indexes is Positive range 1 .. 10;
   type Subpool_Array is array (Subpool_Indexes) of aliased MR_Subpool;

   type Mark_Release_Pool_Type (Pool_Size : Storage_Count) is new
      Subpools.Root_Storage_Pool_With_Subpools with record
      Storage         : Storage_Array (0 .. Pool_Size-1);
      Next_Allocation : Storage_Count := 0;
      Markers         : Subpool_Array;
      Current_Pool    : Subpool_Indexes := 1;
   end record;

   overriding
   function Create_Subpool (Pool : in out Mark_Release_Pool_Type)
      return not null Subpool_Handle;

   function Mark (Pool : in out Mark_Release_Pool_Type)
      return not null Subpool_Handle renames Create_Subpool;

   overriding
   procedure Allocate_From_Subpool (
      Pool : in out Mark_Release_Pool_Type;
      Storage_Address : out System.Address;
      Size_In_Storage_Elements : in Storage_Count;
      Alignment : in Storage_Count;
      Subpool : not null Subpool_Handle);

   overriding
   procedure Deallocate_Subpool (
      Pool : in out Mark_Release_Pool_Type;
      Subpool : in out Subpool_Handle);

   overriding
   function Default_Subpool_for_Pool (Pool : in out Mark_Release_Pool_Type)
      return not null Subpool_Handle;

   overriding
   procedure Initialize (Pool : in out Mark_Release_Pool_Type);

   -- We don't need Finalize.

end MR_Pool;

package body MR_Pool is

   use type Subpool_Handle;

   procedure Initialize (Pool : in out Mark_Release_Pool_Type) is
      -- Initialize the first default subpool.
   begin
      Pool.Markers(1).Start := 1;
      Subpools.Set_Pool_of_Subpool
         (Pool.Markers(1)'Unchecked_Access, Pool);
   end Initialize;

   function Create_Subpool (Pool : in out Mark_Release_Pool_Type)
      return not null Subpool_Handle is
      -- Mark the current allocation location.
   begin
      if Pool.Current_Pool = Subpool_Indexes'Last then
         raise Storage_Error; -- No more subpools.
      end if;
      Pool.Current_Pool := Pool.Current_Pool + 1; -- Move to the next subpool

      return Result : constant not null Subpool_Handle :=
         Pool.Markers(Pool.Current_Pool)'Unchecked_Access
      do
         Pool.Markers(Pool.Current_Pool).Start := Pool.Next_Allocation;
         Subpools.Set_Pool_of_Subpool (Result, Pool);
      end return;
   end Create_Subpool;

   procedure Deallocate_Subpool (
      Pool : in out Mark_Release_Pool_Type;
      Subpool : in out Subpool_Handle) is
   begin
      if Subpool /= Pool.Markers(Pool.Current_Pool)'Unchecked_Access then
         raise Program_Error; -- Only the last marked subpool can be released.
      end if;
      if Pool.Current_Pool /= 1 then
         Pool.Next_Allocation := Pool.Markers(Pool.Current_Pool).Start;
         Pool.Current_Pool := Pool.Current_Pool - 1; -- Move to the previous subpool
      else -- Reinitialize the default subpool:
         Pool.Next_Allocation := 1;
         Subpools.Set_Pool_of_Subpool
            (Pool.Markers(1)'Unchecked_Access, Pool);
      end if;
   end Deallocate_Subpool;

   function Default_Subpool_for_Pool (Pool : in out Mark_Release_Pool_Type)
      return not null Subpool_Handle is
   begin
      return Pool.Markers(Pool.Current_Pool)'Unchecked_Access;
   end Default_Subpool_for_Pool;

   procedure Allocate_From_Subpool (
      Pool : in out Mark_Release_Pool_Type;
      Storage_Address : out System.Address;
      Size_In_Storage_Elements : in Storage_Count;
      Alignment : in Storage_Count;
      Subpool : not null Subpool_Handle) is
   begin
      if Subpool /= Pool.Markers(Pool.Current_Pool)'Unchecked_Access then
         raise Program_Error; -- Only the last marked subpool can be used for allocations.
      end if;

      -- Check for the maximum supported alignment, which is the alignment of the storage area:
      if Alignment > Pool.Storage'Alignment then
         raise Program_Error;
      end if;
      -- Correct the alignment if necessary:
      Pool.Next_Allocation := Pool.Next_Allocation +
         ((-Pool.Next_Allocation) mod Alignment);
      if Pool.Next_Allocation + Size_In_Storage_Elements >
         Pool.Pool_Size then
         raise Storage_Error; -- Out of space.
      end if;
      Storage_Address := Pool.Storage (Pool.Next_Allocation)'Address;
      Pool.Next_Allocation :=
         Pool.Next_Allocation + Size_In_Storage_Elements;
   end Allocate_From_Subpool;

end MR_Pool;