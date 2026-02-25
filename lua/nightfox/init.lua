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

return M
