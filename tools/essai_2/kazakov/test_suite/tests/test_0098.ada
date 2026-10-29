--
-- ARM 8.5.4(8) Subprogram Renaming Declarations
--
-- Success: 17:1..22:6, 25:1..27:6 Tree *
--
-- package P is
--     type T is tagged null record;
--     function Predefined_Equal (X, Y : T) return Boolean renames "=";
-- private
--     function "=" (X, Y : T) return Boolean;
-- end P;
-- with P; use P;
-- package Q is
--     function User_Defined_Equal (X, Y : T) return Boolean renames P."=";
-- end Q;
--
package P is
    type T is tagged null record;
    function Predefined_Equal(X, Y : T) return Boolean renames "=";
private
    function "="(X, Y : T) return Boolean; -- Override predefined "=".
end P;

with P; use P;
package Q is
    function User_Defined_Equal(X, Y : T) return Boolean renames P."=";
end Q;