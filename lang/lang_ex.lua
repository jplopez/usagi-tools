--- Lua Language Extension
local Assert = {}
Assert.__index = Assert


function Falsy(value, msg) assert(type(value) == "nil" or not value, msg)  end
function Truthy(value, msg) assert(type(value) ~= "nil" and value, msg) end


---@generic T
---@param value T
---@param expected T
---@param comparison_fun? fun(value:T, expected:T):boolean
---@param msg? string
function EqualTo(value, expected, comparison_fun, msg)
  if comparison_fun then
    assert(comparison_fun(value, expected), msg)
  else
    assert(value == expected, msg)
  end
end

---@generic T
---@param value T
---@param expected T
---@param comparison_fun fun(value:T, expected:T) : boolean
---@param msg string
function NotEqualTo(value, expected, comparison_fun, msg)
  if comparison_fun then
    assert(not comparison_fun(value, expected), msg)
  else
    assert(value ~= expected, msg)
  end
end

---Non nil and numeric type. Optionally, you can pass a boolean function with additional conditions for the assertion to be true.
---@param value number | integer
---@param bool_expression? fun(value:any, ...?:any):boolean
---@param msg? string
---@param ...? any
function Numeric(value, bool_expression, msg, ...)
  if bool_expression then
    assert(type(value) == "number" and bool_expression(value, ...), msg)
  end
  assert(not value and type(value) == "number", msg)
end

---Assert if Number is within `min_value` and `max_value`. Assert includes the limit values if `inclusive` is set to true
---@param value number
---@param min_value number
---@param max_value number
---@param inclusive boolean
function Within(value, min_value, max_value, inclusive)
  return Numeric(value,
    function(v)
      if inclusive then
        return v >= min_value and v <= max_value
      end
      return v > min_value and v < max_value
    end)
end

Assert.Iz = {
  Falsy = Falsy,
  Truthy = Truthy,
  EqualTo = EqualTo,
  NotEqualTo = NotEqualTo,
  Numeric = Numeric,
  Within = Within
}

return Assert
