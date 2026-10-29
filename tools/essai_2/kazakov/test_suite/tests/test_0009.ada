--
-- ARM 3.2.4(40,41) Subtype Predicates
--
-- Success: 15:1..22:33 Tree *
--
-- package ARM_3_2_4.Subtype_Predicates is
--    subtype Basic_Letter is Character
--       with Static_Predicate => Basic_Letter in 'A'..'Z' | 'a'..'z' | 'Æ' | 
--                               'æ' | 'Ð' | 'ð' | 'Þ' | 'þ' | 'ß';
--    subtype Even_Integer is Integer
--       with Dynamic_Predicate => ((Even_Integer mod 2) = 0),
--            Predicate_Failure => "Even_Integer must be a multiple of 2";
-- end ARM_3_2_4.Subtype_Predicates;
--
package ARM_3_2_4.Subtype_Predicates is
   subtype Basic_Letter is Character -- See A.3.2 for "basic letter".
      with Static_Predicate => Basic_Letter in 'A'..'Z' | 'a'..'z' | 'Æ' | 
                               'æ' | 'Ð' | 'ð' | 'Þ' | 'þ' | 'ß';
   subtype Even_Integer is Integer
      with Dynamic_Predicate => Even_Integer mod 2 = 0,
           Predicate_Failure => "Even_Integer must be a multiple of 2";
end ARM_3_2_4.Subtype_Predicates;