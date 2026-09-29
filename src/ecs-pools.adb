------------------------------------------------------------------------------
--  ECS.Pools body.  THE PROJECT.
--
--  Everything in the seed compiles and the tests run, but the five
--  operations below (Has, Get, Set, Unset, Detach) are placeholders that
--  do nothing useful.  The test suite fails on them.  Making it pass,
--  without changing the spec and without breaking Check_Invariant, is
--  milestone 1.
--
--  You are not designing the data structure.  It is designed; the design
--  is in ARCHITECTURE.md and in the spec's header comment.  Three arrays:
--
--     S : Sparse   entity index -> dense slot, 0 = absent   (fixed domain)
--     O : Owners   dense slot   -> entity index             (a Sequence)
--     V : Values   dense slot   -> Component                (a Sequence)
--
--  and one invariant that every operation must preserve:
--
--     for every I in 1 .. Count :  Lookup (S, Item (O, I)) = I
--     and  Length (O) = Length (V)
--
--  Check_Invariant below is the oracle.  The tests call it after every
--  mutation.  If your Unset is wrong it will tell you on the next line.
--
--  What "lesser" designs look like, so you recognise them and do not
--  write them: a linear search over Owners in Has/Get (that is O(n), the
--  point of Sparse is O(1)); shifting the dense arrays down on remove
--  (O(n), and it breaks the reverse-iteration convention); storing the
--  whole Entity in Owners instead of Entity_Index (wastes the generation
--  and duplicates what the world knows); touching the world signature
--  from Detach (see its comment).
------------------------------------------------------------------------------

package body ECS.Pools is

   V : Values.Sequence;
   O : Owners.Sequence;
   S : Sparse.Map;

   procedure Detach (Index : Entity_Index);
   --  Storage-only removal.  Deliberately does NOT touch the world
   --  signature: W.Destroy calls this while it is already clearing the
   --  whole signature, and calling Note_Removed there would be redundant
   --  work at best and a reentrancy trap at worst.

   ----------
   -- Mask --
   ----------

   function Mask return W.Signature is (W.Only (Kind));

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      Values.Clear (V);
      Owners.Clear (O);
      Sparse.Clear (S);
   end Clear;

   -----------
   -- Count --
   -----------

   function Count return Natural is (Owners.Length (O));

   ---------
   -- Has --
   ---------

   --  TODO milestone 1.
   --  Alive (E) and then Lookup (S, E.Index) /= 0.  Two reads, no loop.
   --  The Alive check matters: a stale handle whose slot was recycled
   --  must not see the new occupant's component.

   function Has (E : Entity) return Boolean is
      pragma Unreferenced (E);
   begin
      return False;
   end Has;

   ---------
   -- Get --
   ---------

   --  TODO milestone 1.
   --  Item (V, Lookup (S, E.Index)).  The precondition Has (E) guarantees
   --  the slot is non-zero; do not re-check it here.

   function Get (E : Entity) return Component is
      pragma Unreferenced (E);
      None : Component;
      pragma Warnings (Off, None);   --  placeholder: never reached
   begin
      raise Program_Error with "Pools.Get: milestone 1 not implemented";
      return None;
   end Get;

   -----------
   -- Owner --
   -----------

   function Owner (I : Positive) return Entity is
     (W.Entity_At (Owners.Item (O, I)));

   -----------
   -- Value --
   -----------

   function Value (I : Positive) return Component is (Values.Item (V, I));

   ------------
   -- Update --
   ------------

   procedure Update (I : Positive; To : Component) is
   begin
      Values.Replace (V, I, To);
   end Update;

   ---------
   -- Set --
   ---------

   --  TODO milestone 1.  Steps, in this order:
   --    1. not Alive (E)            -> Ok := False, return.
   --    2. Lookup (S, E.Index) /= 0 -> overwrite: Replace (V, slot, To),
   --                                   Ok := True, return.  No new row.
   --    3. Append (O, E.Index, Ok); if not Ok return.       (capacity)
   --    4. Append (V, To, Ok); if not Ok: undo step 3 with
   --       Swap_Remove (O, Length (O)) and return.  O and V must never
   --       disagree in length, not even for one statement.
   --    5. Assign (S, E.Index, Length (O)).      The back-pointer.
   --    6. W.Note_Added (E, Kind).                Keep the signature in sync.

   procedure Set (E : Entity; To : Component; Ok : out Boolean) is
      pragma Unreferenced (E, To);
   begin
      Ok := False;
   end Set;

   -----------
   -- Unset --
   -----------

   --  TODO milestone 1.
   --  Not Alive, or Lookup = 0 -> return (no-op on absent).
   --  Otherwise Detach (E.Index) then W.Note_Removed (E, Kind).
   --  Note_Removed after Detach, and only here, never in Detach.

   procedure Unset (E : Entity) is
      pragma Unreferenced (E);
   begin
      null;
   end Unset;

   ------------
   -- Detach --
   ------------

   --  TODO milestone 1.  This is the one that bites.  Steps:
   --    1. Slot_No := Lookup (S, Index); if 0 return.
   --    2. Swap_Remove (O, Slot_No); Swap_Remove (V, Slot_No).
   --       The LAST row has just been moved into Slot_No.
   --    3. THE FIXUP: if Slot_No <= Length (O) (i.e. the removed row was
   --       not itself the last), the row now at Slot_No belongs to
   --       Item (O, Slot_No), whose back-pointer in S still says the old
   --       last slot.  Assign (S, Item (O, Slot_No), Slot_No).
   --       Omit this and nothing fails today; an entity reads another
   --       entity's data a thousand operations from now.
   --    4. Assign (S, Index, 0).  The removed entity has no slot.

   procedure Detach (Index : Entity_Index) is
      pragma Unreferenced (Index);
   begin
      null;
   end Detach;

   ---------------------
   -- Check_Invariant --
   ---------------------

   --  The oracle.  Kept complete on purpose.

   function Check_Invariant return Boolean is
   begin
      if Owners.Length (O) /= Values.Length (V) then
         return False;
      end if;

      for I in 1 .. Owners.Length (O) loop
         if Sparse.Lookup (S, Owners.Item (O, I)) /= I then
            return False;
         end if;
      end loop;

      return True;
   end Check_Invariant;

begin
   Clear;
   W.Register_Component (Kind, Detach'Access);
end ECS.Pools;
