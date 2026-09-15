-- nightfox-minimal: a minimal nightfox/dayfox colorscheme plugin
local M = {}

local valid_themes = { nightfox = true, dayfox = true }

-- Default config
M.config = {
  transparent = false,
  terminal_colors = true,
  dim_inactive = false,
  code_block_bg = true, -- full-line bg tint on fenced code blocks
  statusline = true, -- set to false to disable the built-in statusline
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

  if M.config.on_load then
    M.config.on_load(spec, palette)
  end

  if M.config.terminal_colors then
    hl.apply_terminal(palette)
  end

  if M.config.dim_inactive then
    local factor = type(M.config.dim_inactive) == "number" and M.config.dim_inactive or 0.4
    hl.apply_dim_inactive(spec, factor)
  end

  if M.config.code_block_bg ~= false then
    hl.apply_code_blocks(spec)
  end

  if M.config.statusline ~= false then
    require("nightfox.statusline").apply(spec)
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("NightfoxSemanticTokens", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        client.server_capabilities.semanticTokensProvider = nil
      end
    end,
  })
end

-- GNOME dark/light auto-detection, with a state-file cache so startup never
-- has to block on a subprocess spawn: the cached theme applies instantly,
-- then an async check corrects it in the rare case it's stale.
local state_file = vim.fn.stdpath("state") .. "/nightfox_theme"

local function read_cached_theme()
  local f = io.open(state_file, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  content = content:gsub("%s+$", "")
  return valid_themes[content] and content or nil
end

local function write_cached_theme(name)
  local f = io.open(state_file, "w")
  if f then
    f:write(name)
    f:close()
  end
end

-- Synchronous fallback: only used on the very first run, before any cache exists.
local function get_gnome_theme_sync()
  local handle = io.popen("gsettings get org.gnome.desktop.interface color-scheme")
  local output = handle and handle:read("*a") or ""
  if handle then
    handle:close()
  end
  return output:find("dark") and "nightfox" or "dayfox"
end

-- Async check: reloads + refreshes the cache only if the real theme differs
-- from what's currently applied. Never blocks the main loop.
local function refresh_theme_from_gnome()
  vim.system(
    { "gsettings", "get", "org.gnome.desktop.interface", "color-scheme" },
    { text = true },
    function(res)
      if not res or res.code ~= 0 or not res.stdout then
        return
      end
      local theme = res.stdout:find("dark") and "nightfox" or "dayfox"
      vim.schedule(function()
        if vim.g.colors_name ~= theme then
          M.load(theme)
        end
        write_cached_theme(theme)
      end)
    end
  )
end

-- Apply on startup (only if not already set by user config)
if not vim.g.colors_name then
  local cached = read_cached_theme()
  if cached then
    M.load(cached)
  else
    local theme = get_gnome_theme_sync()
    M.load(theme)
    write_cached_theme(theme)
  end
  -- Self-correct asynchronously in case the cache is stale (system theme
  -- changed since Neovim was last opened).
  refresh_theme_from_gnome()
end

-- Register the auto-update: FocusGained only (a system theme change is a
-- focus-worthy event, not a per-buffer-switch one), async, debounced so
-- rapid focus toggling doesn't spam subprocess spawns.
local last_check_ms = 0
local MIN_CHECK_INTERVAL_MS = 2000

vim.api.nvim_create_autocmd("FocusGained", {
  group = vim.api.nvim_create_augroup("NightfoxGnomeSync", { clear = true }),
  callback = function()
    local now = vim.uv.now()
    if now - last_check_ms < MIN_CHECK_INTERVAL_MS then
      return
    end
    last_check_ms = now
    refresh_theme_from_gnome()
  end,
})

-- Push-based sync
local sigwinch = vim.uv.new_signal()
if sigwinch then
  sigwinch:start("sigwinch", vim.schedule_wrap(refresh_theme_from_gnome))
end

return M
