------------------------------------------------------------------------------
--  ECS.Worlds  --  entity lifetime, signatures, and the detach table.
--
--  ONE WORLD PER INSTANTIATION.  The state lives in the package body, not in
--  a World type.  This is a deliberate v1 restriction: making World a type
--  would require pools to be components of it, and pools are separately
--  instantiated generics with different component types -- which is exactly
--  the heterogeneous-storage problem a statically typed language cannot
--  solve without byte blobs.  Two worlds means two instantiations.
--
--  No storage formals: the registry is dense (every slot exists), so a flat
--  array sized from Max_Entities is right on both targets.  Only pools need
--  the Sequences/Sparse_Maps machinery.
--
--  Sig is stored per entity even though it duplicates what the pools know.
--  Its entire justification is that query matching becomes one bitwise AND
--  per entity instead of N pool lookups.  The cost is that every Set/Unset
--  must keep it in sync, which is why all mutation routes through here.
------------------------------------------------------------------------------

generic
   type Component_Kind is (<>);
   Max_Entities : Positive;
package ECS.Worlds is

   pragma Elaborate_Body;

   type Signature is array (Component_Kind) of Boolean with Pack;

   Empty_Signature : constant Signature := [others => False];

   function Only (K : Component_Kind) return Signature;

   --  Mask_Of exists so that application code never needs a `use type` for
   --  the array `or`.  Overloads cover the realistic arities; beyond four,
   --  build the signature by assignment.
   function Mask_Of (K1 : Component_Kind) return Signature;
   function Mask_Of (K1, K2 : Component_Kind) return Signature;
   function Mask_Of (K1, K2, K3 : Component_Kind) return Signature;
   function Mask_Of (K1, K2, K3, K4 : Component_Kind) return Signature;

   function Contains (Sig, Mask : Signature) return Boolean
     is ((Sig and Mask) = Mask)
     with Inline;

   ---------------------------------------------------------------------------
   --  Entity lifetime
   ---------------------------------------------------------------------------

   procedure Clear;
   --  Resets everything: all entities destroyed, all pools detached, free
   --  list refilled.  Called automatically at elaboration.

   function Create return Entity;
   --  Returns No_Entity when the world is full.  Explicit, never raises.

   procedure Destroy (E : Entity);
   --  Detaches every component this entity holds (via the registered
   --  handlers), then bumps the generation and recycles the slot.
   --  A no-op on a stale or null handle.

   function Alive (E : Entity) return Boolean with Inline;
   --  False for a handle whose slot has since been recycled.  This is the
   --  entire point of the generation field.

   function Live_Count return Natural with Inline;

   function Capacity return Natural is (Max_Entities);

   ---------------------------------------------------------------------------
   --  Signatures
   ---------------------------------------------------------------------------

   function Signature_Of (E : Entity) return Signature;

   function Matches (E : Entity; Mask : Signature) return Boolean;

   function Entity_At (Index : Entity_Index) return Entity;
   --  Rebuilds a full handle from a slot number by attaching the current
   --  generation.  Returns No_Entity for a dead or out-of-range slot.
   --  This is why pools store Entity_Index and not Entity.

   ---------------------------------------------------------------------------
   --  Slot-level iteration, for ECS.Queries
   ---------------------------------------------------------------------------

   function Last_Slot return Entity_Index is (Entity_Index (Max_Entities));

   function Is_Live_Slot (Index : Entity_Index) return Boolean with Inline;

   function Signature_At (Index : Entity_Index) return Signature with Inline;

   ---------------------------------------------------------------------------
   --  Pool plumbing.  Called by ECS.Pools, not by application code.
   ---------------------------------------------------------------------------

   type Detach_Handler is access procedure (Index : Entity_Index);

   procedure Register_Component (K : Component_Kind; Handler : Detach_Handler);
   --  Each pool registers itself at elaboration so that Destroy can reach it.

   procedure Note_Added   (E : Entity; K : Component_Kind);
   procedure Note_Removed (E : Entity; K : Component_Kind);

private

   subtype Index_Range is Entity_Index range 1 .. Entity_Index (Max_Entities);

   type Slot_Record is record
      Generation : Generation_Id := 1;
      --  Starts at 1 so that No_Entity, which carries generation 0, never
      --  matches a live slot.
      Sig        : Signature     := Empty_Signature;
      Live       : Boolean       := False;
   end record;

   type Slot_Array is array (Index_Range) of Slot_Record;
   type Free_Array is array (Index_Range) of Entity_Index;

end ECS.Worlds;
