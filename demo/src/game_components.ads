------------------------------------------------------------------------------
--  Game_Components  --  application component types.  Target-agnostic.
--
--  Component identity is an enumeration, not a string.  The compiler already
--  knows every type at build time; there is no reason to hash names at
--  runtime.  'Image gives you debug names for free.
------------------------------------------------------------------------------

package Game_Components is

   type Component_Kind is (Position, Velocity, Health);

   type Position_Data is record
      X, Y : Float := 0.0;
   end record;

   type Velocity_Data is record
      DX, DY : Float := 0.0;
   end record;

   type Health_Data is record
      Points : Natural := 0;
   end record;

end Game_Components;
