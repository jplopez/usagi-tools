-- Ray library
local Ray = require("ray")


-------------------------------
-- Scenes 
-------------------------------

---@class Scene
---@field name   string
---@field active boolean
---@field cur?   integer
---@field count? integer
---@field examples? string[]
local Scene = {
  name = "", active = false
}
Scene.__index = Scene
---Constructor
---@param tbl table | metatable
---@return Scene | metatable
function Scene:new(tbl)
  return setmetatable(tbl or {}, self)
end
---Initializes a scene. Is called during `load_scene`
function Scene:load() end
---Finalizes a scene. Is called during `load_scene` to the exit scene
function Scene:unload() end
---Update method called by main _update(dt) function 
---@param dt number
function Scene:update(dt) end
---Draw method called by main _draw(dt) function
---@param dt any
function Scene:draw(dt) end

-- Scenes
local RayTestScene = require("raytest_scene")
local MissileScene = require("missile_scene")
local Stealth = require("stealth")


-- SCENE MANAGEMENT

---@param name string -- scene name
local function load_scene(name)

  if not State.Scenes[name] then return end

  local exitScene = State.CurrentScene
  if exitScene then exitScene:unload() end

  State.CurrentScene = State.Scenes[name]
  State.CurrentScene:load()
end

-- CONFIG 

function _config()
  return {
    name = "Usagi Raycast",
    game_id = "com.ameba.raycast",

    examples = { "missile", "stealth"}
  }
end


-- INIT 

function _init()

  State = {
    ---@type Scene
    CurrentScene = nil,

    CurrentState = 0,

    Scenes = {
      test = RayTestScene,
      ---@type Scene | metatable
      missile = MissileScene,
      ---@type Scene | metatable
      stealth = Stealth:new({}),
    },

    SceneType = {
      StartScene   = 10,
      ExampleScene = 20,
    },

    GameStates = {
      Stopped  = 100,
      Playing  = 200,
      Gameover = 300
    }
  }

  -- register example games as menu items
  local ex = _config().examples
  if not ex then return end
  for i, v in ipairs(ex) do
    usagi.menu_item(v, function() load_scene(v) end)
  end

  -- load random scene 
  load_scene("test")

end


function _update(dt)
  if State.CurrentScene then
    State.CurrentScene:update(dt)
  else
    print("no scene to update")
  end
end


function _draw(dt)
  gfx.clear(0)
  if State.CurrentScene then
    State.CurrentScene:draw(dt)
  else 
    print("no scene to draw")
  end
end


