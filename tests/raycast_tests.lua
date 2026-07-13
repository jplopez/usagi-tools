-- Tests for Ray and Collider
-- Run from _update during development:
--   RaycastTests.run_all()

RaycastTests = {}

-- ─── helpers ───────────────────────────────────────────────────────────────

local function _fresh_registry()
  ColliderRegistry.items = {}
end

local function _collect_hits(ox, oy, dx, dy, cast_type, params, source)
  local hits = {}
  Ray.detect(ox, oy, dx, dy, cast_type, params, function(hit)
    table.insert(hits, hit)
  end, source)
  return hits
end

-- ─── Collider tests ────────────────────────────────────────────────────────

function RaycastTests.test_collider_contains()
  local c_circ = Collider.circle(100, 100, 20, nil)
  local c_rect = Collider.rect(50, 50, 40, 30, nil)
  local c_caps = Collider.capsule(200, 100, 20, 60, nil)

  -- circle: center is inside
  assert(c_circ:contains({x=100, y=100}),  "circle center should be inside")
  -- circle: point on edge is outside (strict)
  assert(not c_circ:contains({x=120, y=100}), "circle edge should be outside")
  -- circle: clearly outside
  assert(not c_circ:contains({x=200, y=200}), "far point should be outside circle")

  -- rect: top-left corner is inside (half-open)
  assert(c_rect:contains({x=50, y=50}),    "rect top-left should be inside")
  -- rect: center is inside
  assert(c_rect:contains({x=70, y=65}),    "rect center should be inside")
  -- rect: right edge is outside (half-open)
  assert(not c_rect:contains({x=90, y=65}), "rect right edge should be outside")
  -- rect: clearly outside
  assert(not c_rect:contains({x=10, y=10}), "far point should be outside rect")

  -- capsule: center of body is inside
  assert(c_caps:contains({x=200, y=100}),  "capsule body center should be inside")
  -- capsule: top cap center is inside
  assert(c_caps:contains({x=200, y=70}),   "capsule top cap should be inside")
  -- capsule: bottom cap center is inside
  assert(c_caps:contains({x=200, y=130}),  "capsule bottom cap should be inside")
  -- capsule: clearly outside
  assert(not c_caps:contains({x=100, y=100}), "far point should be outside capsule")

  print("test_collider_contains: PASSED")
end

function RaycastTests.test_collider_move_to()
  local c = Collider.circle(0, 0, 10, nil)

  assert(c:contains({x=0, y=0}),          "should be at origin initially")
  assert(not c:contains({x=50, y=50}),     "should not be at (50,50) yet")

  c:move_to(50, 50)

  assert(c:contains({x=50, y=50}),         "should be at (50,50) after move_to")
  assert(not c:contains({x=0, y=0}),       "should no longer be at origin")

  print("test_collider_move_to: PASSED")
end

-- ─── Ray resolver tests ────────────────────────────────────────────────────

function RaycastTests.test_ray_line_hits()
  _fresh_registry()
  local c = Collider.circle(100, 100, 10, nil)
  ColliderRegistry.add(c)

  -- ray fires upward from below, should hit the circle
  local hits = _collect_hits(100, 200, 0, -1, "line", {dist=200})
  assert(#hits == 1,            "line ray should find exactly one hit")
  assert(hits[1].collider == c, "hit collider should be the circle")

  -- ray fires in wrong direction, should miss
  local misses = _collect_hits(100, 200, 0, 1, "line", {dist=200})
  assert(#misses == 0,          "line ray going away should find no hits")

  print("test_ray_line_hits: PASSED")
end

function RaycastTests.test_ray_line_closest_first()
  _fresh_registry()
  local near = Collider.circle(100, 150, 8, nil)
  local far  = Collider.circle(100,  80, 8, nil)
  ColliderRegistry.add(near)
  ColliderRegistry.add(far)

  local hits = _collect_hits(100, 200, 0, -1, "line", {dist=200})
  assert(#hits == 2,                        "should hit both colliders")
  assert(hits[1].collider == near,          "nearest collider should be first")
  assert(hits[2].collider == far,           "farthest collider should be second")
  assert(hits[1].distance_sq < hits[2].distance_sq, "distance_sq must be ascending")

  print("test_ray_line_closest_first: PASSED")
end

function RaycastTests.test_ray_circle_full()
  _fresh_registry()
  -- collider sitting directly to the right at radius distance
  local c = Collider.circle(160, 100, 5, nil)
  ColliderRegistry.add(c)

  -- full 360 arc should find it regardless of direction
  local hits = _collect_hits(100, 100, 1, 0, "circle", {r=60, arc=360, step=2})
  assert(#hits == 1,            "full circle cast should find the collider")
  assert(hits[1].collider == c, "hit should be the right collider")

  print("test_ray_circle_full: PASSED")
end

function RaycastTests.test_ray_grid_hits()
  _fresh_registry()
  local c = Collider.rect(90, 50, 20, 20, nil)
  ColliderRegistry.add(c)

  -- 3x1 grid shooting upward, middle column passes through the rect
  local hits = _collect_hits(100, 200, 0, -1, "grid", {rows=1, cols=3, dist=200, spacing=20})
  assert(#hits == 1,            "grid cast should find exactly one hit")
  assert(hits[1].collider == c, "grid hit should be the rect collider")

  print("test_ray_grid_hits: PASSED")
end

function RaycastTests.test_ray_custom_source()
  _fresh_registry()

  -- custom source: treats any point where x > 150 as a hit, returns a sentinel table
  local wall = { tag = "wall" }
  local source = function(p)
    return p.x > 150 and wall or nil
  end

  local hits = _collect_hits(100, 100, 1, 0, "line", {dist=100}, source)
  assert(#hits == 1,              "custom source should produce one unique hit")
  assert(hits[1].collider == wall,"hit.collider should be the sentinel table")

  print("test_ray_custom_source: PASSED")
end

function RaycastTests.test_ray_assert_unknown_type()
  local ok, err = pcall(function()
    Ray.detect(0, 0, 1, 0, "triangle", {}, function() end)
  end)
  assert(not ok,                        "unknown cast type should raise an error")
  assert(err:find("triangle"),          "error should mention the unknown type")

  print("test_ray_assert_unknown_type: PASSED")
end

-- ─── run all ───────────────────────────────────────────────────────────────

function RaycastTests.run_all()
  RaycastTests.test_collider_contains()
  RaycastTests.test_collider_move_to()
  RaycastTests.test_ray_line_hits()
  RaycastTests.test_ray_line_closest_first()
  RaycastTests.test_ray_circle_full()
  RaycastTests.test_ray_rect_area()
  RaycastTests.test_ray_grid_hits()
  RaycastTests.test_ray_custom_source()
  RaycastTests.test_ray_assert_unknown_type()
  print("All RaycastTests passed.")
end
