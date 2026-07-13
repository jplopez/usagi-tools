---@class Player
---@field x         integer
---@field y         integer
---@field vx        integer
---@field vy        integer
---@field on_ground boolean
---@field w         integer
---@field h         integer
---@field c         integer # color index from gfx.COLOR_* 
Player = {
  x=0, y=0,
  vx=0, vy=0,
  on_ground=false,
  w=8, h=16,
  c=gfx.COLOR_GREEN,
}
Player.__index = Player

---Player constructor
---@param tbl table
---@return Player
function Player:new(tbl)
  return setmetatable(tbl or {}, self)
end

---Player factory for default player
---@param _x integer  # initial x position of player
---@param _y integer  # initial y position of player
---@return Player
function Player.default(_x,_y)
  return Player:new({
    x =_x or 0,
    y= _y or 0,
    vx = 0, vy = 0,
    on_ground = false,
    w = 8, h = 16,
    c = gfx.COLOR_GREEN,
  })
end

function Player.horizontal_move(self, dt, dx) end

function Player.jump(self, dt) end

function Player.handle_input(self, dt) end

---Update function to be called from main _update(dt) method
---@param self Player
---@param dt number
function Player._update(self, dt) 
  Player.handle_input(self, dt)
  Player.horizontal_move(self, dt)
  -- apply gravity
end

---Draw function to be called from main _draw(dt) method
---@param self Player
---@param dt number
function Player._draw(self,dt)
  local r = self.w/2

  gfx.rect_fill(self.x - self.w/2, self.y - self.h/2, self.w, self.h, self.c)
end
