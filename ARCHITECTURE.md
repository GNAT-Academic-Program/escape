# Architecture

## Layers

```
application (demo/, tests/, yarlib later)
     |
Game_ECS                 the assembly: instantiates World, Pools, Queries over ONE backing
     |
ECS.Queries (generic)    registry-scan cursor over a World
ECS.Pools   (generic)    one sparse set per component type       <- the project
ECS.Worlds  (generic)    entity lifetime, signatures, detach table
     |
ECS.Sequences            } signature packages: the storage contract, no body
ECS.Sparse_Maps          }
     |                         |
ECS.Bounded_Sequences    ECS.Unbounded_Sequences     dense storage: array / vector
ECS.Flat_Sparse_Maps     ECS.Paged_Sparse_Maps       sparse index:  array / pages
     |
ECS                      Entity handle. Pure.
```

Dependencies point down. `Pools` sees only the two signature packages,
never a concrete backing. `Game_ECS` is the only unit that names one.

## Entity

`Entity = (Index : mod 2**32, Generation : mod 2**32)`, 64 bits, private.
Slot 0 is `No_Index`, so a default handle is invalid. Generations start
at 1, so `No_Entity` (generation 0) never matches a live slot. `Destroy`
bumps the slot's generation; `Alive` compares the handle's generation to
the slot's. A stale handle is caught in O(1). `Index` is a namespace,
not a size: `Max_Entities` (a formal of `Worlds`) sizes the arrays.

## World

One world per instantiation; state is in the package body. Making
`World` a type would require pools to be components of it, and pools
are separate generic instantiations over unrelated component types:
that is the heterogeneous-storage problem a statically typed language
cannot solve without byte blobs. Two worlds means two instantiations.
Stretch goal, not a v1 restriction to work around.

The registry is a flat array `1 .. Max_Entities` of (generation,
signature, live). Dense by nature, so no storage formal is needed.
A free list recycles slots. `Register_Component` lets each pool hand
the world a `Detach` procedure so that `Destroy` can reach every pool
without knowing their types.

`Signature` is `array (Component_Kind) of Boolean with Pack`. It
duplicates what the pools know; its only justification is that a query
is one `and` per entity. The cost is that every `Set`/`Unset` must keep
it in sync, which is why all mutation routes through the pool, and the
pool calls `Note_Added`/`Note_Removed`.

## Pool: the sparse set

Three arrays, one invariant.

```
S : Sparse   Entity_Index -> dense slot (0 = absent)   fixed domain 1 .. Max_Entities
O : Owners   dense slot   -> Entity_Index              a Sequence, length = Count
V : Values   dense slot   -> Component                 a Sequence, length = Count

Invariant:  for all I in 1 .. Count:  S (O (I)) = I
            and Length (O) = Length (V)
```

`S` and `O` point at each other. `Get` is two indirections. Iteration
over `V` is contiguous and branch-free, which is what systems do.

### The five operations (milestone 1)

```
Has (E):     Alive (E) and then S (E.Index) /= 0

Get (E):     V (S (E.Index))                    -- Pre: Has (E)

Set (E, C):  if not Alive (E)        -> Ok := False
             if S (E.Index) /= 0     -> V (slot) := C; Ok := True   (overwrite, no new row)
             else  Append (O, E.Index, Ok); if not Ok return
                   Append (V, C, Ok);       if not Ok: Swap_Remove (O, Length (O)); return
                   S (E.Index) := Length (O)
                   Note_Added (E, Kind)

Unset (E):   if not Alive (E) or S (E.Index) = 0 -> return
             Detach (E.Index)
             Note_Removed (E, Kind)

Detach (Ix): Slot := S (Ix); if 0 return
             Swap_Remove (O, Slot); Swap_Remove (V, Slot)     -- last row now sits at Slot
             if Slot <= Length (O):  S (O (Slot)) := Slot      -- THE FIXUP
             S (Ix) := 0
```

The fixup is the whole difficulty. After `Swap_Remove` the row that was
last is now at `Slot`, but its entry in `S` still says the old last
index. Nothing fails immediately; `Check_Invariant` catches it, and so
does the "removal from the middle" test. Without the check it surfaces
as one entity reading another's component, far from the cause.

`Detach` does not touch the signature. `Destroy` clears the whole
signature once and calls every pool's `Detach`; if `Detach` also called
`Note_Removed` it would be redundant at best and reentrant at worst.
`Unset` is the public path and does both, in that order.

### Iteration

`Count`, `Owner (I)`, `Value (I)`, `Update (I, C)` for `I in 1 .. Count`.
No order is guaranteed: `Swap_Remove` moves the tail. A system that
mutates while iterating walks `in reverse`, so the moved tail lands in
an already-visited slot. Milestone 3 (command buffer) removes this
convention.

## Storage contracts

`ECS.Sequences` and `ECS.Sparse_Maps` are signature packages: generics
with formal subprograms and no body, existing so that `Pools` can say
`with package Values is new ECS.Sequences (Element => Component,
others => <>)`. The `is <>` defaults mean an adapter instantiation is
two lines when the concrete package uses the same names.

Cost: every store is two instantiations, the concrete one and the
adapter. `Game_ECS` is 150 lines for three components because of it.
That is the honest price of storage-agnostic generics in Ada; a helper
that folds the pair into one instantiation is a fine small task.

Why not a tagged `Storage'Class`: dispatching on every `Item` call in
the hot loop, an access type in every pool, and no SPARK.

### Backings

| | embedded | desktop |
|---|---|---|
| Sequence | `Bounded_Sequences`: array, `Append` returns `Ok = False` when full | `Unbounded_Sequences`: `Ada.Containers.Vectors`, always `Ok` |
| Sparse map | `Flat_Sparse_Maps`: one `Natural` per entity per component | `Paged_Sparse_Maps`: pages allocated on first assign |

Flat maps cost `Max_Entities * Natural'Size` per component type whether
two entities have the component or all do. Fine at 256, ruinous at a
million; that is what paging is for.

## Queries

`ECS.Queries` walks `1 .. Max_Entities` and tests each live slot's
signature: O(Max_Entities) regardless of how many match. Correct on
embedded, wrong at a million entities where twelve match. The other
strategy, drive from the smallest pool in the mask, cannot be written
generically here (pools are unrelated instantiations), so it is four
lines in the application; the stress demo has both and times them.
Milestone 4 makes it a library facility.

## Differential test

`tests.adb` and `stress.adb` are identical for both targets; only
`Game_ECS` changes. The traces must match (except the backend banner).
A pool implementation that happens to work on the flat map and not the
paged one, or on arrays and not vectors, is wrong, and CI says so.

## Proof plan (milestone 2)

Over the bounded backing, `SPARK_Mode => On` on `ECS.Pools`:

- ghost function `Invariant return Boolean` = the equation above
- `Set`, `Unset`, `Detach`: `Pre => Invariant, Post => Invariant`
- `Clear`: `Post => Invariant and Count = 0`
- the `Swap_Remove` and `Assign` postconditions in the leaf packages are
  already there to make the fixup step provable; strengthen them as the
  proof asks.

`Worlds` and `Queries` can follow; the value is in `Pools`.

## What is deliberately not here

- Systems as a library concept. A system is a loop; the library gives
  you the arrays.
- Events, hierarchies, prefabs, serialization. Downstream (yarlib).
- Multi-threading. One world, one task.
