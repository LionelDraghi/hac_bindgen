--
-- ARM 3.10.2(22) Operations of Access Types
--
-- Success: 22:1..36:6 Tree *
--
-- package P is
--     type Int_Ptr is access all Integer;
--     type Rec (D : access Integer) is limited private;
-- private
--     type Rec_Ptr is access all Rec;
--     function F (X : Rec_Ptr) return Boolean;
--     function G (X : access Rec) return Boolean;
--     type Rec (D : access Integer) is
--         limited record
--             C1 : Int_Ptr := Int_Ptr (D);
--             C2 : Rec_Ptr := Rec'Access;
--             C3 : Boolean := F (Rec'Access);
--             C4 : Boolean := G (Rec'Access);
--         end record;
-- end P;
--
package P is
    type Int_Ptr is access all Integer;
    type Rec(D: access Integer) is limited private;
private
    type Rec_Ptr is access all Rec;
    function F(X: Rec_Ptr) return Boolean;
    function G(X: access Rec) return Boolean;
    type Rec(D: access Integer) is
        limited record
            C1: Int_Ptr := Int_Ptr(D); -- Illegal!
            C2: Rec_Ptr := Rec'Access; -- Illegal!
            C3: Boolean := F(Rec'Access); -- Illegal!
            C4: Boolean := G(Rec'Access);
        end record;
end P;