--
-- ARM 3.9(18) Tagged Types and Type Extensions
--
-- Success: 22:1..26:51 Tree *
--
-- generic
--     type T (<>) is abstract tagged limited private;
--     type Parameters (<>) is limited private;
--     with function Constructor (Params : not null access Parameters)
--         return T is abstract;
-- function Ada.Tags.Generic_Dispatching_Constructor
--    (The_Tag : Tag;
--     Params  : not null access Parameters) return T'Class
--    with Preelaborate, Convention => Intrinsic,
--         Nonblocking, Global => in out synchronized;
--
generic
    type T (<>) is abstract tagged limited private;
    type Parameters (<>) is limited private;
    with function Constructor (Params : not null access Parameters)
        return T is abstract;
function Ada.Tags.Generic_Dispatching_Constructor
   (The_Tag : Tag;
    Params  : not null access Parameters) return T'Class
   with Preelaborate, Convention => Intrinsic,
        Nonblocking, Global => in out synchronized;