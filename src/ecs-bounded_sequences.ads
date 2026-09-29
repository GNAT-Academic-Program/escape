------------------------------------------------------------------------------
--  ECS.Bounded_Sequences  --  static array, no allocation, explicit overflow.
--  The embedded backing for ECS.Sequences.
------------------------------------------------------------------------------

generic
   type Element is private;
   Capacity : Positive;
package ECS.Bounded_Sequences with SPARK_Mode is

   type Sequence is limited private;

   procedure Clear (S : in out Sequence)
     with Post => Length (S) = 0, Inline;

   function Length (S : Sequence) return Natural with Inline;

   function Item (S : Sequence; I : Positive) return Element
     with Pre => I <= Length (S), Inline;

   procedure Replace (S : in out Sequence; I : Positive; E : Element)
     with Pre => I <= Length (S), Inline;

   procedure Append (S : in out Sequence; E : Element; Ok : out Boolean)
     with Post => Length (S) = Length (S)'Old + (if Ok then 1 else 0)
                  and then (Ok or else Length (S) = Capacity);

   procedure Swap_Remove (S : in out Sequence; I : Positive)
     with Pre  => I <= Length (S),
          Post => Length (S) = Length (S)'Old - 1;
   --  Moves the last element into slot I, then shortens by one.

private

   subtype Extent     is Natural  range 0 .. Capacity;
   subtype Slot_Range is Positive range 1 .. Capacity;

   type Element_Array is array (Slot_Range) of Element;

   --  Items is deliberately NOT default-initialised: slots above Last are
   --  garbage by design, so construction and Clear both cost one assignment.
   type Sequence is limited record
      Items : Element_Array;
      Last  : Extent := 0;
   end record;

end ECS.Bounded_Sequences;
