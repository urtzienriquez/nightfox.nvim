local M = {}

function M.load(name)
  local mod = require("nightfox.palette." .. name)
  return mod.palette  -- <- important!
end

return M
