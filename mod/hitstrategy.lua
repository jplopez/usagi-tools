---HitStrategy Module : factory of reusables logics to evaluate hits
---against Raycast's sampled points.
---
--- Each function returns a Hit evaluation strategy compatible with `Raycast.detect` hit_eval_fn parameter.
--- A hit strategy is a function `(p:Usagi:Vec2) -> any`: returning a truthy hit value or nil.
---
--- PERFORMANCE WARNING:
---   The returned function is called once for EVERY sample point the raycast evaluates.
---   For a line cast of dist=100 that is 100 calls per frame per Ray.detect call.
---   For a grid of 3x3 with dist=100 that is 900 calls.
---   Keep source functions as cheap as possible: avoid allocations, loops,
---   or engine calls with high overhead inside them. Prefer sources that
---   do a single indexed lookup or a single gfx call per point.
---
---@TODO - update usage for HitStrategy
--- Usage:
---   Ray.detect(ox, oy, dx, dy, "line", params, on_hit, RaySources.color(gfx.COLOR_WHITE))

---@class HitStrategy
HitStrategy = {}

---@alias source_fn fun( p : Usagi.Vec2 ): any

--- 
--- Produces a hit test function that evaluates if the pixel color matches `color_index` color 
--- 
--- Useful for wall detection baked into the drawn scene.
--- 
---@param color_index Color  gfx.COLOR_* constant to match
---@return source_fn 
function HitStrategy.color(color_index)
  return function(p)
    local _, _, _, idx = gfx.get_px(p.x, p.y)
    return idx == color_index or nil
  end
end

--- 
--- Produces a hit test function that evaluates if the pixel color matches `color_index` in sprites.png at the `sprite_index` position, using `gfx.get_spr_px`.
--- 
--- Useful when level collision is painted directly into a sprite cell.
---
---@param sprite_index integer  1-based sprite cell index (same as gfx.spr)
---@param color_index  Color    gfx.COLOR_* constant to match
---@param tile_size?   integer  pixels per cell (default: usagi.SPRITE_SIZE)
---@return source_fn
function HitStrategy.sprite_color(sprite_index, color_index, tile_size)
  tile_size = tile_size or usagi.SPRITE_SIZE
  return function(p)
    local lx = math.floor(p.x) % tile_size
    local ly = math.floor(p.y) % tile_size
    local _, _, _, idx = gfx.get_spr_px(sprite_index, lx, ly)
    return idx == color_index or nil
  end
end


---
--- Produces a hit test function for the Raycast system that interprets a 2D tilemap
--- as a spatial collider field.
---
--- In other words, answers the question:
---
---     “Does this world-space point fall inside a tile that should count as a hit?”
---
--- It performs:
---   world-space coordinates → tile indices → tile lookup → predicate test
---
--- If the tile exists and the predicate returns true, the tile value is returned
--- (truthy hit). Otherwise, nil is returned (no hit).
---
--- If the predicate function is missing, this method uses the tile value as truthy. 
--- This is convenient if your map has 0,1 values, or uses nil to represent no-hit.
--- 
--- This is extremely cheap (pure Lua table lookup) and is the recommended source
--- for tile-based levels, especially when working with JSON-loaded maps.
---
---@param map integer[][]                             2D array indexed as map[row][col]
---@param tile_predicate fun(tile: integer): boolean  Predicate deciding which tiles count as hits
---@param tile_size? integer                          Optional. Size of each tile in pixels (default: usagi.SPRITE_SIZE)
---@return source_fn
function HitStrategy.tilemap(map, tile_predicate, tile_size)
  tile_size = tile_size or usagi.SPRITE_SIZE
  tile_predicate = tile_predicate or function(t) return t end -- non-zero tiles are hits by default

  return function(p)
    local col = math.floor(p.x / tile_size) + 1
    local row = math.floor(p.y / tile_size) + 1
    local tile = map[row] and map[row][col]
    return (tile and tile_predicate(tile)) and tile or nil
  end
end


-------------------------------------
--- Strategies based on ColliderRegistry
--------------------------------------

local c = require("mod.colliders")


---@class HitStrategy.Collider
local HSC = {}
HSC.__index = HSC
HitStrategy.Collider = HSC


--- Produces a hit test function that evalautes if the sampled points is contained in a Collider registered in `ColliderRegistry`. 
--- 
--- If the sample point is contained within the Collider, is considered a hit.
--- 
--- The hit test function, returns the Collider on hit, so when used with `Ray.detect`, `hit.collider` is the Collider object.
--- 
--- `filter` is an optional predicate to filter the registry to the Colliders of interest.
--- If no filter is provided, all Colliders in the registry are considered. This is not recommended for large registry sets.  
--- 
--- Called once per sample point, iterates ALL registry items each call.
--- Cost scales with registry size * sample count. For large registries,
--- prefer spatial filtering (pass a filter predicate) or reduce cast resolution.
---
---@param filter? fun(col: Collider) : boolean 
---@return fun(p: Usagi.Vec2) : Collider | nil
function HSC.registry(filter)
  return function(p)
    for _, col in ipairs(c.ColliderRegistry.items) do
      if (not filter or filter(col)) and col:contains(p) then
        return col
      end
    end
    return nil
  end
end

--- Hit test that evaluates if the sampled point is contained in a Collider with a specific `tag`.
--- 
--- The sample point has to first be contaiend in the Collider, and the collider must have the tag specified in the input parameter.  
--- 
--- Assumes colliders was created with `data = { tag = "enemy", ... }`. If `data.tag` can't be found, that collider is not considered a hit. 
--- 
---@param tag string # Collider tag specified in data.tag
---@return fun(p: Usagi.Vec2) : Collider | nil
function HSC.tag(tag)
  tag = tag or ""
  return HSC.registry(function(col)
    return (col.data and col.data.tag and col.data.tag == tag) or false
  end)
end

return HitStrategy