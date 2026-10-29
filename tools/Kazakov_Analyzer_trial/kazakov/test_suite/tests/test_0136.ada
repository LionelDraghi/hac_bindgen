--
-- ARM 13.7.2 The Package System.Address_To_Access_Conversions
--
-- Success: 19:1..28:41 Tree *
--
-- generic
--    type Object (<>) is limited private;
-- package System.Address_To_Access_Conversions
--    with Preelaborate, Nonblocking, Global => in out synchronized is
--    type Object_Pointer is access all Object;
--    function To_Pointer (Value : Address) return Object_Pointer
--       with Convention => Intrinsic;
--    function To_Address (Value : Object_Pointer) return Address
--       with Convention => Intrinsic;
--  end System.Address_To_Access_Conversions;
--
generic
   type Object(<>) is limited private;
package System.Address_To_Access_Conversions
   with Preelaborate, Nonblocking, Global => in out synchronized is

   type Object_Pointer is access all Object;
   function To_Pointer(Value : Address) return Object_Pointer
      with Convention => Intrinsic;
   function To_Address(Value : Object_Pointer) return Address
      with Convention => Intrinsic;

end System.Address_To_Access_Conversions;