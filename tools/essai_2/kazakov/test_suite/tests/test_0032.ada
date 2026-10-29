--
-- ARM 3.9_3(15) Abstract Types and Subprograms
--
-- Success: 17:1..26:9 Tree *
--
-- package Sets is
--     subtype Element_Type is Natural;
--     type Set is abstract tagged null record;
--     function Empty return Set is abstract;
--     function Union (Left, Right : Set) return Set is abstract;
--     function Intersection (Left, Right : Set) return Set is abstract;
--     function Unit_Set (Element : Element_Type) return Set is abstract;
--     procedure Take (Element : out Element_Type;
--                    From : in out Set) is abstract;
-- end Sets;
--
package Sets is
    subtype Element_Type is Natural;
    type Set is abstract tagged null record;
    function Empty return Set is abstract;
    function Union(Left, Right : Set) return Set is abstract;
    function Intersection(Left, Right : Set) return Set is abstract;
    function Unit_Set(Element : Element_Type) return Set is abstract;
    procedure Take(Element : out Element_Type;
                   From : in out Set) is abstract;
end Sets;