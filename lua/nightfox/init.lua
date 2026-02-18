-- nightfox-minimal: a minimal nightfox/dayfox colorscheme plugin
local M = {}

local valid_themes = { nightfox = true, dayfox = true }

-- Default config
M.config = {
  transparent = false,
  terminal_colors = true,
}

function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end
end

function M.load(name)
  name = name or "nightfox"

  if not valid_themes[name] then
    vim.notify("nightfox-minimal: unknown theme '" .. name .. "'. Use 'nightfox' or 'dayfox'.", vim.log.levels.ERROR)
    return
  end

  local raw = require("nightfox.palette." .. name)
  local palette = raw.palette
  palette.meta = raw.meta

  local spec = raw.generate_spec(palette)
  spec.palette = palette

  -- Clear existing highlights
  if vim.g.colors_name then
    vim.cmd("hi clear")
  end
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  vim.o.termguicolors = true
  vim.g.colors_name = name
  vim.o.background = raw.meta.light and "light" or "dark"

  local hl = require("nightfox.highlights")
  hl.apply(spec, M.config)

  if M.config.terminal_colors then
    hl.apply_terminal(palette)
  end
end

-- lualine theme generator
function M.lualine(name)
  name = name or vim.g.colors_name or "nightfox"
  if not valid_themes[name] then return {} end

  local C = require("nightfox.color")
  local raw = require("nightfox.palette." .. name)
  local palette = raw.palette
  palette.meta = raw.meta
  local spec = raw.generate_spec(palette)
  local p = palette
  local base = C.from_hex(spec.bg0)

  local function fade(color, amount)
    return C.to_hex(C.blend(base, C.from_hex(color), amount or 0.3))
  end

  local tbg = M.config.transparent and "NONE" or spec.bg0

  return {
    normal = {
      a = { bg = p.blue.base,    fg = spec.bg0, gui = "bold" },
      b = { bg = fade(p.blue.base), fg = spec.fg1 },
      c = { bg = tbg, fg = spec.fg2 },
    },
    insert = {
      a = { bg = p.green.base,   fg = spec.bg0, gui = "bold" },
      b = { bg = fade(p.green.base), fg = spec.fg1 },
    },
    command = {
      a = { bg = p.yellow.base,  fg = spec.bg0, gui = "bold" },
      b = { bg = fade(p.yellow.base), fg = spec.fg1 },
    },
    visual = {
      a = { bg = p.magenta.base, fg = spec.bg0, gui = "bold" },
      b = { bg = fade(p.magenta.base), fg = spec.fg1 },
    },
    replace = {
      a = { bg = p.red.base,     fg = spec.bg0, gui = "bold" },
      b = { bg = fade(p.red.base), fg = spec.fg1 },
    },
    terminal = {
      a = { bg = p.orange.base,  fg = spec.bg0, gui = "bold" },
      b = { bg = fade(p.orange.base), fg = spec.fg1 },
    },
    inactive = {
      a = { bg = tbg, fg = p.blue.base },
      b = { bg = tbg, fg = spec.fg3, gui = "bold" },
      c = { bg = tbg, fg = spec.syntax.comment },
    },
  }
end

return M
