------------------------------------------------------------------------------
--  tests  --  the acceptance test for milestone 1.  IDENTICAL for both
--  targets; only the Game_ECS assembly it withs differs.  Both builds must
--  pass, and print the same trace.  That is the differential test.
--
--  With the seed's placeholder ECS.Pools body this prints FAILURES.  When
--  it prints ALL PASS on both targets, milestone 1 is done.
------------------------------------------------------------------------------

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with ECS;
with Game_Components; use Game_Components;
with Game_ECS;        use Game_ECS;

procedure Tests is

   use type ECS.Entity_Index;
   use type ECS.Entity;         --  private type: "/=" is not directly visible

   Failures : Natural := 0;

   procedure Check (Label : String; Condition : Boolean);
   procedure Check (Label : String; Condition : Boolean) is
   begin
      if not Condition then
         Failures := Failures + 1;
         Put_Line ("  FAIL  " & Label);
      else
         Put_Line ("  ok    " & Label);
      end if;
   end Check;

   procedure Check_All_Invariants (Label : String);
   procedure Check_All_Invariants (Label : String) is
   begin
      Check (Label & " :: pool invariants",
             Positions.Check_Invariant
               and then Velocities.Check_Invariant
               and then Healths.Check_Invariant);
   end Check_All_Invariants;

   Moving : constant World.Signature :=
     World.Mask_Of (Position, Velocity);

   E : array (1 .. 5) of Entity;
   Ok : Boolean;

begin
   Put_Line ("backend: " & Backend);
   New_Line;

   ---------------------------------------------------------------------------
   Put_Line ("-- entity lifetime");
   ---------------------------------------------------------------------------

   for I in E'Range loop
      E (I) := World.Create;
   end loop;

   Check ("five entities created", World.Live_Count = 5);
   Check ("slots handed out in order", ECS.Slot (E (1)) = 1
                                       and then ECS.Slot (E (5)) = 5);

   declare
      Stale : constant Entity := E (3);
   begin
      World.Destroy (E (3));
      Check ("destroy decrements live count", World.Live_Count = 4);
      Check ("stale handle is not alive", not World.Alive (Stale));

      E (3) := World.Create;
      Check ("slot recycled", ECS.Slot (E (3)) = 3);
      Check ("recycled slot has new generation", E (3) /= Stale);
      Check ("stale handle STILL not alive after recycle",
             not World.Alive (Stale));
   end;

   ---------------------------------------------------------------------------
   New_Line;
   Put_Line ("-- components");
   ---------------------------------------------------------------------------

   for I in E'Range loop
      Positions.Set (E (I), (X => Float (I), Y => 0.0), Ok);
      Check ("attach Position" & I'Image, Ok);
   end loop;

   Velocities.Set (E (2), (DX => 1.0, DY => 0.5), Ok);   Check ("attach Velocity 2", Ok);
   Velocities.Set (E (4), (DX => -1.0, DY => 0.0), Ok);  Check ("attach Velocity 4", Ok);
   Healths.Set    (E (1), (Points => 100), Ok);          Check ("attach Health 1", Ok);

   Check ("position count", Positions.Count = 5);
   Check ("velocity count", Velocities.Count = 2);
   Check ("signature reflects attachments",
          World.Contains (World.Signature_Of (E (2)), Moving)
          and then not World.Contains (World.Signature_Of (E (1)), Moving));
   Check ("Get round-trips", Positions.Get (E (4)).X = 4.0);
   Check_All_Invariants ("after attach");

   --  Overwrite, not a second row.
   Positions.Set (E (4), (X => 40.0, Y => 4.0), Ok);
   Check ("Set on existing overwrites", Positions.Count = 5
                                        and then Positions.Get (E (4)).X = 40.0);

   ---------------------------------------------------------------------------
   New_Line;
   Put_Line ("-- query");
   ---------------------------------------------------------------------------

   Check ("two entities match Position+Velocity", Query.Count (Moving) = 2);

   --  A movement system, written the way real systems are: drive from the
   --  smaller pool, test the signature.  Reverse, out of habit -- this loop
   --  does not mutate, but the next one does.
   declare
      Moved : Natural := 0;
   begin
      for I in reverse 1 .. Velocities.Count loop
         declare
            Ent : constant Entity := Velocities.Owner (I);
            V   : constant Velocity_Data := Velocities.Value (I);
            P   : Position_Data;
         begin
            if World.Matches (Ent, Moving) then
               P := Positions.Get (Ent);
               Positions.Set (Ent, (X => P.X + V.DX, Y => P.Y + V.DY), Ok);
               Moved := Moved + 1;
            end if;
         end;
      end loop;
      Check ("movement system touched two entities", Moved = 2);
      Check ("entity 2 moved", Positions.Get (E (2)).X = 3.0);
   end;

   ---------------------------------------------------------------------------
   New_Line;
   Put_Line ("-- removal and the back-pointer fixup");
   ---------------------------------------------------------------------------

   --  Remove from the MIDDLE of the dense array: this is what exercises the
   --  fixup.  E(2) is at some interior slot; after Unset, whatever row was
   --  last must have its Sparse back-pointer corrected.
   Positions.Unset (E (2));
   Check ("position count drops", Positions.Count = 4);
   Check ("removed entity has no position", not Positions.Has (E (2)));
   Check ("signature bit cleared",
          not World.Contains (World.Signature_Of (E (2)), World.Only (Position)));
   Check ("survivors still readable",
          Positions.Get (E (5)).X = 5.0 and then Positions.Get (E (1)).X = 1.0);
   Check_All_Invariants ("after interior unset");

   --  Destroy an entity holding several components: every pool must be
   --  detached via its registered handler.
   Healths.Set (E (5), (Points => 7), Ok);              Check ("attach Health 5", Ok);
   Velocities.Set (E (5), (DX => 9.0, DY => 9.0), Ok);  Check ("attach Velocity 5", Ok);
   World.Destroy (E (5));
   Check ("destroy detached position", Positions.Count = 3);
   Check ("destroy detached velocity", Velocities.Count = 2);
   Check ("destroy detached health",   Healths.Count = 1);
   Check_All_Invariants ("after destroy with components");

   ---------------------------------------------------------------------------
   New_Line;
   Put_Line ("-- churn");
   ---------------------------------------------------------------------------

   declare
      Churn : array (1 .. 40) of Entity;
   begin
      for I in Churn'Range loop
         Churn (I) := World.Create;
         Positions.Set (Churn (I), (X => Float (I), Y => Float (I)), Ok);
         if I mod 2 = 0 then
            Velocities.Set (Churn (I), (DX => 1.0, DY => 1.0), Ok);
         end if;
      end loop;

      for I in Churn'Range loop
         if I mod 3 = 0 then
            World.Destroy (Churn (I));
         elsif I mod 5 = 0 then
            Positions.Unset (Churn (I));
         end if;
      end loop;

      Check_All_Invariants ("after churn");
      Check ("live count consistent with query",
             Query.Count (World.Empty_Signature) = World.Live_Count);
   end;

   ---------------------------------------------------------------------------
   New_Line;
   Put_Line ("-- reset");
   ---------------------------------------------------------------------------

   World.Clear;
   Check ("world empty", World.Live_Count = 0);
   Check ("pools emptied by world reset",
          Positions.Count = 0 and then Velocities.Count = 0
          and then Healths.Count = 0);
   Check_All_Invariants ("after reset");

   New_Line;
   if Failures = 0 then
      Put_Line ("ALL PASS");
   else
      Put_Line ("FAILURES:" & Failures'Image);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
