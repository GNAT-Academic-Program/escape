------------------------------------------------------------------------------
--  ECS.Sparse_Maps  --  the entity-index -> dense-slot contract.
--
--  Second signature package.  Separate from Sequences because it has a
--  different shape: fixed domain, never appended to, never swap-removed.
--
--  Flat implementation for embedded (one array, no allocation).
--  Paged implementation for desktop (millions of entities x many component
--  types makes a flat array per pool unaffordable).
--
--  Slot 0 means "this entity does not have this component".
------------------------------------------------------------------------------

generic
   type Map is limited private;

   with procedure Clear (M : in out Map) is <>;
   --  Also initialisation.  Must be called before first use.

   with function Lookup (M : Map; I : Entity_Index) return Natural is <>;

   with procedure Assign (M : in out Map; I : Entity_Index; S : Natural) is <>;

package ECS.Sparse_Maps is
end ECS.Sparse_Maps;
