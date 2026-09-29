package body ECS.Worlds is

   Slots    : Slot_Array;
   Free     : Free_Array;
   Free_Top : Natural := 0;
   Alive_N  : Natural := 0;

   Handlers : array (Component_Kind) of Detach_Handler := [others => null];

   ----------
   -- Only --
   ----------

   function Only (K : Component_Kind) return Signature is
      Result : Signature := Empty_Signature;
   begin
      Result (K) := True;
      return Result;
   end Only;

   -------------
   -- Mask_Of --
   -------------

   function Mask_Of (K1 : Component_Kind) return Signature is
      R : Signature := Empty_Signature;
   begin
      R (K1) := True;
      return R;
   end Mask_Of;

   function Mask_Of (K1, K2 : Component_Kind) return Signature is
      R : Signature := Empty_Signature;
   begin
      R (K1) := True; R (K2) := True;
      return R;
   end Mask_Of;

   function Mask_Of (K1, K2, K3 : Component_Kind) return Signature is
      R : Signature := Empty_Signature;
   begin
      R (K1) := True; R (K2) := True; R (K3) := True;
      return R;
   end Mask_Of;

   function Mask_Of (K1, K2, K3, K4 : Component_Kind) return Signature is
      R : Signature := Empty_Signature;
   begin
      R (K1) := True; R (K2) := True; R (K3) := True; R (K4) := True;
      return R;
   end Mask_Of;

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      --  Detach first, so pool storage is released before the slots are
      --  recycled.  Skipping this would leave pools holding rows for
      --  entities that no longer exist.
      for I in Index_Range loop
         if Slots (I).Live then
            for K in Component_Kind loop
               if Slots (I).Sig (K) and then Handlers (K) /= null then
                  Handlers (K).all (I);
               end if;
            end loop;
         end if;
      end loop;

      for I in Index_Range loop
         Slots (I) := (Generation => 1, Sig => Empty_Signature, Live => False);
      end loop;

      --  Push slots in reverse so that Create hands out 1, 2, 3, ...
      Free_Top := 0;
      for I in reverse Index_Range loop
         Free_Top := Free_Top + 1;
         Free (Entity_Index (Free_Top)) := I;
      end loop;

      Alive_N := 0;
   end Clear;

   ------------
   -- Create --
   ------------

   function Create return Entity is
      Idx : Entity_Index;
   begin
      if Free_Top = 0 then
         return No_Entity;
      end if;

      Idx := Free (Entity_Index (Free_Top));
      Free_Top := Free_Top - 1;

      Slots (Idx).Live := True;
      Slots (Idx).Sig  := Empty_Signature;
      Alive_N := Alive_N + 1;

      return (Index => Idx, Generation => Slots (Idx).Generation);
   end Create;

   -------------
   -- Destroy --
   -------------

   procedure Destroy (E : Entity) is
   begin
      if not Alive (E) then
         return;
      end if;

      for K in Component_Kind loop
         if Slots (E.Index).Sig (K) and then Handlers (K) /= null then
            Handlers (K).all (E.Index);
         end if;
      end loop;

      Slots (E.Index).Sig        := Empty_Signature;
      Slots (E.Index).Live       := False;
      Slots (E.Index).Generation := Slots (E.Index).Generation + 1;

      Free_Top := Free_Top + 1;
      Free (Entity_Index (Free_Top)) := E.Index;

      Alive_N := Alive_N - 1;
   end Destroy;

   -----------
   -- Alive --
   -----------

   function Alive (E : Entity) return Boolean is
     (E.Index in Index_Range
        and then Slots (E.Index).Live
        and then Slots (E.Index).Generation = E.Generation);

   ----------------
   -- Live_Count --
   ----------------

   function Live_Count return Natural is (Alive_N);

   ------------------
   -- Signature_Of --
   ------------------

   function Signature_Of (E : Entity) return Signature is
     (if Alive (E) then Slots (E.Index).Sig else Empty_Signature);

   -------------
   -- Matches --
   -------------

   function Matches (E : Entity; Mask : Signature) return Boolean is
     (Alive (E) and then Contains (Slots (E.Index).Sig, Mask));

   ---------------
   -- Entity_At --
   ---------------

   function Entity_At (Index : Entity_Index) return Entity is
   begin
      if Index not in Index_Range or else not Slots (Index).Live then
         return No_Entity;
      end if;
      return (Index => Index, Generation => Slots (Index).Generation);
   end Entity_At;

   ------------------
   -- Is_Live_Slot --
   ------------------

   function Is_Live_Slot (Index : Entity_Index) return Boolean is
     (Index in Index_Range and then Slots (Index).Live);

   ------------------
   -- Signature_At --
   ------------------

   function Signature_At (Index : Entity_Index) return Signature is
     (if Index in Index_Range then Slots (Index).Sig else Empty_Signature);

   ------------------------
   -- Register_Component --
   ------------------------

   procedure Register_Component (K : Component_Kind; Handler : Detach_Handler)
   is
   begin
      Handlers (K) := Handler;
   end Register_Component;

   ----------------
   -- Note_Added --
   ----------------

   procedure Note_Added (E : Entity; K : Component_Kind) is
   begin
      if Alive (E) then
         Slots (E.Index).Sig (K) := True;
      end if;
   end Note_Added;

   ------------------
   -- Note_Removed --
   ------------------

   procedure Note_Removed (E : Entity; K : Component_Kind) is
   begin
      if Alive (E) then
         Slots (E.Index).Sig (K) := False;
      end if;
   end Note_Removed;

begin
   Clear;
end ECS.Worlds;
