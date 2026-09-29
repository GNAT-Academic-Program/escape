------------------------------------------------------------------------------
--  Game_ECS  --  EMBEDDED assembly.
--
--  This file, and only this file, knows which storage backing is in use.
--  Its desktop twin declares exactly the same names over unbounded
--  sequences and paged sparse maps.  Application code names Game_ECS and
--  never a concrete storage package, so main.adb is byte-identical for both
--  targets.  Swapping is a GPR scenario variable.
--
--  Each store costs two instantiations: the concrete package, then the
--  signature adapter.  The `is <>` defaults in ECS.Sequences mean the
--  adapter is two associations instead of eight, but it is still two
--  instantiations.  That is the price of the signature-package approach.
------------------------------------------------------------------------------

with ECS;
with ECS.Worlds;
with ECS.Pools;
with ECS.Queries;
with ECS.Sequences;
with ECS.Sparse_Maps;
with ECS.Bounded_Sequences;
with ECS.Flat_Sparse_Maps;

with Game_Components;

package Game_ECS is

   Max_Entities : constant := 256;

   subtype Entity is ECS.Entity;
   No_Entity : constant Entity := ECS.No_Entity;

   package World is new ECS.Worlds
     (Component_Kind => Game_Components.Component_Kind,
      Max_Entities   => Max_Entities);

   package Query is new ECS.Queries (World);

   ---------------------------------------------------------------------------
   --  Storage: concrete, then adapter.
   ---------------------------------------------------------------------------

   package Owner_Store is new ECS.Bounded_Sequences
     (ECS.Entity_Index, Max_Entities);
   package Owner_Seq is new ECS.Sequences
     (Element => ECS.Entity_Index, Sequence => Owner_Store.Sequence,
      Clear   => Owner_Store.Clear,   Length      => Owner_Store.Length,
      Item    => Owner_Store.Item,    Replace     => Owner_Store.Replace,
      Append  => Owner_Store.Append,  Swap_Remove => Owner_Store.Swap_Remove);

   package Sparse_Store is new ECS.Flat_Sparse_Maps (Max_Entities);
   package Sparse_Map is new ECS.Sparse_Maps
     (Map    => Sparse_Store.Map,
      Clear  => Sparse_Store.Clear,
      Lookup => Sparse_Store.Lookup,
      Assign => Sparse_Store.Assign);

   ---------------------------------------------------------------------------
   --  Pools
   ---------------------------------------------------------------------------

   package Position_Store is new ECS.Bounded_Sequences
     (Game_Components.Position_Data, Max_Entities);
   package Position_Seq is new ECS.Sequences
     (Element => Game_Components.Position_Data,
      Sequence => Position_Store.Sequence,
      Clear   => Position_Store.Clear,   Length  => Position_Store.Length,
      Item    => Position_Store.Item,    Replace => Position_Store.Replace,
      Append  => Position_Store.Append,
      Swap_Remove => Position_Store.Swap_Remove);

   package Positions is new ECS.Pools
     (W      => World,
      Component => Game_Components.Position_Data,
      Kind   => Game_Components.Position,
      Values => Position_Seq,
      Owners => Owner_Seq,
      Sparse => Sparse_Map);

   package Velocity_Store is new ECS.Bounded_Sequences
     (Game_Components.Velocity_Data, Max_Entities);
   package Velocity_Seq is new ECS.Sequences
     (Element => Game_Components.Velocity_Data,
      Sequence => Velocity_Store.Sequence,
      Clear   => Velocity_Store.Clear,   Length  => Velocity_Store.Length,
      Item    => Velocity_Store.Item,    Replace => Velocity_Store.Replace,
      Append  => Velocity_Store.Append,
      Swap_Remove => Velocity_Store.Swap_Remove);

   package Velocities is new ECS.Pools
     (W      => World,
      Component => Game_Components.Velocity_Data,
      Kind   => Game_Components.Velocity,
      Values => Velocity_Seq,
      Owners => Owner_Seq,
      Sparse => Sparse_Map);

   package Health_Store is new ECS.Bounded_Sequences
     (Game_Components.Health_Data, Max_Entities);
   package Health_Seq is new ECS.Sequences
     (Element => Game_Components.Health_Data,
      Sequence => Health_Store.Sequence,
      Clear   => Health_Store.Clear,   Length  => Health_Store.Length,
      Item    => Health_Store.Item,    Replace => Health_Store.Replace,
      Append  => Health_Store.Append,
      Swap_Remove => Health_Store.Swap_Remove);

   package Healths is new ECS.Pools
     (W      => World,
      Component => Game_Components.Health_Data,
      Kind   => Game_Components.Health,
      Values => Health_Seq,
      Owners => Owner_Seq,
      Sparse => Sparse_Map);

   Backend : constant String := "embedded (bounded + flat)";

end Game_ECS;
