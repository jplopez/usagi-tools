local Ray = require('ray')
local RaySampler = require("raycast.samplers")

__debug = false

---comment
---@param action integer
---@return boolean
local function _press_or_held(action) 
  return input.pressed(action) or input.held(action)
end

---------------
--- Player 
---------------

---@class RaytestPlayer
local Player = {
  x = usagi.GAME_W / 2 - 8,
  y = usagi.GAME_H / 2 - 8,
  w = 16, h = 16,
  c = gfx.COLOR_GREEN,

  speed = 50,
  dir_x = 0,
  dir_y = 0,

  fov = 30,       -- 30degrees field of view
  dist_view = usagi.GAME_W, -- view distance
  ---@type RaySampler
  sampler = nil,
}

RaySampler:grid_sampler()

function Player:x_center() return  Player.x + Player.w/2 end
function Player:y_center() return  Player.y + Player.h/2 end

---Returns the x,y coordinates for the center of the player
---@return number -- center x-position
---@return number -- center y-position
function Player:center() return self:x_center(), self:y_center() end
function Player:destroy() self = nil end

----------------------
--- RayTestScene
----------------------

---@class RayTestScene : Scene
local RayTestScene = {
  name = "RayTest",
  active = false,

  -- rectangle colliders
  rect_collider = {x=200, y=50, w=100, h=50, clr=gfx.COLOR_GREEN},
  -- circle collider
  circle_collider = {x=60, y=90, r=50, clr=gfx.COLOR_GREEN},
}

function RayTestScene:load()

  -- initialized with false, will store RaycastHit results
  -- from rect and circ colliders
  State.Hits = {
    Circle = nil,
    Rect = nil,
  }
  Player.sampler = RaySampler:line_sampler()
  State.SamplerName = "Line"
  print(usagi.dump(Player))
end

function RayTestScene:unload()
  Player:destroy()
  State.Colliders = nil
end

--- Update
function RayTestScene:update(dt)
  RayTestScene.move_player(dt)
  RayTestScene:detect(dt)

  self.rect_collider.clr = (State.Hits.Rect and #State.Hits.Rect > 0) and
    gfx.COLOR_RED or gfx.COLOR_GREEN
  self.circle_collider.clr = (State.Hits.Circle and #State.Hits.Circle >0) and
    gfx.COLOR_RED or gfx.COLOR_GREEN

  if(input.released(input.BTN1)) then
    Player.sampler = RaySampler:line_sampler()
    State.SamplerName = "Line"
  end
  if(input.released(input.BTN2)) then
    Player.sampler = RaySampler:arc_sampler(30, 6)
    State.SamplerName = string.format("Arc(%d'  )",Player.sampler.arc)
  end
  if(input.released(input.BTN3)) then
    Player.sampler = RaySampler:grid_sampler(4, 4, 4, 16)
    State.SamplerName = "Grid " .. 
      Player.sampler.rows .. "x" .. Player.sampler.cols
  end

  -- debug toggle
  if(input.key_released(input.KEY_0)) then __debug = not __debug end
end

--- Draw
function RayTestScene:draw(dt)
  gfx.clear(gfx.COLOR_BLACK)

  --colliders
  gfx.rect(self.rect_collider.x, self.rect_collider.y, 
    self.rect_collider.w, self.rect_collider.h, self.rect_collider.clr)
  gfx.circ(self.circle_collider.x, self.circle_collider.y, 
    self.circle_collider.r, self.circle_collider.clr)
  -- player
  gfx.rect_fill(Player.x, Player.y, Player.w, Player.h, gfx.COLOR_ORANGE)
  -- ui
  gfx.rect(0,0,usagi.GAME_W, usagi.GAME_H, gfx.COLOR_GREEN)
  gfx.text("Debugging", 260, 1, __debug and gfx.COLOR_GREEN or gfx.COLOR_DARK_GRAY)

  RayTestScene:debug_draw()

end

function RayTestScene.move_player(dt)

  -- calculate direction
  Player.dir_x = _press_or_held(input.RIGHT) and 1 or
        (_press_or_held(input.LEFT) and -1 or 0)
  Player.dir_y = _press_or_held(input.DOWN) and 1 or
        (_press_or_held(input.UP) and -1 or 0)

  Player.x += Player.dir_x * dt * Player.speed
  Player.y += Player.dir_y * dt * Player.speed

end

function RayTestScene:detect(dt)
  local ccol, rcol = self.circle_collider, self.rect_collider
  local circle_hit_fn = function(p) return util.point_in_circ(p, ccol) end
  State.Hits.Circle = self:detect_hit(circle_hit_fn)
  local rect_hit_fn = function(p) return util.point_in_rect(p, rcol) end
  State.Hits.Rect = self:detect_hit(rect_hit_fn)
end

function RayTestScene:detect_hit(hit_fn)
  local hits = Ray.cast(
      Player:x_center(), Player:y_center(),
      Player.dir_x, Player.dir_y,
      Player.sampler,
      hit_fn,
      function() return true end) -- exit condition: first hit returns 

  local smplr = Player.sampler:sample(Player:x_center(), Player:y_center(),
      Player.dir_x, Player.dir_y, Player.sampler.length or 16)
  print(" sampler :" .. #smplr)
  return hits
end

local function draw_raycasthit(hits)
  if not hits or #hits==0 then return end
  for i, hit in ipairs(hits) do
    gfx.circ_fill(hit.point.x, hit.point.y, 2, gfx.COLOR_YELLOW)
  end
end

function RayTestScene:debug_draw()
  if not __debug then return end

  -- print raycast lines
  local px, py = Player:center()
  local count = 0
  local clr = gfx.COLOR_WHITE

  for x, y in Player.sampler:iter(px,py,Player.dir_x, Player.dir_y) do

    if (State.Hits.Circle and
        util.point_in_circ({x=x,y=y}, RayTestScene.circle_collider)) or
      (State.Hits.Rect and
        util.point_in_rect({x=x,y=y}, RayTestScene.rect_collider)) then
      clr = gfx.COLOR_DARK_GRAY
    else
      clr = (clr == gfx.COLOR_WHITE) and gfx.COLOR_ORANGE or gfx.COLOR_WHITE
      if(x==0 or x == usagi.GAME_W) then clr = gfx.COLOR_RED end
      count += 1
    end
    gfx.px(x, y, clr)

  end

  gfx.text(string.format("Ray:%s\n(%d pts)", State.SamplerName, count), 1, 1, gfx.COLOR_WHITE)
  gfx.text(string.format(" (%.2f,%.2f) (%d,%d)",Player.x, Player.y, Player.dir_x, Player.dir_y), 120,1,gfx.COLOR_ORANGE)

  draw_raycasthit(State.Hits.Circle)
  draw_raycasthit(State.Hits.Rect)

end


return RayTestScene