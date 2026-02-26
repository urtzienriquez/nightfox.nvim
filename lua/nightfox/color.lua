-- Minimal color utility
local M = {}

local function clamp(v, min, max)
  return math.max(min, math.min(max, v))
end

local function round(x)
  return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

-- Create color from hex string "#RRGGBB"
function M.from_hex(hex)
  hex = hex:gsub("^#", "")
  local n = tonumber(hex, 16)
  return {
    r = math.floor(n / 0x10000) / 255,
    g = math.floor(n / 0x100) % 0x100 / 255,
    b = n % 0x100 / 255,
  }
end

function M.to_hex(c)
  return string.format(
    "#%02x%02x%02x",
    round(clamp(c.r, 0, 1) * 255),
    round(clamp(c.g, 0, 1) * 255),
    round(clamp(c.b, 0, 1) * 255)
  )
end

-- Linear blend: f=0 -> self, f=1 -> other
function M.blend(c1, c2, f)
  return {
    r = (c2.r - c1.r) * f + c1.r,
    g = (c2.g - c1.g) * f + c1.g,
    b = (c2.b - c1.b) * f + c1.b,
  }
end

-- Shade: f < 0 = darker, f > 0 = brighter, range [-1, 1]
function M.shade(c, f)
  local t = f < 0 and 0 or 1
  local p = math.abs(f)
  return {
    r = (t - c.r) * p + c.r,
    g = (t - c.g) * p + c.g,
    b = (t - c.b) * p + c.b,
  }
end

-- Brighten by value in HSV space
function M.brighten(hex, v)
  local c = M.from_hex(hex)
  local max = math.max(c.r, c.g, c.b)
  local min = math.min(c.r, c.g, c.b)
  local delta = max - min

  -- to HSV
  local h, s, val = 0, 0, max
  if max ~= 0 then
    s = delta / max
  end
  if delta ~= 0 then
    if max == c.r then
      h = ((c.g - c.b) / delta) % 6
    elseif max == c.g then
      h = (c.b - c.r) / delta + 2
    else
      h = (c.r - c.g) / delta + 4
    end
    h = h * 60
  end

  val = clamp(val + v / 100, 0, 1)

  -- back to RGB
  local function f(n)
    local k = (n + h / 60) % 6
    return val - val * s * math.max(math.min(k, 4 - k, 1), 0)
  end
  return M.to_hex({ r = f(5), g = f(3), b = f(1) })
end

-- Create a shade table {base, bright, dim} from a base hex color
function M.make_shade(base, bright_factor, dim_factor, is_light)
  bright_factor = bright_factor or 0.15
  dim_factor = dim_factor or -0.15
  local bc = M.from_hex(base)
  return {
    base = base,
    bright = M.to_hex(M.shade(bc, bright_factor)),
    dim = M.to_hex(M.shade(bc, dim_factor)),
    light = is_light or false,
  }
end

-- Blend two hex colors
function M.blend_hex(hex1, hex2, f)
  return M.to_hex(M.blend(M.from_hex(hex1), M.from_hex(hex2), f))
end

return M
