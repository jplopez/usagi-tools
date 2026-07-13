--- Samplers Module : Define strategies to sample points for Raycasting
---
--- Samplers calculate the points that a Ray would pass through in the screen.
--- Sampler types included:
--- * line_sampler: a single straight line.
--- * circle_sampler: concentric straight lines. You must provide the arc of the circle you want to cast, and a step (distance between each casted line)
--- * grid_sampler: horizontal and vertical lines. You must provide the number of rows, columns and the separation (in pixels) between each casted line. 
--- 
--- *Max Distance:* all samplers support an optional `max_dist` paramteter. This tells the cast how far must the ray go. By default, rays go all the way to the edge of the screen.   
--- 
--- All samplers satisfy this contract:
--- * `sample(ox, oy, dx, dy)` : calculates and returns all the points in the screen the ray will go through.
--- * `iter(ox, oy, dx, dy)`   : An iterator to calculate and return the points one at a time.
--- 
--- For both functions, the input parameters are the same:
--- * `ox` : origin x-position
--- * `oy` : origin y-position
--- * `dx` : direction x-position. A value from -1, 0 or 1
--- * `dy` : direction y-position. A value from -1, 0 or 1
---  
--- Each sampler receives different initial parameters at construction:
--- 
--- Both functions receive the same input parameters. 


require("mod.usagi_ex")
local PointBuffer = require("mod.pointbuffer")


---A ray sampler that collects points based on origin, normalized direction, and params, and returns a list of sample points.
---@class RaySampler
---@field buffer PointBuffer
---@field iter fun(...: any) : fun(): x:integer, y:integer | nil -- iterator for points
---@field sample fun(self:RaySampler, ox:integer, oy:integer, dx:direction_type, dy:direction_type, dist:number) : PointBuffer -- performs the casting and returns the sampled points 
---@field valid_distance fun(self:RaySampler, ox:integer, oy:integer, dx:direction_type, dy:direction_type, dist:number) : boolean
---@field r? integer -- radius for circle sampler
---@field arc? number -- arch for circle sampler
---@field step? integer -- for circle sampler
---
---@field rows? integer -- for grid sampler
---@field cols? integer -- for grid sampler
---@field spacing? integer -- for grid sampler
local RaySampler = {}
RaySampler.__index = RaySampler


--- Constants
RaySampler.SCREEN_DIST = math.sqrt(usagi.GAME_W^2 + usagi.GAME_H^2)
RaySampler.INFINITE    = math.maxinteger

---@alias direction_type
---| -1 -- left or up
---| 0 -- no direction
---| 1 -- right or down

local function _calc_max_dist_sq(max_dist)
    return max_dist and max_dist*max_dist or 
          usagi.GAME_W * usagi.GAME_W + usagi.GAME_H * usagi.GAME_H
end



------------------------
--- Line Sampler
------------------------


---Returns a point sampler that uses a single straight line
---
---@param buffer? PointBuffer -- optional PointBuffer with the strategy to store and sort the sampled points. Default is flat array
---@return RaySampler
function RaySampler:line_sampler(buffer)
  local sampler = setmetatable({ buffer = buffer }, RaySampler)

  function sampler:sample(ox, oy, dx, dy, max_dist)
    self.buffer = self.buffer or PointBuffer.flat()
    self.buffer:clear()
    for x,y in self:iter(ox,oy,dx,dy,max_dist) do
      self.buffer:push(x,y)
    end
    return self.buffer
  end

  ---Iterator
  ---@param ox integer
  ---@param oy integer
  ---@param dx direction_type
  ---@param dy direction_type
  ---@param max_dist? integer
  ---@return function -- iterator function
  function sampler:iter(ox, oy, dx, dy, max_dist)
    max_dist = max_dist or RaySampler.SCREEN_DIST
    local i = 0
    return function()
      -- edge case when direction is 0,0
      if dx == 0 and dy == 0 then return nil end
      local _x, _y = i * dx, i * dy
      if i >= max_dist then return nil end
      i = i + 1
      return ox + _x, oy + _y
    end
  end

  return sampler
end


----------------------
--- Circle Sampler
----------------------


---Returns a point sampler using concentric lines.
---
---Calling this function w/o parameters, casts a full circle of 36 concentric stright lines with length == GAME_H
---
---@param r? integer  -- radius of the circle. If not provided, the lines are casted until the edge of the screen
---@param arc? number -- specifies the arc from the circle to cast. Default is 360 (full circle)
---@param step? number -- the separation in degrees between each casted line. Default is 10
---@param buffer? PointBuffer -- optional PointBuffer with the strategy to store and sort the sampled points. Default is flat array
---@return RaySampler
function RaySampler:circle_sampler(r, arc, step, buffer)
  print("circle sampler")
  -- validate inputs
  local msg_prefix = "Circle Sample: invalid argument "
  if r then assert(r > 0, msg_prefix .. " r (" .. r .. ") must be greater than zero") end
  if arc then assert(arc > 0 and arc <= 360, msg_prefix .. " arc (" .. arc .. ") must be in (0, 360]") end
  if step then assert(step > 0 and step <= arc, msg_prefix .. " step (" .. step .. ") must be in (0, ".. arc .."]") end

  r = r or RaySampler.SCREEN_DIST
  arc = arc or 360
  step = step or 5

  local sampler = setmetatable({
    buffer = buffer, r = r, arc = arc, step = step }, RaySampler)

  function sampler:sample(ox, oy, dx, dy, max_dist)
    self.buffer = self.buffer or PointBuffer.flat()
    self.buffer:clear()
    for x, y in self:iter(ox, oy, dx, dy, max_dist) do
      self.buffer:push(x,y)
    end
    return self.buffer
  end

  function sampler:iter(ox, oy, dx, dy, max_dist)

    dx = dx or 0
    dy = dy or 0

    if max_dist then assert(max_dist > 0, string.format("Line sampler: max_dist must be > 0 -> %s", max_dist or "")) end
    local radius = max_dist or self.r
    local center = math.atan(dy, dx)
    local half   = math.rad(self.arc / 2)
    local step_r = math.rad(self.step)
    local _ox, _oy = ox, oy

    local start_angle = center - half
    local end_angle   = center + half

    local a = start_angle
    local d = 1

    -- iterator function
    -- outer loop: angle steps around the arc
    -- inner loop: distance steps along each ray
    return function ()
      while a <= end_angle do
        if d <= radius then
          local _x,_y = util.vec_from_angle_values(a, d)
          d = d + 1
          return _ox + _x, _oy + _y
        else
          -- move to next angle, reset distance
          a = a + step_r
          d = 0
        end
      end
      return nil
    end
  end

  return sampler
end


---------------------
--- Grid Sampler
--------------------

---comment
---@param rows? integer -- number of horizontal lines of the grid. Set to zero if you only want vertical lines. Default: 4
---@param cols? integer -- number of vertical lines of the grid. Set to zero if you only want horizontal lines. Default: 4
---@param spacing? integer -- number of pixels in between casted lines. Must be > 0. Default: 4
---@param length? integer --  length in pixels for all rays. Must be > 0. Default is 16
---@param buffer? PointBuffer -- optional PointBuffer object to manage point storting and iteration. Default: PointBuffer.flat()
---@return RaySampler
function RaySampler:grid_sampler(rows, cols, spacing, length, buffer)

  -- validate inputs
  local msg_prefix = "Grid Sampler: invalid argument "
  assert(not (rows == 0 and cols == 0), msg_prefix .. "rows and columns are both zero")
  if length then assert(length > 0 , "length (".. length .. ") is required and must be > zero") end
  if rows then assert(rows >= 0 , msg_prefix .. " rows (".. rows ..") must be >= zero") end
  if cols then assert(cols >= 0, msg_prefix .. " cols (" .. cols ..") must be >= zero") end
  if spacing then assert(spacing > 0, msg_prefix .. " spacing (" .. spacing .. ") must be > 0 ") end

  local sampler = setmetatable({
      rows = rows or 4,
      cols = cols or 4,
      spacing = spacing or 4,
      buffer = buffer or PointBuffer.flat(),
      length = length,
    }, RaySampler)

  function sampler:sample(ox, oy, dx, dy, max_dist)

    local dist = max_dist or self.length

    local half_cols = (self.cols - 1) * 0.5
    local half_rows = (self.rows - 1) * 0.5

    for r = 0, self.rows - 1 do
      for c = 0, self.cols - 1 do
        local sx = ox + (c - half_cols) * self.spacing
        local sy = oy + (r - half_rows) * self.spacing

        for d = 0, dist do
          self.buffer:push(sx + d * dx, sy + d * dy)
        end
      end
    end
    return self.buffer
  end

  ---Point iterator for grid_sampler.
  ---
  ---TODO: 
  ---rows and cols iterations define local vars for start, end and step value during iterations,
  ---this sets a foundation to enable iterations that could start from last row/col to first, or to inverse the order between rows and cols
  ---
  ---@param ox integer
  ---@param oy integer
  ---@param dx integer
  ---@param dy integer
  ---@param max_dist? integer -- optional distance to cast. Defaults to sampler.length
  ---@return function
  function sampler:iter(ox, oy, dx, dy, max_dist)
    local dist = max_dist or self.length

    local half_cols = (self.cols - 1) * 0.5
    local half_rows = (self.rows - 1) * 0.5

    local r_start, r_end = 0, self.rows - 1
    local c_start, c_end = 0, self.cols - 1
    local r, r_step = 0, 1
    local c, c_step = 0, 1
    local _ox, _oy = ox, oy
    local d = 0

    return function()
      while (r < r_end) do
        while(c < c_end) do

          local sx = _ox + (c - half_cols) * self.spacing
          local sy = _oy + (r - half_rows) * self.spacing

          local _x,_y = sx + d * dx, sy + d * dy
         
          d = d + 1

          c = c + c_step
          if c == c_end then
            c = 0
            r = r + r_step
          end

          return _x,_y
        end
      end
      return nil
    end
  end

  return sampler
end

return RaySampler