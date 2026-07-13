---@deprecated
---Raycast module: casts rays and evaluates against colliders

local _ = require("mod.usagi_ex")
local PointBuffer = require("mod.pointbuffer")
local RaycastHit = require("mod.raycasthit")
local RaySampler = require("mod.samplers")

-------------------------
--  Public Types
-------------------------

---@alias cast_type
---| "line"
---| "circle"
---| "grid"

---@alias CircleCastParams { r: integer, arc?: integer, step?: integer }
---@alias LineCastParams   { dist: integer }
---@alias GridCastParams   { spacing?: integer, rows: integer, cols: integer, dist: integer }

-------------------------
--  Resolver Function Types
-------------------------

---A ray resolver receives origin, normalized direction, and params, and returns a list of sample points.
---@alias RayResolver fun(
---    ox: integer,
---    oy: integer,
---    dx: integer,
---    dy: integer,
---    params: table,
---    buffer: PointBuffer): Usagi.Vec2[] 


-- Reusables functions
local __fun = {
  noop = function() end,
  truthy = function() return true end
}


-------------------------
--  Raycast Module
-------------------------

---@class Raycast
---@field ox integer
---@field oy integer
---@field dx integer
---@field dy integer
---@field distance number
---@field resolution integer
---@field callbacks table
---@field _resolvers  table<cast_type, RayResolver>
---@field r? integer
---@field arc? number
---@field step? integer
---@field rows? integer
---@field cols? integer
---@field spacing? integer
local OldRaycast = {
  ox = 0, oy = 0,
  dx = 0, dy = 0,
  distance = 0,
  resolution = 1,
  callbacks = {
    hit_test = __fun.noop,
    exit_fn = __fun.truthy,
  },
  type = "line",
  _resolvers = {},

  ---@type RaySampler
  sampler = nil,

  --circle
  r = 80,
  arc = 360,
  step = 5,
  --grid 
  rows = 4,
  cols = 4,
  spacing = 4,

}
OldRaycast.__index = OldRaycast

function OldRaycast:new(tbl)
  return setmetatable(tbl or {}, self)
end

--- Raycast Builder


---@class Raycast.Builder
local Builder = {
  ---@type Raycast
  _instance = nil
}
Builder.__index = Builder
OldRaycast.Builder = Builder

Builder.__call = function(self)
  self._instance = OldRaycast:new()
  return self
end

---Builder functions are a convenience way of creating Raycast
---instances. 
---Raycast Builder function to define the origin position
---@param a integer -- for origin x position
---@param b integer -- for origin y position
---@return Raycast.Builder  -- Rayvast.Builder 
function Builder:from(a, b)
  self._instance.ox = a
  self._instance.oy = b
  return self
end

---Raycast Builder function to define the direction (x,y) = (a,b)
---@param a integer -- for direction x position
---@param b integer -- for direction y position
---@return Raycast.Builder  -- self
function Builder:to(a, b)
  self._instance.dx = a
  self._instance.dy = b
  return self
end

---Builder method to set Raycast to be of cast type `type`
---@private
---@param type cast_type
---@return Raycast.Builder
function Builder:_as(type)
  if self._instance._resolvers[type] then
    self._instance.type = type
  end
  return self
end

---Raycast Builder function to configure Raycast as a line
---@param dist integer -- defaults to 342 (longest diagonal distance)
---@return Raycast.Builder
function Builder:as_line(dist)
  self._instance.distance = dist or 342
  return self:_as("line")
end

---Raycast Builder function to configure Raycast as a circle.
---* r : circle radius. This value will essentially be `distance/2`
---@param r? integer -- defaults to GAME_H / 2 (typically 80)
---@param arc? number -- defaults to 360 (complete circle)
---@param step? number -- defaults to 5 (casts every 5 degrees)
---@return Raycast.Builder
function Builder:as_circle(r, arc, step)
  r = r or usagi.GAME_H / 2
  self._instance.r = r
  self._instance.distance = r * 2
  self._instance.arc = arc or 360
  self._instance.step = step or 5
  return self:_as("circle")
end

---Raycast Builder function to condigure Raycast as a circle
---@param dist integer
---@param rows integer -- defaults to 1
---@param cols integer -- detauls to 1
---@param spacing integer -- detauls to 2
---@return Raycast.Builder
function Builder:as_grid(dist, rows, cols, spacing)
  self._instance.distance = dist
  self._instance.rows = rows or 1
  self._instance.cols = cols or 1
  self._instance.spacing = spacing or 2
  return self:_as("grid")
end

---Returns the Raycast instance of this builder
---@return Raycast
function Builder:get_instance() return self._instance end

---
---Collects the points obtained by casting the ray in the screen. The returned array is not sorted.
---
---* `cast_type` specifies the raycast shape (line, circle, grid). The type also determines how the direction vector is used.
---* `params` is a table with the specific parameters used by the cast_type (ie: radius for circle, distance for lines).
---* `buffer` is a PointBuffer instance to store and sort the sampled points
---
---
---@private
---@param ox integer
---@param oy integer
---@param dx integer
---@param dy integer
---@param cast_type cast_type
---@param params table
---@param buffer? PointBuffer  -- Optional. Defaults to PointBuffer.flat()
---@return PointBuffer -- contains points 
function OldRaycast._sample(ox, oy, dx, dy, cast_type, params, buffer)
  assert(cast_type, "You must specify a type of Raycast")
  buffer = buffer or PointBuffer.flat()
  dx, dy = util.get_direction_values(dx, dy)

  local dist = params.dist
  local sampler = nil

  if cast_type == "line" then
    sampler = RaySampler:line_sampler(buffer)
  elseif cast_type == "circle" then
    sampler = RaySampler:circle_sampler(params.arc, params.step, _, buffer)
    dist = params.r
  elseif cast_type == "grid" then
    sampler = RaySampler:grid_sampler(params.rows, params.cols, params.spacing, _, buffer)
  end

  if sampler then
    return sampler:sample(ox, oy, dx, dy, dist)
  end
  assert(false, "Unknown Ray cast type: " .. tostring(cast_type) .. ". Returning empty buffer")
  return buffer
end

---
---Evaluates a list of sample points using a hit evaluation function.
---
---If `exit_fn` is provided, the evaluation stops when it returns true for a hit. 
---You can use `exit_fn` as an early exit, and prevent evaluating all points. 
---
---Returns hits (unsorted), with deduplication for table-valued colliders.
---
---@private
---@param ox integer -- cast x-position origin
---@param oy integer -- cast y-position origin
---@param buffer PointBuffer -- with sampled points to eval hits
---@param hit_eval_fn fun(p: Usagi.Vec2):Collider|boolean|nil
---@param exit_fn? fun(hit: RaycastHit) : boolean  -- if provided, stop evaluation when it returns true for a hit
---@return RaycastHit[] hits
function OldRaycast._eval_hits(ox, oy, buffer, hit_eval_fn, exit_fn)
  assert(hit_eval_fn and type(hit_eval_fn) == "function", "invalid hit evaluation function")
  assert(buffer ~= nil, "you must specify at least one point to eval hits")

  util.sprintf("Raycast:eval_hits: o:(%s,%s) points %d ", ox, oy, buffer:count())
  
  local origin = { x = ox, y = oy }
  local hits = {}   -- found hits
  local seen  = {}  -- track seen objects, to prevent re-processing

  for x,y in buffer:iter() do
    local p = {x = x, y = y}
    local obj = hit_eval_fn(p)

    if obj then
      -- deduplicate table hits by reference; non-table hits (e.g. true) always record
      local key = (type(obj) == "table") and obj or nil
      if not key or not seen[key] then
        if key then seen[key] = 1 end
        local hit = RaycastHit.new(origin, p, obj)
        hits[#hits+1] = hit
        -- evaluate if the detect should stop at this found hit
        if exit_fn and exit_fn(hit) then break end
      end
    end
  end
  return hits
end

---
---Performs a Raycast using `{ox,oy}` as the origin and  `{dx,dy}` as direction, and returns all found hits.
---This methods uses `_sample` and `_eval_hits`
---
---* `"cast_type"` specifies the raycast shape (line, circle, grid). The type also determines how the direction vector is used.
---* `"params"` is a table with the specific parameters used by the cast_type (ie: radius for circle, distance for lines).
---* `"hit_test"` is a function that evaluates each sample point and returns a truthy value on hit or nil.
---* `"on_hit"` is a callback called once per unique hit, in ascending distance order (closer to farthest).
---* Hits with table values are deduplicated by reference.
---* `exit_fn` is a function `(hit) -> boolean` that stops the evaluation if it returns true. Use this functions to exit early
---from the point evaluation, if you have already found your hist of interest.
------
---@private
---@param ox integer -- cast x-position origin
---@param oy integer -- cast y-position origin
---@param dx integer -- cast x-position direction
---@param dy integer -- cast y-position direction
---@param cast_type cast_type 
---@param params table -- additional parameters, specific for the cast_type
---@param hit_test fun(p: Usagi.Vec2):table|boolean|nil -- resolves is a sampled point is a hit
---@param exit_fn? fun(hit: RaycastHit) : boolean -- resolves if the cast should stop based on a found hit
---@return RaycastHit[] -- list of hits from the cast
function OldRaycast._all_hits(ox, oy, dx, dy, cast_type, params, hit_test, exit_fn )

  ---@type PointBuffer
  local points = OldRaycast._sample(ox, oy, dx, dy, cast_type, params)

  ---@type RaycastHit[]
  local hits = OldRaycast._eval_hits(ox, oy, points, hit_test, exit_fn)

  table.sort(hits, function(a, b) return a.distance_sq < b.distance_sq end)

  return hits
end

---Performs a Raycast using `{ox,oy}` as the origin and `{dx,dy}` as direction, and returns the first found hit.
---This method calls `eval_hits` with an `exit_fn` that stops at the first found hit.
---
---* `"cast_type"` specifies the raycast shape (line, circle, grid). The type also determines how the direction vector is used.
---* `"params"` is a table with the specific parameters used by the cast_type (ie: radius for circle, distance for lines).
---* `"hit_test"` is a function that evaluates each sample point and returns a truthy value on hit or nil.
---* `"on_hit"` is a callback called once per unique hit, in ascending distance order (closer to farthest).
---* Hits with table values are deduplicated by reference.
---* `exit_fn` is a function `(hit) -> boolean` that stops the evaluation if it returns true. Use this functions to exit early
---from the point evaluation, if you have already found your hist of interest.
---
---@private
---@param ox integer
---@param oy integer
---@param dx integer
---@param dy integer
---@param cast_type cast_type
---@param params table
---@param hit_test fun(p: Usagi.Vec2):table|boolean|nil
---@return RaycastHit | nil -- first found hit, or nil if no found
---@return PointBuffer
function OldRaycast._first_hit(ox, oy, dx, dy, cast_type, params, hit_test)
  ---@type PointBuffer
  local points = OldRaycast._sample(ox, oy, dx, dy, cast_type, params)
  --print("_first_hit sample : " .. points:count())
  ---@type RaycastHit[]
  local hits   = OldRaycast._eval_hits(ox, oy, points, hit_test, __fun.truthy)
  print("_first_hit hits: " .. #hits)

  return (#hits > 0) and hits[1] or nil, points
end

function OldRaycast.line(ox, oy, dx, dy, dist, hit_test)
  return OldRaycast._first_hit(ox, oy, dx, dy, "line", {dist = dist}, hit_test)
end

---Casts a circle origin in (ox, oy) radius r. Returns first hit
---
---@param ox        integer
---@param oy        integer
---@param dx        integer -- cast direction. Ignored if arc is 630
---@param dy        integer
---@param r         integer
---@param hit_test  fun(p: Usagi.Vec2):any
---@param step?     integer -- default to 1
---@return RaycastHit | nil
---@return PointBuffer
function OldRaycast.circle(ox, oy, dx, dy, r, hit_test, step)
  local params = { r = r, arc = 360, step = step or 1 }
  dx = dx or 0
  dy = dy or 0
  return OldRaycast._first_hit(ox, oy, 0, 0, "circle", params, hit_test)
  end

---Casts a circle orogin in (ox,oy) radius r. Returns all hits
---@param ox        integer
---@param oy        integer
---@param r         integer
---@param hit_test  fun(p: Usagi.Vec2):any
---@param step?     integer -- default to 1
---@return RaycastHit[] 
function OldRaycast.circle_all(ox, oy, r, hit_test, step)
   local params = { r = r, arc = 360, step = step or 1 }
  return OldRaycast._all_hits(ox, oy, 0, 0, "circle", params,
      hit_test)
end

function OldRaycast.grid(ox, oy, dx, dy, dist, rows, cols, spacing, hit_test)
  return OldRaycast._first_hit(ox, oy, dx, dy, "grid",
            { dist = dist, rows = rows, cols = cols, spacing = spacing},
            hit_test)
end

-------------------------
--  Raycast Resolvers
-------------------------


---@param params CircleCastParams
local function _assert_circle_resolver(params)
  local msg_prefix = "Raycast Circle: invalid argument "
  assert(params.r,             msg_prefix .. "r is required")
  assert(params.r > 0,         msg_prefix .. " r (" .. params.r .. ") must be > 0")
  assert(params.arc > 0 and params.arc <= 360, msg_prefix .. " arc (" .. params.arc .. ") must be in (0, 360]")
  assert(params.step > 0 and params.step <= params.arc, msg_prefix .. " step (" .. params.step .. ") must be in (0, ".. params.arc .."]")
end


---
---Raycasts concentric lines with center on `{ox,oy}`
---Each ray is cast in the angle obtained from `(dx, dy)`, and all sample points are returned
---
---`*params*`:
---* `r`    - integer circle radius.
---* `arc?` - integer arc angle in degrees (0,360]. Default: 360 (full circle). 
---* `step?`- integer angular step in degrees between rays. Default: 5
---
---@param ox integer
---@param oy integer
---@param dx integer
---@param dy integer
---@param params CircleCastParams
---@param buffer PointBuffer
---@return PointBuffer
OldRaycast._resolvers.circle = function(ox, oy, dx, dy, params, buffer)
  params.arc  = params.arc  or 360
  params.step = params.step or 5

  _assert_circle_resolver(params)

  local r      = params.r
  local arc    = params.arc
  ---@type number # default value is assigned above
  local step   = params.step
  local center = math.atan(dy, dx)
  local half   = math.rad(arc / 2)
  local step_r = math.rad(step)

  local start_angle = center - half
  local end_angle   = center + half

  for a = start_angle, end_angle, step_r do
    local _x,_y = util.vec_from_angle_values(a, r)
    buffer:push(ox + _x, oy + _y)
  end

  return buffer
end


---@param params LineCastParams
local function _assert_line_resolver(params)
  local msg_prefix = "Raycast Line: invalid argument "
  assert(params.dist,       msg_prefix .. "dist is required")
  assert(params.dist > 0,   msg_prefix .. " dist (" .. params.dist .. ") must be > 0")
end

---
---Raycasts a line with center on `{ox,oy}` in the direction of `{dx,dy}`, and all sample points are returned.
---
---`*params*`:
---* `dist` - integer distance of the ray. Must be a positive number. 
---
---@param ox integer
---@param oy integer
---@param dx integer
---@param dy integer
---@param params LineCastParams
---@param buffer PointBuffer
---@return PointBuffer
function OldRaycast._resolvers.line(ox, oy, dx, dy, params, buffer)
  _assert_line_resolver(params)
  local dist    = params.dist
  for d=0, dist do
    buffer:push(ox + d * dx, oy + d * dy)
  end
  return buffer
end


---@param params GridCastParams
local function _assert_grid_resolver(params)
  local rows, cols = params.rows, params.cols
  local spacing = params.spacing
  local dist = params.dist
  local msg_prefix = "Raycast Grid: invalid argument "
  assert(not (rows == 0 and cols == 0), msg_prefix .. "rows and columns are both zero")
  assert(rows >= 0 , msg_prefix .. " rows (".. rows ..") must be >= zero")
  assert(cols >= 0, msg_prefix .. " cols (" .. cols ..") must be >= zero")
  assert(spacing > 0, msg_prefix .. " spacing (" .. spacing .. ") must be > 0 ")
  assert(dist > 0, msg_prefix .. " dist (".. dist .. ") must be > 0")
end


---
---Raycasts a grid with origin in `{ox, oy}`.
---
---`*params*` fields:
---* `spacing`- integer pixel separation between rays. Default: 2 
---* `rows`   - number of horizontal rays
---* `cols`   - number of vertical rays
---* `dist`   - length (in pixels) of each ray 
---
---Each ray is cast in the direction `{dx, dy}`, and all sample points are returned
---
---@param ox integer
---@param oy integer
---@param dx integer
---@param dy integer
---@param params GridCastParams
---@param buffer PointBuffer
---@return PointBuffer
OldRaycast._resolvers.grid = function(ox, oy, dx, dy, params, buffer)
  -- optional params
  params.spacing = params.spacing or 2

  _assert_grid_resolver(params)

  -- local vars
  local spacing = params.spacing
  local rows    = params.rows
  local cols    = params.cols
  local dist    = params.dist

  local half_cols = (cols - 1) * 0.5
  local half_rows = (rows - 1) * 0.5

  for r = 0, rows - 1 do
    for c = 0, cols - 1 do
      --local sx = ox + (c - (cols - 1) / 2) * spacing
      --local sy = oy + (r - (rows - 1) / 2) * spacing
      local sx = ox + (c - half_cols) * spacing
      local sy = oy + (r - half_rows) * spacing

      for d = 0, dist do
        buffer:push(sx + d * dx, sy + d * dy)
      end
    end
  end
  return buffer
end


return OldRaycast