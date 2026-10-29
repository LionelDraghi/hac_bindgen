--
-- ARM 8.3(26) Visibility
--
-- Success: 21:1..22:6, 24:1..25:8, 27:1..30:6, 34:1..37:8 Tree *
--
-- package P is
-- end P;
-- package P.Q is
-- end P.Q;
-- package body P is
--     Q : Integer;
--     procedure Sub is separate;
-- end P;
-- with P.Q;
-- separate (P)
-- procedure Sub is
-- begin
--     null;
-- end Sub;
--
package P is
end P;

package P.Q is
end P.Q;

package body P is
    Q : Integer; -- OK; we cannot see package P.Q here.
    procedure Sub is separate;
end P;

with P.Q;
separate(P)
procedure Sub is -- Illegal.
begin
    null;
end Sub;