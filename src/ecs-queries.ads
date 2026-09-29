------------------------------------------------------------------------------
--  ECS.Queries  --  find entities matching a component mask.
--
--  This is the REGISTRY-SCAN strategy: walk 1 .. Max_Entities and test each
--  live slot's signature.  Cost is O(Max_Entities) regardless of how many
--  entities match.  Correct on embedded, wrong at four million entities
--  where twelve match.
--
--  The other strategy -- drive from the shortest pool named in the mask --
--  cannot be written generically here, because pools are separate
--  instantiations with unrelated component types.  Write it inline instead;
--  it is four lines:
--
--     for I in reverse 1 .. Positions.Count loop
--        E := Positions.Owner (I);
--        if W.Matches (E, Mask) then ... end if;
--     end loop;
--
--  Reverse, because Unset moves the tail into the current slot.
------------------------------------------------------------------------------

with ECS.Worlds;

generic
   with package W is new ECS.Worlds (<>);
package ECS.Queries is

   type Cursor is private;

   function First (Mask : W.Signature) return Cursor;

   function Has_Element (C : Cursor) return Boolean with Inline;

   function Element (C : Cursor) return Entity
     with Pre => Has_Element (C);

   procedure Next (C : in out Cursor);

   function Count (Mask : W.Signature) return Natural;

private

   type Cursor is record
      Mask  : W.Signature;
      Slot  : Entity_Index := 0;
      Valid : Boolean      := False;
   end record;

end ECS.Queries;
