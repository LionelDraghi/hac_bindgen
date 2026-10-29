--
-- ARM 3.8.1(15 b) Variant Parts and Discrete Choices
--
-- Success: 21:1..30:6 Tree *
--
-- generic
--    type T is new Integer;
-- package G is
--    type Rec (Discrim : T) is record
--       case Discrim is
--          when -(10)..-(1) =>
--             Foo : Float;
--          when others =>
--             null;
--       end case;
--    end record;
-- end G;
--
generic
   type T is new Integer;
package G is
   type Rec (Discrim : T) is record
      case Discrim is
         when -10 .. -1 =>
            Foo : Float;
         when others =>
            null;
      end case;
   end record;
end G;