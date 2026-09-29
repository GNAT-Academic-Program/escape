# escape

A bounded entity-component-system runtime in Ada, with two storage
backings from one source tree: static arrays for embedded, growable
containers for the desktop. Same API, same tests, same trace.

GNAT Academic Program capstone project. Proposal title: *ECS PAL:
Entity Component System Runtime*.

## What it is

An ECS is the data layout under most game engines (Unity DOTS, Bevy,
Flecs): entities are integers, components are plain records stored in
dense arrays per type, and systems are loops over those arrays. It is
fast because it is cache-friendly and simple because there is no
object hierarchy. It is also exactly the kind of thing that goes wrong
quietly: one missed back-pointer update and, a thousand operations
later, one entity reads another's data.

escape is the small, bounded, provable version:

- **Generational handles.** An `Entity` is a 32-bit slot plus a 32-bit
  generation. A handle to a destroyed entity is detectably dead, even
  after the slot is reused.
- **Sparse sets.** One pool per component type: a sparse map from entity
  to dense slot, and two dense arrays (owners, values). O(1) attach,
  O(1) detach, contiguous iteration.
- **Signatures.** One bit per component kind per entity, kept in sync
  by the pools, so a query is one `and` per entity.
- **Storage is a formal, not a decision.** `ECS.Sequences` and
  `ECS.Sparse_Maps` are signature packages. Bounded arrays and flat maps
  for a microcontroller, vectors and paged maps for a million entities
  on a desktop. The pool code does not know which it got.

## What is in the seed

```
src/ecs.ads                    Entity handle                                     done, SPARK
src/ecs-sequences.ads          storage contract (signature package)              done
src/ecs-sparse_maps.ads        sparse index contract (signature package)         done
src/ecs-bounded_sequences.*    static array, explicit overflow                   done, SPARK
src/ecs-flat_sparse_maps.*     one array over 1 .. Max_Entities                  done, SPARK
src/ecs-unbounded_sequences.*  Ada.Containers.Vectors                            done
src/ecs-paged_sparse_maps.*    lazily allocated pages                            done
src/ecs-worlds.*               entity lifetime, signatures, detach handlers      done
src/ecs-pools.*                THE SPARSE SET: spec done, body is a PLACEHOLDER
src/ecs-queries.*              registry-scan query cursor                        done
demo/src/game_components.ads   the demo's component types
demo/src/{embedded,desktop}/game_ecs.ads   the two assemblies, picked by TARGET
demo/src/stress.adb            spawn/churn/scan timing, both targets
tests/src/tests.adb            ~40 checks with the pool invariant after every mutation
```

Everything compiles on both targets. The tests fail. That is the
starting line.

Read `ARCHITECTURE.md` before touching anything. It contains the
algorithm for the five placeholder operations, step by step. You are
implementing a known design, not inventing one; the point is to get it
exactly right, and the tests know when you have not.

## Milestones

1. **Make the tests pass on both backings.** `ECS.Pools` body: `Has`,
   `Get`, `Set`, `Unset`, `Detach`. ~60 lines. `Check_Invariant` is the
   oracle; the test suite calls it after every mutation. The two traces
   must match line for line. CI checks that.
2. **Prove the pool.** `SPARK_Mode` on `ECS.Pools`, the invariant as a
   ghost function, `Set`/`Unset`/`Detach` proved to preserve it, over
   the bounded backing. This is the year's headline and it is a
   textbook target: three arrays and one equation.
3. **Deferred structural changes.** A command buffer: `Destroy` and
   `Unset` during iteration are queued and applied at a sync point,
   so the reverse-iteration convention stops being load-bearing.
4. **Pool-driven queries.** `ECS.Queries` scans the registry:
   O(Max_Entities). Add a query that drives from the smallest pool
   named in the mask. The stress demo already measures the difference.
5. **Archetype storage, as a third backing.** Group entities by
   signature so a system over (Position, Velocity) walks one array
   with no lookups. Real design work; this is how Unity and Flecs do
   it, and it is where the signature-package design pays off or does
   not.

Stretch: `World` as a type rather than a package (the header comment
in `ecs-worlds.ads` says why that is hard); yarlib as the client.

## Build

Three [Alire](https://alire.ada.dev) crates. `TARGET` picks the
assembly in demo and tests; the library compiles both backings always.

```
alr build
cd tests && TARGET=embedded alr build && ./bin/embedded/tests
cd tests && TARGET=desktop  alr build && ./bin/desktop/tests
cd demo  && TARGET=desktop  alr build && ./bin/desktop/stress
alr with gnatprove && alr exec -- gnatprove -P escape.gpr --mode=flow
```

Contracts are checked at runtime (`-gnata`). Warnings are errors.

## Rules of the road

- Nothing above `ECS.Sequences` may assume iteration order.
  `Swap_Remove` does not preserve it.
- Mutating a pool while iterating it upward skips elements. Iterate
  `in reverse` until milestone 3 lands.
- Capacity exhaustion is `Ok : out Boolean`, never an exception.
  No exception crosses a package boundary in `src/`.
- Pools store `Entity_Index`, never `Entity`. The world rebuilds the
  handle; that is how stale handles get caught.
- `Detach` never touches the world signature. `Unset` does, after
  `Detach`. `Destroy` does, once, for all pools. Read the comment.

See `CONTRIBUTING.md` for the fork workflow.

## Contact

Olivier Henley, GAP Coordinator, AdaCore. Weekly meeting, plus the
project Discord.

## License

Apache-2.0. See `LICENSE`.
