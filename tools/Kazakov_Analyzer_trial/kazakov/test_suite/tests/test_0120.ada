--
-- ARM 10.1.2(11) Context Clauses - With Clauses
--
-- Success: 18:1..19:6, 21:1..22:8, 24:9..25:10, 27:1..28:12, 31:9..32:10, 34:1..35:10, 38:1..39:10, 42:1..43:10 Tree *
--
-- package A is end A;
-- package A.B is end A.B;
-- private package A.B.C is end A.B.C;
-- package A.B.C.D is end A.B.C.D;
-- with A.B.C;
-- private package A.B.X is end A.B.X;
-- package A.B.Y is end A.B.Y;
-- with A.B.C;
-- package body A.B.Y is end A.B.Y;
-- private with A.B.C;
-- package A.B.Z is end A.B.Z;
--
package A is
end A;

package A.B is
end A.B;

private package A.B.C is
end A.B.C;

package A.B.C.D is
end A.B.C.D;

with A.B.C; -- (1)
private package A.B.X is
end A.B.X;

package A.B.Y is
end A.B.Y;

with A.B.C; -- (2)
package body A.B.Y is
end A.B.Y;

private with A.B.C; -- (3)
package A.B.Z is
end A.B.Z;