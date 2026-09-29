with Ada.Unchecked_Deallocation;

package body ECS.Paged_Sparse_Maps is

   procedure Free is new Ada.Unchecked_Deallocation (Page, Page_Access);

   function Page_Of   (I : Entity_Index) return Natural is
     (Natural (I / Entity_Index (Page_Size)));

   function Offset_Of (I : Entity_Index) return Natural is
     (Natural (I mod Entity_Index (Page_Size)));

   -----------
   -- Clear --
   -----------

   procedure Clear (M : in out Map) is
      P : Page_Access;
   begin
      for I in M.Pages.First_Index .. M.Pages.Last_Index loop
         P := M.Pages.Element (I);
         Free (P);
      end loop;
      M.Pages.Clear;
   end Clear;

   ------------
   -- Lookup --
   ------------

   function Lookup (M : Map; I : Entity_Index) return Natural is
      Pg : constant Natural := Page_Of (I);
   begin
      if Pg > M.Pages.Last_Index or else M.Pages.Element (Pg) = null then
         return 0;
      end if;
      return M.Pages.Element (Pg) (Offset_Of (I));
   end Lookup;

   ------------
   -- Assign --
   ------------

   procedure Assign (M : in out Map; I : Entity_Index; S : Natural) is
      Pg : constant Natural := Page_Of (I);
   begin
      --  Clearing a slot in a page that was never allocated is a no-op.
      if S = 0
        and then (Pg > M.Pages.Last_Index or else M.Pages.Element (Pg) = null)
      then
         return;
      end if;

      while M.Pages.Last_Index < Pg loop
         M.Pages.Append (null);
      end loop;

      if M.Pages.Element (Pg) = null then
         M.Pages.Replace_Element (Pg, new Page'(others => 0));
      end if;

      M.Pages.Element (Pg) (Offset_Of (I)) := S;
   end Assign;

end ECS.Paged_Sparse_Maps;
