# Ameba Usagi-Tools

**Ameba Usagi-Tools** are extra functionalities for the [Usagi Engine](https://usagiengine.com) created by [Brett Chalupa](https://brettmakesgames.com).

## Modules

### Raycast 2D

Raycast and Collider system. 

#### Example
```lua
--Import library
local Ray = require("ray")

-- In your `_update(dt)` perform the cast
function _update(dt)
  -- some code

  -- Example: cast a single line with origin in (10,10) to the right
  local hits = Ray:cast(10, 10, 1, 0,
      -- function to evaluate if point `p` is a hit
      -- for example, does p == player's position
      function(p) return p.x == player.x and p.y == player.y end,
      -- function called a hit to determine if the `scanning` should stop
      -- for example, stop at the first hit 
      function(hit) return true end )

  -- Hits are returned as `RaycastHit` objects
  -- below some of the properties you can explore  
  for i, hit in ipairs(hits) do
    print(string.format("Hit %d - origin in (%d, %d) found hit at (%d, %d)", i, 
        -- origin: from where it was casted
        hit.origin.x, hit.origin.y,
        -- coordinate of the hit
        hit.point.x, hit.point,y))
    
    -- the distance, in pixels, from the origin
    print(string.format("Hit %d at %d pixels in (%d, %d) ",i, hit.distance))

    -- `Collider` object with information about the collision area like
    print(string.format("Hit %d collider type %s in (%d, %d) ",i, 
        -- type: circle, capsule or rect  
        hit.collider.col_type, 
        -- collider position
        hit.collider.x, hit.collider.y))
  end

end
```


### Splines

### Audio 

## Usage

## Credits

**Ameba Games Studio** is an indie Video Games studio based in Seattle, founded by Juan Pablo Lopez.   



