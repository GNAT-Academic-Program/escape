package body ECS.Queries is

   procedure Advance (C : in out Cursor);

   -------------
   -- Advance --
   -------------

   procedure Advance (C : in out Cursor) is
   begin
      while C.Slot < W.Last_Slot loop
         C.Slot := C.Slot + 1;
         if W.Is_Live_Slot (C.Slot)
           and then W.Contains (W.Signature_At (C.Slot), C.Mask)
         then
            C.Valid := True;
            return;
         end if;
      end loop;

      C.Valid := False;
   end Advance;

   -----------
   -- First --
   -----------

   function First (Mask : W.Signature) return Cursor is
      C : Cursor := (Mask => Mask, Slot => 0, Valid => False);
   begin
      Advance (C);
      return C;
   end First;

   -----------------
   -- Has_Element --
   -----------------

   function Has_Element (C : Cursor) return Boolean is (C.Valid);

   -------------
   -- Element --
   -------------

   function Element (C : Cursor) return Entity is (W.Entity_At (C.Slot));

   ----------
   -- Next --
   ----------

   procedure Next (C : in out Cursor) is
   begin
      Advance (C);
   end Next;

   -----------
   -- Count --
   -----------

   function Count (Mask : W.Signature) return Natural is
      N : Natural := 0;
      C : Cursor  := First (Mask);
   begin
      while Has_Element (C) loop
         N := N + 1;
         Next (C);
      end loop;
      return N;
   end Count;

end ECS.Queries;
