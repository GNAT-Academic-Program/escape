------------------------------------------------------------------------------
--  stress  --  also identical for both targets.  Adapts to whatever
--  Max_Entities the assembly declares, so the embedded build exercises
--  capacity exhaustion and the desktop build exercises scale.
------------------------------------------------------------------------------

with Ada.Text_IO;      use Ada.Text_IO;
with Ada.Calendar;     use Ada.Calendar;
with ECS;
with Game_Components;  use Game_Components;
with Game_ECS;         use Game_ECS;

procedure Stress is

   use type ECS.Entity;

   N : constant Natural := Natural'Min (Max_Entities + 64, 200_000);

   Ok      : Boolean;
   Made    : Natural := 0;
   Refused : Natural := 0;
   T0, T1  : Time;

begin
   Put_Line ("backend: " & Backend);
   Put_Line ("capacity:" & Max_Entities'Image & "  spawning:" & N'Image);

   T0 := Clock;

   --  Spawn, attaching Position to all and Velocity to every third.  Every
   --  seventh entity is destroyed straight away, so slots recycle and the
   --  dense arrays churn rather than just growing.
   for I in 1 .. N loop
      declare
         E : constant Entity := World.Create;
      begin
         if E = No_Entity then
            Refused := Refused + 1;
         else
            Made := Made + 1;
            Positions.Set (E, (X => Float (I mod 1000), Y => 0.0), Ok);
            if I mod 3 = 0 then
               Velocities.Set (E, (DX => 1.0, DY => 0.0), Ok);
            end if;
            if I mod 7 = 0 then
               World.Destroy (E);
            end if;
         end if;
      end;
   end loop;

   T1 := Clock;

   Put_Line ("created:" & Made'Image
             & "  refused:" & Refused'Image
             & "  live:" & World.Live_Count'Image);
   Put_Line ("positions:" & Positions.Count'Image
             & "  velocities:" & Velocities.Count'Image);
   Put_Line ("spawn+churn:"
             & Duration'Image (T1 - T0) & " s");

   --  Dense iteration: this is the hot path.  Contiguous, no signature test.
   T0 := Clock;
   declare
      Sum : Float := 0.0;
   begin
      for I in 1 .. Positions.Count loop
         Sum := Sum + Positions.Value (I).X;
      end loop;
      T1 := Clock;
      Put_Line ("dense scan of" & Positions.Count'Image
                & " positions:" & Duration'Image (T1 - T0)
                & " s  (checksum" & Float'Image (Sum) & ")");
   end;

   --  Registry scan: O(Max_Entities) whatever the match count.  This is the
   --  strategy that does not scale, shown next to the one that does.
   T0 := Clock;
   declare
      Moving : constant World.Signature :=
        World.Mask_Of (Position, Velocity);
      Matched : constant Natural := Query.Count (Moving);
   begin
      T1 := Clock;
      Put_Line ("registry scan found" & Matched'Image
                & " movers:" & Duration'Image (T1 - T0) & " s");
   end;

   --  Pool-driven equivalent: cost follows the pool, not the world.
   T0 := Clock;
   declare
      Moving : constant World.Signature :=
        World.Mask_Of (Position, Velocity);
      Matched : Natural := 0;
   begin
      for I in reverse 1 .. Velocities.Count loop
         if World.Matches (Velocities.Owner (I), Moving) then
            Matched := Matched + 1;
         end if;
      end loop;
      T1 := Clock;
      Put_Line ("pool-driven found" & Matched'Image
                & " movers:" & Duration'Image (T1 - T0) & " s");
   end;

   if Positions.Check_Invariant and then Velocities.Check_Invariant then
      Put_Line ("invariants: ok");
   else
      Put_Line ("invariants: BROKEN");
   end if;

   World.Clear;
   Put_Line ("after clear: live" & World.Live_Count'Image
             & "  positions" & Positions.Count'Image);
end Stress;
