------------------------------------------------------------------------------
--  ECS.Flat_Sparse_Maps  --  one array covering 1 .. Max_Entities.
--  The embedded backing for ECS.Sparse_Maps.  No allocation.
--
--  Cost: Max_Entities * Slot_Storage bytes PER COMPONENT TYPE, whether the
--  component is held by every entity or by two.  Fine at 256 entities,
--  ruinous at four million -- use ECS.Paged_Sparse_Maps there.
------------------------------------------------------------------------------

generic
   Max_Entities : Positive;
package ECS.Flat_Sparse_Maps with SPARK_Mode is

   type Map is limited private;

   procedure Clear (M : in out Map);

   function Lookup (M : Map; I : Entity_Index) return Natural with Inline;
   --  0 for any index outside 1 .. Max_Entities, and for unassigned ones.

   procedure Assign (M : in out Map; I : Entity_Index; S : Natural)
     with Pre  => I in 1 .. Entity_Index (Max_Entities),
          Post => Lookup (M, I) = S,
          Inline;

private

   subtype Index_Range is Entity_Index range 1 .. Entity_Index (Max_Entities);

   type Slot_Array is array (Index_Range) of Natural;

   type Map is limited record
      Slots : Slot_Array := [others => 0];
   end record;

end ECS.Flat_Sparse_Maps;
