--- PointBuffer: efficient storing and sorting of points obtained from a Raycast.
--- 
--- PointBuffer implementations help reduce the complexity and computing time required to scan through all points obtained from a Raycast.
--- They are useful when you want to read all points, before checking for hits. 
--- 
--- *Provided implementations:*
--- 
--- * `flat` : stores x,y coordinates in a flat arrat without sorting. This is buffer[n] and buffer[n+1] represent the x and y coordinates of a single point.
--- * `sort` : stores x,y coordinates sorted by the calculated distance to the origin from smallest to largest. Internally, this is a table with the distance as the key for each item.
---            This implementation guarantees one point for a given distance. If there are two or more points with the same distance, this buffer returns the latest entered.
--- 
--- *Usage:*
--- 
--- ```
--- -- get instance of flat buffer
--- local buffer = PointBuffer.flat() 
--- 
--- -- adds the (x, y) point  
--- buffer:push(x,y)  
--- 
--- -- returns the total number of (x,y) points in the buffer
--- buffer:count()  --> 1
--- 
--- -- iterator that returns each x,y as two separate values
--- for x,y in buffer:iter() do
--- -- something...
--- end
--- 
--- -- the table functions # (length) and common iterators work as expected for the flat array
--- print(#buffer) --> 2
--- 
--- -- will iterate two times for each pushed point: first the x coordinate, then the y
--- for i,p in ipairs(buffer) do
--- 
--- end
--- 
--- ```
--- 
--- *How to Create you own PointBuffer*
--- 
--- PointBuffer must have meet the following contract:
--- * `push(x,y)` : To add points to the buffer. x and y are integers
--- * `count()` : returns the number of points in the buffer
--- * `iter()` : iterator 
--- 
--- Example:
--- ```
--- -- mypointbuffer.lua 
--- 
--- -- include the pointbuffer module
--- local PointBuffer = require("mod.pointbuffer")
--- 
--- -- create a 'constructor' function that returns the PointBuffer
--- function PointBuffer.my_buffer()
---   
---   -- make PointBuffer the index metatable
---   local self = setmetatable({}, PointBuffer) 
---   
---   -- add the functions to your PointBuffer
---   
---   function self:push(x, y) 
---     -- some code
---   end
---
---   function self:iter()
---     -- some code
---     return function()
---       -- your iteration function
---     end
---   end
---
---   function self:count() 
---     -- some code
---   end
---
---   -- return the metatable now 'casted' to PointBuffer
---   return self
---   
--- end
--- 
--- ```
--- 
---@class PointBuffer
---@field push fun(self, x: number, y: number)
---@field iter fun(self): fun(): number, number
---@field count fun(self): integer
---@field validate fun(self, x: integer, y: integer): boolean
---@field clear fun(self)
---@field _sort? fun(self)
---@field _order? table
local PointBuffer = {
  _seen = {}
}
PointBuffer.__index = PointBuffer

  ---rounds x and y to nearest integer. Helps reducing sampled points 
  ---that are too close to each other
  ---@param x number
  ---@param y number
  ---@return integer
  ---@return integer
  local function round(x, y)
    return math.floor(x + 0.5), math.floor(y + 0.5)
  end

  ---simple function to create a unique key for the `seen` array
  local function key(x ,y) return  x * 10000 + y end

  ---Validates the x,y pair checking if is already in, in which case, returns false
  ---
  ---@param x integer
  ---@param y integer
  ---@return boolean
  function PointBuffer:validate(x, y)
    local _x, _y = round(x, y)

    local _key = key(_x, _y)
    if not self._seen[_key] then
      self._seen[_key] = true
      return true
    end
    return false
  end


---Default flat buffer. Insertion order, no sorting.
---@return PointBuffer
function PointBuffer.flat()
  local self = setmetatable({ _data = {}, _seen = {} }, PointBuffer)

  function self:push(x, y)
    if not self:validate(x, y) then return end
    x,y = round(x,y)
    local i = #self._data + 1
    self._data[i]   = x
    self._data[i+1] = y
    --print(string.format("PointBuffer:push added (%d,%d)", self._data[i], self._data[i+1]))
  end

  function self:iter()
    local i = 0
    return function()
      i = i + 2
      local x = self._data[i-1]
      if x == nil then return nil end
      return x, self._data[i]
    end
  end

  function self:count()
    return #self._data / 2
  end

  function self:clear()
    self._data = {}
  end

  return self
end

---Sorted buffer. Points are sorted by distance from origin on first iter call.
---@param ox number
---@param oy number
---@return PointBuffer
function PointBuffer.sorted(ox, oy)
  local self = setmetatable({ _data = {}, _ox = ox, _oy = oy, _sorted = false, _seen = {} }, PointBuffer)

  function self:push(x, y)
    print("sorted:pushs")
    if not self:validate(x, y) then return end
    x,y = round(x,y)
    local i = #self._data + 1
    self._data[i]   = x
    self._data[i+1] = y
    self._sorted = false
  end

  function self:_sort()
    if self._sorted then return end
    local n = #self._data / 2
    local order = {}
    for i = 1, n do order[i] = i end
    local d = self._data
    local ox_, oy_ = self._ox, self._oy
    table.sort(order, function(a, b)
      local ax = d[a*2-1] - ox_
      local ay = d[a*2]   - oy_
      local bx = d[b*2-1] - ox_
      local by = d[b*2]   - oy_
      return (ax*ax + ay*ay) < (bx*bx + by*by)
    end)
    self._order  = order
    self._sorted = true
  end

  function self:iter()
    self:_sort()
    local i = 0
    local order = self._order or {} --defensive code: unlikely for _order to be nil
    local d = self._data
    return function()
      i = i + 1
      local idx = order[i]
      if idx == nil then return nil end
      return d[idx*2-1], d[idx*2]
    end
  end

  function self:count()
    return #self._data / 2
  end

  function self:clear()
    self._data = {}
  end

  return self
end

return PointBuffer