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
		vim.notify(
			"nightfox-minimal: unknown theme '" .. name .. "'. Use 'nightfox' or 'dayfox'.",
			vim.log.levels.ERROR
		)
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
end

return M
