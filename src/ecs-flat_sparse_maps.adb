package body ECS.Flat_Sparse_Maps with SPARK_Mode is

   -----------
   -- Clear --
   -----------

   procedure Clear (M : in out Map) is
   begin
      M.Slots := [others => 0];
   end Clear;

   ------------
   -- Lookup --
   ------------

   function Lookup (M : Map; I : Entity_Index) return Natural is
     (if I in Index_Range then M.Slots (I) else 0);

   ------------
   -- Assign --
   ------------

   procedure Assign (M : in out Map; I : Entity_Index; S : Natural) is
   begin
      if I in Index_Range then
         M.Slots (I) := S;
      end if;
   end Assign;

end ECS.Flat_Sparse_Maps;
