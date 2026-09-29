------------------------------------------------------------------------------
--  ECS.Unbounded_Sequences  --  heap-growable.  The desktop backing for
--  ECS.Sequences.  Append always succeeds (or raises Storage_Error, which
--  is a genuinely fatal condition, not a capacity signal).
------------------------------------------------------------------------------

with Ada.Containers.Vectors;

generic
   type Element is private;
package ECS.Unbounded_Sequences is

   type Sequence is limited private;

   procedure Clear (S : in out Sequence) with Inline;

   function Length (S : Sequence) return Natural with Inline;

   function Item (S : Sequence; I : Positive) return Element
     with Pre => I <= Length (S), Inline;

   procedure Replace (S : in out Sequence; I : Positive; E : Element)
     with Pre => I <= Length (S), Inline;

   procedure Append (S : in out Sequence; E : Element; Ok : out Boolean);

   procedure Swap_Remove (S : in out Sequence; I : Positive)
     with Pre => I <= Length (S);

private

   package Element_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Element);

   type Sequence is limited record
      Items : Element_Vectors.Vector;
   end record;

end ECS.Unbounded_Sequences;
