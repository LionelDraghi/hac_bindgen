--
-- 8.4(7) Use Clauses
--
-- Success: 22:1..24:6, 27:1..31:11, 33:1..38:17 Tree *
--
-- package P is
--     type T is range 1..10;
-- end P;
-- with P;
-- package Parent is
-- private
--     use P;
--     X : T;
-- end Parent;
-- package Parent.Child is
--     Y : T;
--     Z : P.T;
-- private
--     W : T;
-- end Parent.Child;
--
package P is
    type T is range 1..10;
end P;

with P;
package Parent is
private
    use P;
    X : T;
end Parent;

package Parent.Child is
    Y : T; -- Illegal!
    Z : P.T;
private
    W : T;
end Parent.Child;