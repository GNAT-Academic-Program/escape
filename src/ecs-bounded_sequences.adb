package body ECS.Bounded_Sequences with SPARK_Mode is

   -----------
   -- Clear --
   -----------

   procedure Clear (S : in out Sequence) is
   begin
      S.Last := 0;
   end Clear;

   ------------
   -- Length --
   ------------

   function Length (S : Sequence) return Natural is (S.Last);

   ----------
   -- Item --
   ----------

   function Item (S : Sequence; I : Positive) return Element is (S.Items (I));

   -------------
   -- Replace --
   -------------

   procedure Replace (S : in out Sequence; I : Positive; E : Element) is
   begin
      S.Items (I) := E;
   end Replace;

   ------------
   -- Append --
   ------------

   procedure Append (S : in out Sequence; E : Element; Ok : out Boolean) is
   begin
      if S.Last = Capacity then
         Ok := False;
      else
         S.Last := S.Last + 1;
         S.Items (S.Last) := E;
         Ok := True;
      end if;
   end Append;

   -----------------
   -- Swap_Remove --
   -----------------

   procedure Swap_Remove (S : in out Sequence; I : Positive) is
   begin
      if I /= S.Last then
         S.Items (I) := S.Items (S.Last);
      end if;
      S.Last := S.Last - 1;
   end Swap_Remove;

end ECS.Bounded_Sequences;
