---@type Scene
local Stealth = {
  name = "stealth", active = false,
}
Stealth.__index = Stealth

function Stealth:new(tbl) return setmetatable(tbl or {}, self) end

function Stealth:load() end

function Stealth:unload() end

function Stealth:update(dt) end

function Stealth:draw(dt) print("stealth scene") end

return Stealth