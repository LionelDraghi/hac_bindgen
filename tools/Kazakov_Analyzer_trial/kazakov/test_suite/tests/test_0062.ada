--
-- ARM 5.5.1 User-Defined Iterator Types
--
-- Success: 50:1..96:28 Tree *
--
-- generic
--    type Cursor;
--    with function Has_Element (Position : Cursor) return Boolean;
-- package Ada.Iterator_Interfaces
--    with Pure, Nonblocking => False is
--    type Forward_Iterator is limited interface;
--    function First (Object : Forward_Iterator) return Cursor is abstract;
--    function Next (Object : Forward_Iterator; Position : Cursor)
--       return Cursor is abstract;
--    type Reversible_Iterator is limited interface and Forward_Iterator;
--    function Last (Object : Reversible_Iterator) return Cursor is abstract;
--    function Previous (Object : Reversible_Iterator; Position : Cursor)
--       return Cursor is abstract;
--    type Parallel_Iterator is limited interface and Forward_Iterator;
--    subtype Chunk_Index is Positive;
--    function Is_Split (Object : Parallel_Iterator)
--       return Boolean is abstract;
--    procedure Split_Into_Chunks (Object     : in out Parallel_Iterator;
--                                 Max_Chunks :      Chunk_Index) is abstract
--       with Pre'Class   => (not (Object.Is_Split) or else (raise Program_Error)),
--            Post'Class  => (Object.Is_Split and then
--                           (Object.Chunk_Count <= Max_Chunks));
--    function Chunk_Count (Object : Parallel_Iterator)
--       return Chunk_Index is abstract
--       with Pre'Class   => (Object.Is_Split or else (raise Program_Error));
-- 
--    function First (Object : Parallel_Iterator;
--                    Chunk  : Chunk_Index) return Cursor is abstract
--       with Pre'Class   => ((Object.Is_Split and then
--                               (Chunk <= Object.Chunk_Count))
--                            or else (raise Program_Error));
--    function Next (Object   : Parallel_Iterator;
--                   Position : Cursor;
--                   Chunk    : Chunk_Index) return Cursor is abstract
--       with Pre'Class   => ((Object.Is_Split and then
--                               (Chunk <= Object.Chunk_Count))
--                            or else (raise Program_Error));
--    type Parallel_Reversible_Iterator is limited interface
--       and Parallel_Iterator and Reversible_Iterator;
-- end Ada.Iterator_Interfaces;
--
generic
   type Cursor;
   with function Has_Element (Position : Cursor) return Boolean;
package Ada.Iterator_Interfaces
   with Pure, Nonblocking => False is

   type Forward_Iterator is limited interface;
   function First (Object : Forward_Iterator) return Cursor is abstract;
   function Next (Object : Forward_Iterator; Position : Cursor)
      return Cursor is abstract;

   type Reversible_Iterator is limited interface and Forward_Iterator;
   function Last (Object : Reversible_Iterator) return Cursor is abstract;
   function Previous (Object : Reversible_Iterator; Position : Cursor)
      return Cursor is abstract;

   type Parallel_Iterator is limited interface and Forward_Iterator;

   subtype Chunk_Index is Positive;

   function Is_Split (Object : Parallel_Iterator)
      return Boolean is abstract;

   procedure Split_Into_Chunks (Object     : in out Parallel_Iterator;
                                Max_Chunks : in     Chunk_Index) is abstract
      with Pre'Class   => not Object.Is_Split or else raise Program_Error,
           Post'Class  => Object.Is_Split and then
                          Object.Chunk_Count <= Max_Chunks;

   function Chunk_Count (Object : Parallel_Iterator)
      return Chunk_Index is abstract
      with Pre'Class   => Object.Is_Split or else raise Program_Error;

   function First (Object : Parallel_Iterator;
                   Chunk  : Chunk_Index) return Cursor is abstract
      with Pre'Class   => (Object.Is_Split and then
                              Chunk <= Object.Chunk_Count)
                           or else raise Program_Error;

   function Next (Object   : Parallel_Iterator;
                  Position : Cursor;
                  Chunk    : Chunk_Index) return Cursor is abstract
      with Pre'Class   => (Object.Is_Split and then
                              Chunk <= Object.Chunk_Count)
                           or else raise Program_Error;

   type Parallel_Reversible_Iterator is limited interface
      and Parallel_Iterator and Reversible_Iterator;

end Ada.Iterator_Interfaces;