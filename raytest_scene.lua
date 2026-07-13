local Ray2 = require('ray2')
local RaySampler = require("mod.samplers")
local colliders = require("mod.colliders")
local Collider = colliders.Collider
local ColliderRegistry = colliders.ColliderRegistry
local HitStrategy = require("mod.hitstrategy")

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

}
Player.sampler = 
  -- RaySampler:line_sampler() 

  -- RaySampler:circle_sampler()
-- Player.sampler.arc = Player.fov

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
}

function RayTestScene:load()

  State.Colliders = {
    player = Collider.rect(
      Player.x, Player.y,
      Player.w, Player.h,
      {tag = "player"}),

    circle = Collider.circle(60, 90, 50, {tag = "obstacle"}),
    rect = Collider.rect(200, 50, 100, 80, {tag = "obstacle"}),
  }

  ---@type RaycastHit[]
  State.Hits = {}

  print(usagi.dump(Player))
end

function RayTestScene:unload()
  Player:destroy()
  State.Colliders = nil
end

--- Update
function RayTestScene:update(dt)
  RayTestScene.move_player(dt)
  RayTestScene.cast(dt)

  -- debug toggle
  if(input.key_released(input.KEY_0)) then __debug = not __debug end
end

--- Draw
function RayTestScene:draw(dt)

  gfx.clear(gfx.COLOR_BLACK)
  gfx.rect(0,0,usagi.GAME_W, usagi.GAME_H, gfx.COLOR_GREEN)
  gfx.text("Hits: " .. (State.Hits and #State.Hits or "N/A"), 1, 1, gfx.COLOR_WHITE)
  gfx.text("Debugging", 260, 1, __debug and gfx.COLOR_GREEN or gfx.COLOR_DARK_GRAY)

  RayTestScene.draw_collider(State.Colliders.circle, gfx.COLOR_GREEN, false)
  RayTestScene.draw_collider(State.Colliders.rect, gfx.COLOR_GREEN, false)
  RayTestScene.draw_collider(State.Colliders.player, gfx.COLOR_GREEN, true)

  RayTestScene.draw_player(dt, gfx.COLOR_ORANGE)

end

function RayTestScene.move_player(dt)

  -- calculate direction
  Player.dir_x = _press_or_held(input.RIGHT) and 1 or
        (_press_or_held(input.LEFT) and -1 or 0)
  Player.dir_y = _press_or_held(input.DOWN) and 1 or
        (_press_or_held(input.UP) and -1 or 0)

  Player.x += Player.dir_x * dt * Player.speed
  Player.y += Player.dir_y * dt * Player.speed

  -- keep player and its collider in sync
  State.Colliders.player.x = Player.x
  State.Colliders.player.y = Player.y

end

function RayTestScene.cast(dt)

  State.Hits = Ray2.cast(
      Player:x_center(), Player:y_center(),
      Player.dir_x, Player.dir_y,
      Player.sampler,
      HitStrategy.Collider.tag("obstacle"), -- hit condition: colliders with tag 'obstacle' 
      function() return true end) -- exit condition: first hit returns 

  if not State.Hits or #State.Hits == 0 then return end
  util.sprintf("Ray2.cast -> hits: %d ", #State.Hits)
  for i,hit in ipairs(State.Hits) do 
    util.sprintf("Ray2.cast -> Hit %d : '%s' (x,y):( %d , %d )",i, hit.collider.col_type, hit.collider.x, hit.collider.y)
  end

end

---Draws a colider in the specified color
---@param collider Collider
---@param color Color
---@param fill boolean
function RayTestScene.draw_collider(collider, color, fill)
  if not collider then return end
  local type = collider.col_type
  color = color or gfx.COLOR_WHITE

  if fill == true then
    if type == "circle" then
      gfx.circ_fill(collider.x, collider.y, collider.r, color)
    elseif type == "rect" then
      gfx.rect_fill(collider.x, collider.y, collider.w, collider.h, color)
    elseif type == "line" then
      --TODO
    end
  else
    if type == "circle" then
      gfx.circ(collider.x, collider.y, collider.r, color)
    elseif type == "rect" then
      gfx.rect(collider.x, collider.y, collider.w, collider.h, color)
    elseif type == "line" then
      --TODO
    end
  end

end

---@param dt number
---@param color Color
function RayTestScene.draw_player(dt, color)

  color = color or gfx.COLOR_WHITE
  gfx.rect_fill(Player.x, Player.y, Player.w, Player.h, color)

  if not __debug then return end

  -- print raycast lines
  local px, py = Player:center()
  local count = 0
  local clr = gfx.COLOR_WHITE
  for x, y in Player.sampler:iter(px,py,Player.dir_x, Player.dir_y) do
    clr = (clr == gfx.COLOR_WHITE) and gfx.COLOR_ORANGE or gfx.COLOR_WHITE
    if(x==0 or x == usagi.GAME_W) then clr = gfx.COLOR_RED end
    --print("x,y " .. x .. " " .. y)
    gfx.px(x, y, clr)
    count += 1
  end
  gfx.text("Pts:  " .. count , 1, 10, gfx.COLOR_WHITE)
  gfx.text(string.format(" (%.2f,%.2f) (%d,%d)",Player.x, Player.y, Player.dir_x, Player.dir_y), 60,1,gfx.COLOR_ORANGE)
end

return RayTestScene