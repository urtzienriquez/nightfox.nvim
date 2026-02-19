local M = {}

function M.load(name)
  local mod = require("nightfox.palette." .. name)
  return mod.palette
end

return M
