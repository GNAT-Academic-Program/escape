------------------------------------------------------------------------------
--  ECS.Pools  --  a sparse set holding one component type.
--
--  Three arrays, one invariant:
--
--     Sparse : entity index -> dense slot (0 = absent)   fixed size
--     Owners : dense slot   -> entity index              a Sequence
--     Values : dense slot   -> Component                 a Sequence
--
--     for every slot I in 1 .. Count :  Sparse (Owners (I)) = I
--
--  Sparse and Owners point at each other.  That is the whole data structure.
--  Get is two indirections; iteration over Values is contiguous and
--  branch-free, which is what systems actually do.
--
--  Storage is package-level: one pool per instantiation, matching the
--  one-world-per-instantiation rule in ECS.Worlds.
------------------------------------------------------------------------------

with ECS.Worlds;
with ECS.Sequences;
with ECS.Sparse_Maps;

generic
   with package W is new ECS.Worlds (<>);

   type Component is private;

   Kind : W.Component_Kind;

   with package Values is new ECS.Sequences (Element => Component, others => <>);
   with package Owners is new ECS.Sequences (Element => Entity_Index, others => <>);
   with package Sparse is new ECS.Sparse_Maps (others => <>);

package ECS.Pools is

   pragma Elaborate_Body;

   function Mask return W.Signature;
   --  Convenience: the single-bit signature for this component.

   procedure Clear;

   ---------------------------------------------------------------------------
   --  Random access
   ---------------------------------------------------------------------------

   function Has (E : Entity) return Boolean with Inline;

   function Get (E : Entity) return Component
     with Pre => Has (E);

   procedure Set (E : Entity; To : Component; Ok : out Boolean);
   --  Attaches, or overwrites if already present.  Ok is False only on
   --  capacity exhaustion (bounded backing) or a dead handle.  Never raises.

   procedure Unset (E : Entity);
   --  No-op if absent.  O(1): the last dense row is moved into the hole.

   ---------------------------------------------------------------------------
   --  Dense iteration.  Slots are 1 .. Count, contiguous, NO GUARANTEED ORDER.
   --
   --  To mutate while iterating, walk downward:
   --     for I in reverse 1 .. Count loop ...
   --  An upward loop skips an element whenever Unset moves the tail into I.
   ---------------------------------------------------------------------------

   function Count return Natural with Inline;

   function Owner (I : Positive) return Entity with Pre => I <= Count;
   --  Rebuilds the full handle from the stored index via the world.

   function Value (I : Positive) return Component with Pre => I <= Count;

   procedure Update (I : Positive; To : Component) with Pre => I <= Count;

   ---------------------------------------------------------------------------
   --  Testing
   ---------------------------------------------------------------------------

   function Check_Invariant return Boolean;
   --  Verifies Sparse (Owners (I)) = I across the whole pool.  Call this
   --  after every mutation in tests.  The back-pointer fixup in Unset is the
   --  single easiest thing to get wrong in this design, and getting it wrong
   --  corrupts silently.

end ECS.Pools;
