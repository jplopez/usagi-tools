--- Collider Module: defines areas of the screen that can be used
--- to detect intersections between objects, and as targets for 
--- Raycasting.
--- 
---* `Collider` can be circles, rectangles or capsules, that you can use to detect object intersections.
---* `ColliderRegistry` is a global list where you store Collider instances.
---* The `Raycast` module treats `Collider` as a soft depedency, ie, you can cast without explicitly using them
---
--- @TODO
--- use case of capsule where w > h. 
--- create a common check function that receives the specific logic as a parameter, so
--- i can keep extending other shapes, to eventually support full polygon and 'meshes'


---@alias collider_type
---| "circle"  
---| "capsule" 
---| "rect" 

---------------------
--- Collider class
---------------------

---@class Collider
---@field col_type string        -- "circle", "rect", "capsule", ...
---@field x number           -- center or top-left depending on type
---@field y number
---@field r number?          -- radius (circle only)
---@field w number?          -- width  (rect/capsule)
---@field h number?          -- height (rect/capsule)
---@field data table?        -- user metadata
local Collider = {}
Collider.__index = Collider


---Base constructor. Do not call directly; use shape constructors.
---@param o table
---@return Collider
function Collider:new(o)
  o = o or {}
  return setmetatable(o, self)
end

---Creates a circular collider.
---@param x number  Center X
---@param y number  Center Y
---@param r number  Radius
---@param data table?  Optional metadata
---@return Collider
function Collider.circle(x,y,r,data)
  return Collider:new{
    col_type="circle",
    x = x, y = y, -- center 
    r = r, -- radius
    data = data,
  }
end
 

---Creates a capsule collider (vertical capsule).
---NOTE: Currently assumes h >= w. See TODO for horizontal capsules.
---@param x number  Center X
---@param y number  Center Y
---@param w number  Width
---@param h number  Height
---@param data table?  Optional metadata
---@return Collider
function Collider.capsule(x, y, w, h, data)
  return Collider:new{
    col_type = "capsule",
    x = x, y = y,
    w = w, h = h,
    data = data,
    top_left     = function(self) return { x = self.x - self.w/2, y = self.y - self.h/2 } end,
    top_right    = function(self) return { x = self.x + self.w/2, y = self.y - self.h/2 } end,
    bottom_left  = function(self) return { x = self.x - self.w/2, y = self.y + self.h/2 } end,
    bottom_right = function(self) return { x = self.x + self.w/2, y = self.y + self.h/2 } end,
  }

end

---Creates an axis-aligned rectangle collider.
---@param x number  Top-left X
---@param y number  Top-left Y
---@param w number  Width
---@param h number  Height
---@param data table?  Optional metadata
---@return Collider
function Collider.rect(x, y, w, h, data)
  return Collider:new{
    col_type = "rect",
    x = x, y = y,
    w = w, h = h,
    data = data,
    top_left     = function(self) return { x = self.x,          y = self.y          } end,
    top_right    = function(self) return { x = self.x + self.w, y = self.y          } end,
    bottom_left  = function(self) return { x = self.x,          y = self.y + self.h } end,
    bottom_right = function(self) return { x = self.x + self.w, y = self.y + self.h } end,
  }
end

--- Moves the collider center to `{x, y}`. Call each frame when the owning entity moves.
---@param x number
---@param y number
function Collider:move_to(x, y)
  self.x = x
  self.y = y
end


local function check_circle(p, col) return col.type == "circle" and util.point_in_circ(p, {x=col.x,y=col.y,r=col.r}) end
local function check_rect(p, col) return col.type == "rect" and util.point_in_rect(p, {x=col.x, y=col.y, w=col.w,h=col.h}) end
local function check_capsule(p, col)
  if col.type ~= "capsule" then return false end
  local r    = col.w / 2
  local half_inner = (col.h - col.w) / 2   -- half-length of inner segment
  local seg_top    = col.y - half_inner
  local seg_bot    = col.y + half_inner

  -- closest point on the inner segment to p
  local closest_x = col.x
  local closest_y = math.max(seg_top, math.min(seg_bot, p.y))

  local dx = p.x - closest_x
  local dy = p.y - closest_y
  return (dx*dx + dy*dy) <= (r*r)
end

--- Returns true if point `p` (x,y) falls inside this collider.
--- Dispatches to the correct shape check based on `self.type`.
---@param p Usagi.Vec2
---@return boolean
function Collider:contains(p)
  if self.col_type == "circle"  then return check_circle(p, self)  end
  if self.col_type == "rect"    then return check_rect(p, self)    end
  if self.col_type == "capsule" then return check_capsule(p, self) end
  return false
end


-----------------------------
--- ColliderRegistry class
-----------------------------

---@class ColliderRegistry
---@field items Collider[]
local ColliderRegistry = {
  items = {}
}
ColliderRegistry.__index = ColliderRegistry

---Adds a Collider to the registry. If c is nil this method does nothing
---@param c Collider
function ColliderRegistry.add(c)
  if not c then return end
  table.insert(ColliderRegistry.items, c)
end

---Removes the Collider `c` from the registry
---@param c Collider
function ColliderRegistry.remove(c)
  ColliderRegistry.try_remove(c)
end

---Attempts to remove c from the registry. Returns true if the removal was successfule, false otherwise
---@param c any
function ColliderRegistry.try_remove(c)
  if not c then return false end
  for i,v in ipairs(ColliderRegistry.items) do
    if v == c then
      table.remove(ColliderRegistry.items, i)
      return true
    end
  end
  return false
end

return {
  Collider = Collider,
  ColliderRegistry = ColliderRegistry,
}
