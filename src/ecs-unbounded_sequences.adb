package body ECS.Unbounded_Sequences is

   -----------
   -- Clear --
   -----------

   procedure Clear (S : in out Sequence) is
   begin
      S.Items.Clear;
   end Clear;

   ------------
   -- Length --
   ------------

   function Length (S : Sequence) return Natural is
     (Natural (S.Items.Length));

   ----------
   -- Item --
   ----------

   function Item (S : Sequence; I : Positive) return Element is
     (S.Items.Element (I));

   -------------
   -- Replace --
   -------------

   procedure Replace (S : in out Sequence; I : Positive; E : Element) is
   begin
      S.Items.Replace_Element (I, E);
   end Replace;

   ------------
   -- Append --
   ------------

   procedure Append (S : in out Sequence; E : Element; Ok : out Boolean) is
   begin
      S.Items.Append (E);
      Ok := True;
   end Append;

   -----------------
   -- Swap_Remove --
   -----------------

   procedure Swap_Remove (S : in out Sequence; I : Positive) is
      Last : constant Positive := Natural (S.Items.Length);
   begin
      if I /= Last then
         S.Items.Replace_Element (I, S.Items.Element (Last));
      end if;
      S.Items.Delete_Last;
   end Swap_Remove;

end ECS.Unbounded_Sequences;
