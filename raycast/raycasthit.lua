---RaycastHit : Object to represent a possitive hit from a Raycast
local _ require("lang.usagi_ex")

---@class RaycastHit
---@field collider Collider | table | boolean | nil
---@field point Usagi.Vec2
---@field distance number
---@field distance_sq number
---@field direction Usagi.Vec2  -- normalized direction from origin to hit
---@field normal? Usagi.Vec2     -- optional, depends on collider type
local RaycastHit = {}
RaycastHit.__index = RaycastHit

---Constructor for RaycastHit
---@param origin Usagi.Vec2
---@param point Usagi.Vec2
---@param collider Collider | table | boolean | nil
---@return RaycastHit
function RaycastHit.new(origin, point, collider)
    local dx = point.x - origin.x
    local dy = point.y - origin.y
    local dist_sq = util.vec_dist_sq(origin, point)

    return setmetatable({
        collider = collider,
        point = point,
        distance = math.sqrt(dist_sq),
        distance_sq = dist_sq,
        direction = util.vec_to_direction(dx, dy ),
    }, RaycastHit)
end

return RaycastHit