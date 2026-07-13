local cfg = _config()
cfg = cfg or {}

---@alias Color integer
---| 0 "COLOR_TRUE_WHITE"
---| 1 "COLOR_BLACK"
---| 2 "COLOR_DARK_BLUE"
---| 3 "COLOR_DARK_PURPLE"
---| 4 "COLOR_DARK_GREEN"
---| 5 "COLOR_BROWN"
---| 6 "COLOR_DARK_GRAY"
---| 7 "COLOR_LIGHT_GRAY"
---| 8 "COLOR_WHITE"
---| 9 "COLOR_RED"
---| 10 "COLOR_ORANGE"
---| 11 "COLOR_YELLOW"
---| 12 "COLOR_GREEN"
---| 13 "COLOR_BLUE"
---| 14 "COLOR_INDIGO"
---| 15 "COLOR_PINK"
---| 16 "COLOR_PEACH"


---@class Coin
---@field x integer
---@field y integer
---@field r integer
---@field on_ground boolean
---@field vy number
---@field c Color
Coin = {
    x = 0,
    y = 0, -- ensure coin is created above the ground level
    r = 5,
    on_ground = false,
    vy = 0,
    c = gfx.COLOR_YELLOW
}
Coin.__index = Coin

function Coin:new(_x,_y,_r,_c)
  return setmetatable({
    x = _x or 0,
    y = _y or 0, -- ensure coin is created above the ground level
    r = _r or 5,
    on_ground = false,
    vy = 0,
    c = _c or gfx.COLOR_YELLOW}, self)
end

function Coin._update(self,dt)
  -- apply gravity to coins
  if not self.on_ground then
    self.vy = math.min(cfg.gravity, self.vy + 1)
  else
    self.vy = 0
  end

  self.y += self.vy

end

function Coin._draw(self, dt) gfx.circ_fill(self.x, self.y, self.r, self.c) end