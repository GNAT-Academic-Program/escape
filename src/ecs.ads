------------------------------------------------------------------------------
--  ECS  --  root package.
--
--  Declares the entity handle and nothing else.  No storage, no generics,
--  no dependencies.  Every other unit is a child of this one, which is what
--  gives them visibility of the private part of Entity.
------------------------------------------------------------------------------

package ECS with SPARK_Mode is

   pragma Pure;

   --  The index is a namespace, not a size.  Nothing is dimensioned 2**32;
   --  Max_Entities (a formal of ECS.Worlds) sizes the actual arrays.
   type Entity_Index  is mod 2 ** 32;
   type Generation_Id is mod 2 ** 32;

   No_Index : constant Entity_Index := 0;
   --  Slot 0 is reserved so that a default-initialised handle is invalid.
   --  Valid slots are 1 .. Max_Entities.

   type Entity is private;

   No_Entity : constant Entity;

   function Is_Null (E : Entity) return Boolean with Inline;

   function Slot (E : Entity) return Entity_Index with Inline;
   --  For debugging and logging only.  Do not index anything with this;
   --  ask the world instead, so the generation gets checked.

private

   type Entity is record
      Index      : Entity_Index  := No_Index;
      Generation : Generation_Id := 0;
   end record
     with Size => 64;

   No_Entity : constant Entity := (Index => No_Index, Generation => 0);

   function Is_Null (E : Entity) return Boolean is (E.Index = No_Index);
   function Slot    (E : Entity) return Entity_Index is (E.Index);

end ECS;
