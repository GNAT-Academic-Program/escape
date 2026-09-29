------------------------------------------------------------------------------
--  ECS.Paged_Sparse_Maps  --  the desktop backing for ECS.Sparse_Maps.
--
--  The index space is cut into pages of Page_Size slots.  A page is
--  allocated only when something inside its range actually gets the
--  component.  A component held by 200 clustered entities out of four
--  million costs a page or two, not sixteen megabytes.
------------------------------------------------------------------------------

with Ada.Containers.Vectors;

generic
   Page_Size : Positive := 4096;
package ECS.Paged_Sparse_Maps is

   type Map is limited private;

   procedure Clear (M : in out Map);
   --  Frees every allocated page.

   function Lookup (M : Map; I : Entity_Index) return Natural;

   procedure Assign (M : in out Map; I : Entity_Index; S : Natural);

private

   type Page is array (0 .. Page_Size - 1) of Natural;
   type Page_Access is access Page;

   package Page_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Page_Access);

   type Map is limited record
      Pages : Page_Vectors.Vector;
   end record;

end ECS.Paged_Sparse_Maps;
