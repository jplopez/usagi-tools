A = {}

A.True = function(value, msg, bool_fn, ...)
  msg = msg or "Assert Failed: Must be true"
  local bul = bool_fn(value, ...)
  assert(bul, msg)
end

A.False = function(value, msg, bool_fn, ...)
  msg = msg or "Assert Failed: Must be False"
  local bul = bool_fn(value, ...)
  assert(not bul, msg)
end

A.Haz = {

  exactly = function(value, comparing, msg) 
    local _m = "value must have exactly " .. comparing
    assert(#value == comparing, msg or _m)
  end,

  at_least = function(value, comparing, msg) 
    local _m = "value must have at least " .. comparing
    assert(#value > comparing, msg or _m)
  end,

  at_least_or_same = function(value, comparing, msg) 
    local _m = "value must have at least or same to " .. comparing
    assert(#value >= comparing, msg or _m)
  end,

  at_most = function(value, comparing, msg) 
    local _m = "value must have at least " .. comparing
    assert(#value < comparing, msg or _m)
  end,

  at_most_or_same = function(value, comparing, msg) 
    local _m = "value must have at least or same to " .. comparing
    assert(#value <= comparing, msg or _m)
  end,

  same_as = function(value, comparing, msg) 
    A.Haz.exactly(value, #comparing, "value (".. #value ..") must have same as comparing (".. #comparing .. ")")
  end,

  more_than = function(value, comparing, msg) 
    A.Haz.at_least(value, #comparing, "value (".. #value ..") must have more than comparing (".. #comparing .. ")")
  end,

  less_than = function(value, comparing, msg) 
    A.Haz.at_most(value, #comparing, "value (".. #value ..") must have less than comparing (".. #comparing .. ")")
  end,

  more_or_same_than = function(value, comparing, msg) 
    A.Haz.at_least_or_same(value, #comparing, "value (".. #value ..") must have more or same than comparing (".. #comparing .. ")")
  end,

  less_or_same_than = function(value, comparing, msg) 
    A.Haz.at_most_or_same(value, #comparing, "value (".. #value ..") must have less or same than comparing (".. #comparing .. ")")
  end,

}

A.Iz = {

  is_nil = function(value, msg) 
    local _m = "value (" .. value .. ") must be nil"
    assert(value == nil, msg or _m)
  end,

  not_nil = function(value,msg) 
    local _m = "value must not be nil"
    assert(value ~= nil, msg or _m)
  end,

  empty = function(value, msg) 
    local _m = "value must not be empty"
    assert(#value == 0, msg or _m)
  end,

  not_empty = function(value, msg) 
    local _m = "value must not be empty"
    assert(#value > 0, msg or _m)
  end,

  zero = function(value, msg)
    local _m = "value (" .. value .. ") must be zero"
    assert(value == 0, msg or _m)
  end,

  not_zero = function(value, msg)
    local _m = "value (" .. value .. ") must be zero"
    assert(value ~= 0, msg or _m)
  end,

  gt = function(value, comparing, msg)
    local _m = "value (".. value .. ") must be greater than " .. comparing
    assert(value > comparing, msg or _m)
  end,

  gte = function(value, comparing, msg)
    local _m = "value (".. value .. ") must be greater or equal than " .. comparing
    assert(value >= comparing, msg or _m)
  end,

  lt = function(value, comparing, msg)
    local _m = "value (".. value .. ") must be less than " .. comparing
    assert(value < comparing, msg or _m)
  end,

  lte = function(value, comparing, msg)
    local _m = "value (".. value .. ") must be less or equal than " .. comparing
    assert(value <= comparing, msg or _m)
  end,

  equal_to = function(value, comparing, msg)
    local _m = "value (".. value .. ") must be equal to " .. comparing
    assert(value == comparing, msg or _m)
  end,


}
