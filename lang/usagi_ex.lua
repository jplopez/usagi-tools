-------------------------
--  Usagi Extensions
-------------------------

---@class Usagi
local usagi = usagi

function usagi.rand(tbl)
    tbl = tbl or {}
    return tbl[math.random(#tbl)]
end

---@class Usagi.Util
local util = util

---Clone of `vec_from_angle` that returns the x,y coordinate as separated values, instead of a table.
---This will avoid the table allocation while sampling raycast points
---@param angle number  radians
---@param len? number   magnitude (default 1)
---@return number
---@return number
function util.vec_from_angle_values(angle, len)
  len = len or 1
  return math.cos(angle) * len, math.sin(angle) * len
end


---Normalization of 2 numeric values, returned as 2 separate values
---@param dx number
---@param dy number
---@return integer
---@return integer
function util.normalize2(dx, dy)
    local len = math.sqrt(dx*dx + dy*dy)
    if len == 0 then
        return 0, 0
    end
    return dx / len, dy / len
end

---Normalization of 2 numeric values, returned as a Usagi.Vec2
---@param dx any
---@param dy any
---@return table
function util.normalize2_as_vec(dx, dy)
    local len = math.sqrt(dx*dx + dy*dy)
    if len == 0 then
        return { x = 0, y = 0 }
    end
    return { x = dx / len, y = dy / len }
end

---Returns the direction values (-1,0,1) for `dx` and `dy` as separate values 
---
---For each input:
---* a > 0 -> 1
---* a < 0 -> -1
---* a == 0 -> 0
---
---@param dx number
---@param dy number
---@return integer  -- dx normalized
---@return integer  -- dy normalized
function util.get_direction_values(dx, dy)
    if dx == 0 and dy == 0 then return 0, 0 end
    return (dx > 0 and 1 or dx < 0 and -1 or 0),
           (dy > 0 and 1 or dy < 0 and -1 or 0)
end

---Returns the direction values (-1,0,1) for `dx` and `dy` as {x,y} table
---
---This method uses `util.get_direction_values` to calculate the values
---
---For each input:
---* a > 0 -> 1
---* a < 0 -> -1
---* a == 0 -> 0
---
---@param dx number
---@param dy number
---@return Usagi.Vec2
function util.vec_to_direction(dx, dy)
  local _x,_y = util.get_direction_values(dx, dy)
  return {x = _x, y = _y }
end


function util.vec_in_screen(x, y)
    return x >= 0 and x <= usagi.GAME_W and y >=0 and y <= usagi.GAME_H
end

-- wrapper for `print(string.format(s))` 
function util.sprintf(s, ...)
    print(string.format(s, ...))
end
