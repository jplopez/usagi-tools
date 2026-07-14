---Missile Scene: Scene for the missile game

local Ray = require "ray"
local RaySampler = require("raycast.samplers")
local colliders = require("raycast.colliders")
local Collider = colliders.Collider
local ColliderRegistry = colliders.ColliderRegistry
local HitStrategy = require("raycast.hitstrategy")


------------------------
-- Public Types
------------------------


---@alias Missile {
--- x : integer,
--- y : integer,
--- r : integer,
--- c : Color,
--- direction : Usagi.Vec2,
--- speed : number }

---@alias Building {
--- x : integer,
--- y : integer,
--- w : integer,
--- h : integer,
--- c : Color }


-------------------
-- Local Functions/Helpers
-------------------


local function _mouse_dir_from(x,y)
  x,y = x or 0, y or 0
  local mx,my = input.mouse()
  return util.vec_to_direction(mx - x, my - y)
end

local building_colors = { gfx.COLOR_WHITE, gfx.COLOR_DARK_GRAY, gfx.COLOR_GREEN, gfx.COLOR_LIGHT_GRAY, gfx.COLOR_INDIGO, gfx.COLOR_ORANGE }


-----------------------
-- MissileScene Definition
-----------------------

---@class MissileGameScene : Scene
local MissileGameScene = {
  name = "missile",
  active = false,

  pos_x = 0, pos_y = 0, -- player current pos hit position 
  fire_r = 1,  -- max radius of the fire
  fire_x = 0,
  fire_y = 0,
  max_fire_r = 5,
  fire_rate = 0.5,
  fire_cd = 1, -- time between fires
  t_last_fire = 0,


  ---@type Building[]
  buildings = {},
  max_buildings = 10,
  x0 = 32,        -- starting x-pos for buildings
  default_w = 16, -- default with of buildings
  h_step = 16,    -- building height is in multiples of 16px

  ---@type Missile[]
  missiles = {},
  max_missiles = 10,
  spawn_delay = 2,
  t_last_spawn = 0,
  missile_max_speed = 2,

  hit_count = 0,
  miss_count = 0,

}
MissileGameScene.__index = MissileGameScene


-------------------------
-- MissileScene Functions
-------------------------

--- Resets missiles and buildings, and adds State.Missile 
function MissileGameScene:load()

  -- game states
  State.Missile = {
    Idle      = 10,
    Shooting  = 20,
  }
  State.CurrentState = State.Missile.Idle

  self.buildings = {}
  self.missiles = {}
  self.hit_count = 0
  self.miss_count = 0

  -- starting x-pos for buildings
  local _x = self.x0
  for i=1,self.max_buildings do

    -- don't build past the 300 pixel
    if _x >=300 then break end

    -- randomize buildings 
    local _w = math.random(1, 2) * self.default_w
    local _h = math.random(2, 5) * self.h_step
    local _y = usagi.GAME_H - _h
    local _c = building_colors[math.random(#building_colors)]
    self:create_building(_x, _y, _w, _h, _c)
    _x += _w
  end

  self.active = true
end

function MissileGameScene:unload()
  self.active = false
end

---Spawn and moves missiles, updates player position, and checks inputs to detect hit missiles.
---If any missiles are hit, removes them from the list
---@param dt number -- delta time 
function MissileGameScene:update(dt)


  print("State: " .. State.CurrentState)


  -- spawn missile, if cooldown is complete
  self:spawn_missile(dt)

  -- we are shooting, check for hit missiles
  if State.CurrentState == State.Missile.Shooting then
    -- check if player shoot hit a missile
    self:check_player_hits(dt)
    self.t_last_fire += dt
  end

  -- left click means player is firing
  if input.mouse_pressed(input.MOUSE_LEFT) then
    print("fire!")
    self:player_fire(dt)
  end
  self:check_missiles_hits(self.fire_r)


  -- move missiles
  local offscreen = {}
  for i, m in ipairs(self.missiles) do

    m.x = m.x + (m.direction.x * m.speed)
    m.y = m.y + (m.direction.y * m.speed)

    -- mark missiles off screen to be deleted
    if m.y >= usagi.GAME_H then
      offscreen[#offscreen+1] = i
    end

  end

  -- delete missiles offscreen
  for i=1,#offscreen do
    table.remove(self.missiles, offscreen[i])
  end

  -- update player position
  self.pos_x, self.pos_y = input.mouse()
end

---Perform the player fire
---@param dt any
function MissileGameScene:player_fire(dt)
  -- still on cooldown
  if State.CurrentState == State.Missile.Shooting 
    and self.t_last_fire < self.fire_cd then return end

  
  State.CurrentState = State.Missile.Shooting
  self.t_last_fire = 0
  self.fire_x = self.pos_x
  self.fire_y = self.pos_y
end

---Checks if player latest fire hit a missile 
---@param dt integer -- delta time
function MissileGameScene:check_player_hits(dt)

    -- end of shooting
    if self.t_last_fire > self.fire_rate then
      print("end of shooting")
      State.CurrentState = State.Missile.Idle
      return
    end

    self.fire_r = 1 + (self.t_last_fire * self.max_fire_r) / self.fire_rate

    -- `circle_all` returns me all missiles hit within the radious `r`.
    -- we cast from the player position, and the hit strategy is collider with tag 'missile'
    -- local hits = Ray.Raycast.circle_all(
    --               self.pos_x, self.pos_y, self.fire_r,
    --               Ray.HitStrategy.Collider.tag("missile"))  -- hit strategy : collider with tag 'missile'
    -- print(usagi.dump(hits))
    -- -- remove missiles and their colliders
    -- for i,hit in ipairs(hits) do
    --   local c = hit.collider
    --   if c then
    --     local m_index = c.data.index
    --     table.remove(self.missiles, m_index)
    --     Ray.ColliderRegistry.try_remove(c)
    --   end
    -- end

end

---Check if a missile has hit a building. If so, applies damage to building
---@param dt integer -- delta time from update
function MissileGameScene:check_missiles_hits(dt)

end

function MissileGameScene:draw(dt)
  gfx.clear(gfx.COLOR_DARK_BLUE)

  for i=1,#self.missiles do
    local m = self.missiles[i]
    gfx.circ_fill(m.x, m.y, m.r, m.c)
  end

  for i=1,#self.buildings do
    local b = self.buildings[i]
    gfx.rect_fill(b.x, b.y, b.w, b.h, b.c)
  end

  gfx.circ(self.pos_x, self.pos_y, 2, gfx.COLOR_YELLOW)

  if State.CurrentState == State.Missile.Shooting then
    gfx.circ_fill(self.fire_x, self.fire_y, self.fire_r, gfx.COLOR_YELLOW)
  end

end

---Creates a building with a collider and adds it to the self.buildings and collider registry
---@param _x integer
---@param _y integer
---@param _w integer
---@param _h integer
---@param _c Color
function MissileGameScene:create_building(_x, _y, _w, _h, _c)

    ---@type Building
    local b = {
      x = _x,
      y = _y,
      w = _w,
      h = _h,
      c = _c,

      ---@type Collider
      col = nil
    }

    self.buildings[#self.buildings+1] = b

    -- b.col = Ray.Collider.rect(_x,_y,_w,_h, { tag = "building"})
    -- Ray.ColliderRegistry.add(b.col)
end

---Applies damage to a building
---@param d number --damage ammount
function MissileGameScene:damage_building(d) end

---Spawns a missile if the cooldown time has passed and there's room for more missiles
---@param dt number -- delta time from update
function MissileGameScene:spawn_missile(dt)

  -- update timer
  self.t_last_spawn += dt

  -- exit early if conditions arent met to spawn a missile
  if self.t_last_spawn < self.spawn_delay
    or #self.missiles >= self.max_missiles then return end

  -- spawn missile
  ---@type Missile
  local m = {
    x = math.random(0, 320),
    y = 0,
    r = math.random(1,2),
    c = gfx.COLOR_RED,
    speed = 0.3 + (math.random() * 0.7),
  }

  -- missile direction is based on a random building
  --pick random building
  local b = self.buildings[math.random(1, #self.buildings)]
  -- calculate target
  local tx, ty = b.x + b.w * 0.5, b.y
  -- compute direction
  m.direction = util.normalize2_as_vec(tx - m.x, ty - m.y)

  local index = #self.missiles+1
  -- add to missiles list
  self.missiles[index] = m

  -- create missile collider  
  -- add the missile index reference to determine which missile this collider belongs to
  -- local col = Ray.Collider.circle(m.x, m.y, m.r, {tag = "missile", index = index })
  -- Ray.ColliderRegistry.add(col)

  -- reset spawn cooldown
  self.t_last_spawn = 0

end

---Destroy the missiles specified in `m_array`. Also removes the Colliders from the registry
---@param m_array any
function MissileGameScene:destroy_missiles(m_array)
  if not m_array or #m_array == 0 then return end

  -- for i,m in ipairs(m_array) do
  --   Ray.ColliderRegistry.remove(m)
  --   table.remove(self.missiles, m.index)
  -- end
end

return MissileGameScene