--
-- ARM 3.2.4 Subtype Predicates
--
-- Success: 13:1..19:33 Tree *
-- 
--  package ARM_3_2_4.Subtype_Predicates is
--     type Really_Ugly is private;
--  private
--     subtype Ugly is Really_Ugly;
--     type Really_Ugly is new Integer with Static_Predicate => Really_Ugly not in Ugly;
--  end ARM_3_2_4.Subtype_Predicates;
--
package ARM_3_2_4.Subtype_Predicates is
   type Really_Ugly is private;
private
   subtype Ugly is Really_Ugly;
   type Really_Ugly is new Integer
      with Static_Predicate => Really_Ugly not in Ugly; -- Illegal!
end ARM_3_2_4.Subtype_Predicates;