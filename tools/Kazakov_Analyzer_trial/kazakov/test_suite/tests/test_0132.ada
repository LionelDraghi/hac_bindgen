--
-- ARM 11.3 Raise Statements and Raise Expressions
--
-- Success: 22:1..41:13 Tree *
--
-- procedure ARM_11_3 is
--    Obj : Boolean := (Func_Call or else (raise TBD_Error)) with Atomic;
--    Obj : Boolean := (Func_Call or else (raise TBD_Error)) with Atomic;
--    Obj : Boolean := (Func_Call or else (raise TBD_Error with Atomic));
--    Obj : Boolean := (Func_Call or else (raise TBD_Error with Atomic));
--    Pre : Boolean  := (if not (Is_Valid (Param)) then (raise Not_Valid_Error));
--    A : A_Tagged   := (Some_Tagged'((raise TBD_Error)) with Comp => 'A');
--    B : Some_Array := (1, 2, 3, others => (raise Not_Valid_Error));
--    C : Natural    := Func (Val => (raise TBD_Error));
--    D : A_Tagged   := ((raise TBD_Error) with Comp => 'A');
-- begin
--    raise Ada.IO_Exceptions.Name_Error;
--    raise Queue_Error with "Buffer Full"; exception when others =>
--    raise;
-- end ARM_11_3;
--
procedure ARM_11_3 is
   Obj : Boolean := Func_Call or else (raise TBD_Error) with Atomic;
   Obj : Boolean := (Func_Call or else raise TBD_Error) with Atomic;

   Obj : Boolean := Func_Call or else (raise TBD_Error with Atomic);
   Obj : Boolean := (Func_Call or else raise TBD_Error with Atomic);

   Pre : Boolean  := (if not Is_Valid(Param) then raise Not_Valid_Error);
   A : A_Tagged   := (Some_Tagged'(raise TBD_Error) with Comp => 'A');
   B : Some_Array := (1, 2, 3, others => raise Not_Valid_Error);
   C : Natural    := Func (Val => raise TBD_Error);

   D : A_Tagged   := ((raise TBD_Error) with Comp => 'A');
begin
   raise Ada.IO_Exceptions.Name_Error;   -- see A.13
   raise Queue_Error with "Buffer Full"; -- see 9.11
exception
   when others =>
      raise;                                -- re-raise the current exceptionexception
end ARM_11_3;