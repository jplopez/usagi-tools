local RaycastHit = require("mod.raycasthit")
local RaySampler = require("mod.samplers")
local PointBuffer = require("mod.pointbuffer")
local Collider = require("mod.colliders")

---@class Raycast2D
local Raycast = {
  ox = 0,
  oy = 0,
  dx = 0,
  dy = 0,
  sampler = nil,
  hit_condition = function() end,
  exit_condition = function() return true end,
  step = 1, -- number of pixels to 
}
Raycast.__index = Raycast


--- Raycast Builder

---@class Raycast2D.Builder
local Builder = {
  ---@type Raycast2D
  _instance = nil
}
Builder.__index = Builder

---@return Raycast2D.Builder
function Raycast.Builder()
  local b = setmetatable({ _instance = Raycast:_new() }, Builder)
  return b
end

---Builder functions are a convenience way of creating Raycast
---instances. 
---Raycast Builder function to define the origin position
---@param a integer -- for origin x position
---@param b integer -- for origin y position
---@return Raycast2D.Builder  -- Rayvast.Builder 
function Builder:from(a, b)
  self._instance.ox = a
  self._instance.oy = b
  return self
end

---Builder functions are a convenience way of creating Raycast
---instances. 
---Raycast Builder function to define the cast direction
---@param a integer -- for direction x position
---@param b integer -- for direction y position
---@return Raycast2D.Builder  -- Rayvast.Builder 
function Builder:to(a, b)
  self._instance.dx = a
  self._instance.dy = b
  return self
end

---Raycast Builder function to configure Raycast as a line
---@return Raycast2D.Builder
function Builder:as_line()
  self._instance.sampler = RaySampler:line_sampler(PointBuffer.flat())
  return self
end

---Raycast Builder function to configure Raycast as a circle.
---* r : circle radius. This value will essentially be `distance/2`
---@param r? integer -- defaults to GAME_H / 2 (typically 80)
---@param arc? number -- defaults to 360 (complete circle)
---@param step? number -- defaults to 5 (casts every 5 degrees)
---@return Raycast2D.Builder
function Builder:as_circle(r, arc, step)
  self._instance.sampler = RaySampler:circle_sampler(r, arc, step, PointBuffer.flat())
  return self
end

---Raycast Builder function to condigure Raycast as a circle
---@param rows integer -- defaults to 1
---@param cols integer -- detauls to 1
---@param spacing integer -- detauls to 2
---@param dist integer -- distance of grid rays. Must be > 0
---@return Raycast2D.Builder
function Builder:as_grid(rows, cols, spacing, dist)
  self._instance.sampler = RaySampler:grid_sampler(rows, cols, spacing, dist, PointBuffer.flat())
  return self
end

function Builder:hit(hit_condition)
 self._instance.hit_condition = hit_condition
 return self
end

function Builder:exit(exit_condition)
  self._instance.exit_condition = exit_condition
  return self
end


---Returns the Raycast instance of this builder
---@return Raycast2D
function Builder:get_instance() return self._instance end


local function has_hit(obj, hits)
  for _, hit in ipairs(hits) do
    if hit.collider == obj then return true end
  end
  return false
end


---@private -- constructor
function Raycast:_new(tbl)
  return setmetatable(tbl or {}, self)
end

---Casts a line with origin in (ox,oy) and direction (dx,dy)
---@param ox integer
---@param oy integer
---@param dx integer
---@param dy integer
---@param sampler RaySampler -- iterator for points
---@param hit_condition function -- evaluation function to determine if a point is a hit
---@param exit_condition function --function to evaluate if the cast should top evaluating points
---@return RaycastHit[] -- hits found
function Raycast.cast(ox, oy, dx, dy, sampler, hit_condition, exit_condition)
  assert( hit_condition, "Raycast.cast: hit_condition is required")

  local hits = {}
  if not sampler then return hits end

  hit_condition = hit_condition or function() end
  exit_condition = exit_condition or function() return false end

  local origin = {x = ox, y = oy}

  for x,y in sampler:iter(ox, oy, dx, dy) do
    local p = {x=x, y=y}

    -- function return a truthy value
    local is_hit = hit_condition(p)
    if is_hit then
      -- create new raycasthit, and validate is not already
      -- captured
      local hit = RaycastHit.new(origin, p, is_hit)
      if not has_hit(hit, hits) then
        hits[#hits+1] = hit
        if exit_condition(hit)then break end
      end
    
    end
  end
  return hits
end

---comment
---@param ox integer -- optional
---@param oy integer -- optional
---@param dx integer -- optional
---@param dy integer -- optional
---@param hit_condition function -- optional
---@param exit_condition function -- optional
---@return RaycastHit | nil
function Raycast:first_hit(ox, oy, dx, dy, hit_condition, exit_condition) end

---comment
---@param ox integer -- optional
---@param oy integer -- optional
---@param dx integer -- optional
---@param dy integer -- optional
---@param hit_condition function -- optional
---@param exit_condition function -- optional
---@return RaycastHit[] 
function Raycast:all_hits(ox, oy, dx, dy, hit_condition, exit_condition)
  local hits = {}

  return hits
end

return Raycast