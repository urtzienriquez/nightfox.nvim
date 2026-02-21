-- Statusline bundled with nightfox.nvim
-- Called from nightfox/init.lua; only activates when no other statusline
-- plugin has already set vim.o.statusline to something non-empty.

---@diagnostic disable: duplicate-set-field

local M = {}

-- Detect whether a third-party statusline plugin is active.
-- Relies only on package.loaded to avoid false positives from Neovim's own
-- default statusline value, which can be non-empty in some contexts.
local function statusline_plugin_active()
	local plugins = {
		"lualine",        -- nvim-lualine/lualine.nvim
		"feline",         -- feline-nvim/feline.nvim
		"galaxyline",     -- glepnir/galaxyline.nvim
		"heirline",       -- rebelot/heirline.nvim
		"windline",       -- windwp/windline.nvim
		"staline",        -- tamton-aquib/staline.nvim
		"statusline",     -- generic name some configs use
		"hardline",       -- ojroques/nvim-hardline
		"express_line",   -- tjdevries/express_line.nvim
		"el",             -- tjdevries/express_line.nvim (alternate)
		"neoline",        -- adelarsq/neoline.vim
		"airline",        -- vim-airline (loaded via VimL but sometimes has Lua shim)
		"lightline",      -- itchyny/lightline.vim (same)
	}
	for _, name in ipairs(plugins) do
		if package.loaded[name] then return true end
	end
	return false
end

local function setup_highlights(spec)
	local palette = spec.palette
	vim.api.nvim_set_hl(0, "SLFileName",      { fg = palette.blue.base })
	vim.api.nvim_set_hl(0, "SLGitAdd",        { fg = palette.green.base })
	vim.api.nvim_set_hl(0, "SLGitDelete",     { fg = palette.red.base })
	vim.api.nvim_set_hl(0, "SLGitBranch",     { fg = palette.magenta.base })
	vim.api.nvim_set_hl(0, "SLDiagError",     { fg = palette.red.base })
	vim.api.nvim_set_hl(0, "SLDiagWarn",      { fg = palette.yellow.base })
	vim.api.nvim_set_hl(0, "SLDiagInfo",      { fg = palette.blue.base })
	vim.api.nvim_set_hl(0, "SLDiagHint",      { fg = palette.cyan.base })
	vim.api.nvim_set_hl(0, "SLFileType",      { bold = true })
	vim.api.nvim_set_hl(0, "StatusLineMinimal",{ bg = spec.bg1, fg = spec.bg1 })
	vim.api.nvim_set_hl(0, "StatusLine",      { bg = spec.bg0, fg = spec.fg3 })
	vim.api.nvim_set_hl(0, "StatusLineNC",    { bg = spec.bg0, fg = spec.fg3 })
	vim.api.nvim_set_hl(0, "SLMacro",         { fg = palette.green.base })
	vim.api.nvim_set_hl(0, "SLMode",          { fg = spec.bg0, bg = palette.blue.base, bold = true })
end

-- Call this once from nightfox/init.lua, passing the resolved spec.
function M.apply(spec)
	-- Always refresh highlight groups (colorscheme may have reloaded)
	setup_highlights(spec)

	-- Do not overwrite vim.o.statusline if a plugin already owns it
	if statusline_plugin_active() then return end

	-- Guard against double-initialisation across successive :colorscheme calls
	if _G._nightfox_statusline_loaded then return end
	_G._nightfox_statusline_loaded = true

	-- --------------------------
	-- Icon highlight cache
	-- --------------------------
	local icon_hl_cache = {}

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("NightfoxStatuslineHL", { clear = true }),
		callback = function() icon_hl_cache = {} end,
	})
	vim.api.nvim_create_autocmd("OptionSet", {
		pattern = "background",
		callback = function() icon_hl_cache = {} end,
	})

	-- --------------------------
	-- Mode
	-- --------------------------
	local block  = vim.api.nvim_replace_termcodes("<C-v>", true, false, true)
	local sblock = vim.api.nvim_replace_termcodes("<C-s>", true, false, true)

	local mode_map = {
		["n"]    = " NORMAL",  ["no"]  = " O-PEND",
		["v"]    = " VISUAL",  ["V"]   = " V-LINE",  [block]  = " V-BLOCK",
		["s"]    = " SELECT",  ["S"]   = " S-LINE",  [sblock] = " S-BLOCK",
		["i"]    = " INSERT",  ["ic"]  = " INSERT",
		["R"]    = " REPLACE", ["Rv"]  = " V-REPL",
		["c"]    = " COMMAND", ["t"]   = " TERM",    ["nt"]   = " N-TERM",
	}

	function _G.st_mode()
		return " " .. (mode_map[vim.fn.mode()] or vim.fn.mode()) .. " "
	end

	-- --------------------------
	-- Macro recording
	-- --------------------------
	function _G.st_macro()
		local reg = vim.fn.reg_recording()
		return reg ~= "" and ("  recording @" .. reg .. " ") or ""
	end

	-- --------------------------
	-- Async git status
	-- --------------------------
	local git_cache     = {}
	local pending       = {}
	local timers        = {}
	local root_cache    = {}

	local function get_git_root(bufnr)
		if root_cache[bufnr] then return root_cache[bufnr] end
		local path = vim.api.nvim_buf_get_name(bufnr)
		if path == "" then return nil end
		local dir = vim.fn.fnamemodify(path, ":p:h")
		local h = io.popen(("git -C %s rev-parse --show-toplevel 2>/dev/null"):format(
			vim.fn.shellescape(dir)))
		if not h then return nil end
		local root = h:read("*l"); h:close()
		root_cache[bufnr] = (root and root ~= "") and root or nil
		return root_cache[bufnr]
	end

	local function update_git_async(bufnr)
		bufnr = bufnr or vim.api.nvim_get_current_buf()
		if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then return end
		if pending[bufnr] then return end
		pending[bufnr] = true

		local root = get_git_root(bufnr)
		if not root then
			git_cache[bufnr] = { branch = "", added = 0, removed = 0 }
			pending[bufnr] = nil
			return
		end

		local cmd = ("cd %s 2>/dev/null && { git rev-parse --abbrev-ref HEAD 2>/dev/null; echo '---'; "
			.. "git diff --numstat HEAD 2>/dev/null; echo '---'; git status --porcelain 2>/dev/null; }")
			:format(vim.fn.shellescape(root))

		vim.fn.jobstart(cmd, {
			stdout_buffered = true,
			on_stdout = function(_, data)
				if not data or not vim.api.nvim_buf_is_valid(bufnr) then
					pending[bufnr] = nil; return
				end
				local parts = vim.split(table.concat(data, "\n"), "---", { plain = true })
				local branch = (parts[1] or ""):match("^%s*(.-)%s*$")
				local added, removed = 0, 0
				if parts[2] then
					for line in parts[2]:gmatch("[^\r\n]+") do
						local a, d = line:match("^(%d+)%s+(%d+)")
						if a then added = added + tonumber(a); removed = removed + tonumber(d) end
					end
				end
				if not (parts[3] and parts[3]:match("%S")) then added = 0; removed = 0 end
				git_cache[bufnr] = { branch = branch, added = added, removed = removed }
				pending[bufnr] = nil
				vim.schedule(function() vim.cmd("redrawstatus") end)
			end,
			on_exit = function() pending[bufnr] = nil end,
		})
	end

	local function update_debounced(bufnr, delay)
		delay = delay or 100
		if timers[bufnr] then timers[bufnr]:stop() end
		timers[bufnr] = vim.defer_fn(function()
			update_git_async(bufnr); timers[bufnr] = nil
		end, delay)
	end

	function _G.st_branch()
		local g = git_cache[vim.api.nvim_get_current_buf()]
		return (g and g.branch ~= "") and (" " .. g.branch .. " ") or ""
	end
	function _G.st_added()
		local g = git_cache[vim.api.nvim_get_current_buf()]
		return (g and g.added > 0) and ("+" .. g.added .. " ") or ""
	end
	function _G.st_removed()
		local g = git_cache[vim.api.nvim_get_current_buf()]
		return (g and g.removed > 0) and ("-" .. g.removed .. "  ") or ""
	end

	-- --------------------------
	-- Filetype + devicons
	-- --------------------------
	function _G.st_filetype_text()
		local filetype = vim.bo.filetype
		if filetype == "" then return "" end

		local ok, devicons = pcall(require, "nvim-web-devicons")
		if not ok then return filetype end

		local path = vim.api.nvim_buf_get_name(0)
		local fname = vim.fn.fnamemodify(path, ":t")
		local ext   = vim.fn.fnamemodify(path, ":e")

		local icon, color = devicons.get_icon_color(fname, ext:lower(), { default = true })
		if not icon then icon, color = devicons.get_icon_color("", filetype, { default = true }) end
		if not icon then icon, color = devicons.get_icon_color("", filetype:lower(), { default = true }) end

		if icon and color then
			local hl = "SLFileIcon_" .. color:gsub("#", "")
			if not icon_hl_cache[hl] then
				vim.api.nvim_set_hl(0, hl, { fg = color })
				icon_hl_cache[hl] = true
			end
			return ("%%#%s#%s %%#SLFileType#%s%%*"):format(hl, icon, filetype)
		end
		return filetype
	end

	-- --------------------------
	-- Diagnostics
	-- --------------------------
	local sev = vim.diagnostic.severity
	local function dc(s) return #vim.diagnostic.get(0, { severity = s }) end

	function _G.st_err()  local c = dc(sev.ERROR); return c > 0 and (" "  .. c .. " ") or "" end
	function _G.st_warn() local c = dc(sev.WARN);  return c > 0 and (" "  .. c .. " ") or "" end
	function _G.st_info() local c = dc(sev.INFO);  return c > 0 and ("󰋽 " .. c .. " ") or "" end
	function _G.st_hint() local c = dc(sev.HINT);  return c > 0 and (" "  .. c .. " ") or "" end

	-- --------------------------
	-- Position
	-- --------------------------
	function _G.st_position()
		local line, total = vim.fn.line("."), vim.fn.line("$")
		if line == 1 then return "Top"
		elseif line == total then return "Bot"
		else return ("%2d%%"):format(math.floor(line / total * 100)) end
	end

	-- --------------------------
	-- Autocommands
	-- --------------------------
	local aug = vim.api.nvim_create_augroup("NightfoxStatusline", { clear = true })

	vim.api.nvim_create_autocmd("BufEnter",     { group = aug, callback = function(a) update_debounced(a.buf, 100) end })
	vim.api.nvim_create_autocmd("BufWritePost", { group = aug, callback = function(a) update_debounced(a.buf, 0)   end })
	vim.api.nvim_create_autocmd("FocusGained",  { group = aug, callback = function()
		local b = vim.api.nvim_get_current_buf(); root_cache[b] = nil; update_debounced(b, 0)
	end })
	vim.api.nvim_create_autocmd("User", { group = aug, pattern = "FugitiveChanged", callback = function()
		root_cache = {}
		for b in pairs(git_cache) do update_debounced(b, 0) end
	end })
	vim.api.nvim_create_autocmd("ShellCmdPost", { group = aug, callback = function()
		local b = vim.api.nvim_get_current_buf(); root_cache[b] = nil; update_debounced(b, 0)
	end })
	vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
		group = aug, callback = function() vim.cmd("redrawstatus") end,
	})

	-- Minimal statusline for oil / empty buffers
	vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufModifiedSet" }, {
		group = aug,
		callback = function()
			local is_oil = vim.bo.filetype == "oil"
			local empty  = vim.api.nvim_buf_get_name(0) == "" and vim.bo.buftype == "" and not vim.bo.modified
			vim.wo.statusline = (is_oil or empty) and "%#StatusLineMinimal# " or ""
		end,
	})

	vim.api.nvim_create_user_command("GitStatusRefresh", function()
		update_debounced(vim.api.nvim_get_current_buf(), 0)
		vim.notify("Git status refreshed", vim.log.levels.INFO)
	end, {})

	-- --------------------------
	-- Global statusline string
	-- --------------------------
	vim.o.laststatus = 3
	vim.o.statusline = table.concat({
		"%#SLMode#%{v:lua.st_mode()}%* ",
		"%#SLFileName#%t %m%* ",
		"%#SLGitBranch#%{v:lua.st_branch()}%*",
		"%#SLGitAdd#%{v:lua.st_added()}%*",
		"%#SLGitDelete#%{v:lua.st_removed()}%*",
		"%#SLDiagError#%{v:lua.st_err()}%*",
		"%#SLDiagWarn#%{v:lua.st_warn()}%*",
		"%#SLDiagInfo#%{v:lua.st_info()}%*",
		"%#SLDiagHint#%{v:lua.st_hint()}%*",
		"%#SLMacro#%{v:lua.st_macro()}%*",
		"%=",
		"%{%v:lua.st_filetype_text()%} ",
		"%4{v:lua.st_position()} ",
		"%5l:%-5c ",
	})
end

return M
