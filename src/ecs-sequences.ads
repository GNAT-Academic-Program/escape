------------------------------------------------------------------------------
--  ECS.Sequences  --  the storage contract.  Signature package: no body,
--  nothing implements it, it exists so that consumers can name it in a
--  formal_package_declaration.
--
--  A Sequence is a dense indexed array of Element with O(1) Append and
--  O(1) unordered removal.  That is the whole abstraction.
--
--  IMPORTANT: Swap_Remove does NOT preserve order.  No ECS code above this
--  layer may assume iteration order.
--
--  Append carries Ok rather than raising: the bounded implementation returns
--  False when full, the unbounded one grows and always returns True.  No
--  exception ever crosses this boundary.
------------------------------------------------------------------------------

generic
   type Element  is private;
   type Sequence is limited private;

   with procedure Clear (S : in out Sequence) is <>;
   --  Also serves as initialisation: Sequence is limited private here, so
   --  nothing guarantees default initialisation.  Consumers MUST call Clear
   --  before first use.

   with function Length (S : Sequence) return Natural is <>;

   with function Item (S : Sequence; I : Positive) return Element is <>;

   with procedure Replace (S : in out Sequence; I : Positive; E : Element) is <>;

   with procedure Append (S : in out Sequence; E : Element; Ok : out Boolean) is <>;

   with procedure Swap_Remove (S : in out Sequence; I : Positive) is <>;
   --  Moves the last element into slot I, then shortens by one.

package ECS.Sequences is
end ECS.Sequences;
