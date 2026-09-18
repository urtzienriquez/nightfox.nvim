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
    "mini.statusline",
    "lualine", -- nvim-lualine/lualine.nvim
    "feline", -- feline-nvim/feline.nvim
    "galaxyline", -- glepnir/galaxyline.nvim
    "heirline", -- rebelot/heirline.nvim
    "windline", -- windwp/windline.nvim
    "staline", -- tamton-aquib/staline.nvim
    "statusline", -- generic name some configs use
    "hardline", -- ojroques/nvim-hardline
    "express_line", -- tjdevries/express_line.nvim
    "el", -- tjdevries/express_line.nvim (alternate)
    "neoline", -- adelarsq/neoline.vim
    "airline", -- vim-airline (loaded via VimL but sometimes has Lua shim)
    "lightline", -- itchyny/lightline.vim (same)
  }
  for _, name in ipairs(plugins) do
    if package.loaded[name] then
      return true
    end
  end
  return false
end

local function setup_highlights(spec)
  local palette = spec.palette
  -- vim.api.nvim_set_hl(0, "SLFileName", { fg = palette.blue.base })
  vim.api.nvim_set_hl(0, "SLGitBranch", { fg = palette.blue.base })
  vim.api.nvim_set_hl(0, "SLDiagError", { fg = palette.red.base })
  vim.api.nvim_set_hl(0, "SLDiagWarn", { fg = palette.yellow.base })
  vim.api.nvim_set_hl(0, "SLDiagInfo", { fg = palette.cyan.base })
  vim.api.nvim_set_hl(0, "SLDiagHint", { fg = palette.green.base })
  vim.api.nvim_set_hl(0, "SLFileType", { bold = true })
  vim.api.nvim_set_hl(0, "StatusLineMinimal", { bg = spec.bg1, fg = spec.bg1 })
  -- vim.api.nvim_set_hl(0, "StatusLine", { bg = spec.bg0, fg = spec.fg3 })
  -- vim.api.nvim_set_hl(0, "StatusLineNC", { bg = spec.bg2, fg = spec.fg3 })
  -- vim.api.nvim_set_hl(0, "SLMacro", { fg = palette.cyan.base })
  vim.api.nvim_set_hl(0, "SLMode", { fg = spec.bg0, bg = palette.blue.base, bold = true })
end

-- Call this once from nightfox/init.lua, passing the resolved spec.
function M.apply(spec)
  -- Always refresh highlight groups (colorscheme may have reloaded)
  setup_highlights(spec)

  -- Do not overwrite vim.o.statusline if a plugin already owns it
  if statusline_plugin_active() then
    return
  end

  -- Guard against double-initialisation across successive :colorscheme calls
  if _G._nightfox_statusline_loaded then
    return
  end
  _G._nightfox_statusline_loaded = true

  -- --------------------------
  -- Width-based truncation
  -- --------------------------
  -- Mirrors mini.statusline's MiniStatusline.is_truncated(): while a
  -- statusline %{} expression is evaluated, Neovim temporarily makes the
  -- window/buffer it is drawn for the "current" one (see :h stl-%{), so a
  -- plain nvim_win_get_width(0)/nvim_get_current_buf() already refers to
  -- the right window/buffer without any extra bookkeeping.
  local function is_truncated(trunc_width)
    local w = vim.o.laststatus == 3 and vim.o.columns or vim.api.nvim_win_get_width(0)
    return w < trunc_width
  end

  -- --------------------------
  -- Mode
  -- --------------------------
  -- Show whatever vim.fn.mode() emits directly ("n", "i", "v", "V", ...),
  -- no lookup table translating it into a name.
  function _G.st_mode()
    return "  " .. vim.fn.mode() .. " "
  end

  -- --------------------------
  -- Focus detection
  -- --------------------------
  -- g:actual_curwin is set natively by Neovim for exactly this purpose (see
  -- :h g:actual_curwin): it holds the window-ID of the *real* current
  -- window, distinct from the one currently being drawn.
  local function is_focused_win()
    return vim.o.laststatus == 3 or vim.api.nvim_get_current_win() == tonumber(vim.g.actual_curwin or -1)
  end

  -- --------------------------
  -- File path
  -- --------------------------
  -- Mirrors mini.statusline's section_filename(): plain tail for terminal
  -- buffers, short form (tail) when truncated, full path otherwise. Unlike
  -- mini we tilde-collapse $HOME in the full form, and %m%r (appended in
  -- the statusline string itself) cover the modified/readonly flags.
  function _G.st_filepath()
    if vim.bo.buftype == "terminal" then
      return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
    end

    local path = vim.api.nvim_buf_get_name(0)
    if path == "" then
      return "[No Name]"
    end
    if is_truncated(140) then
      return vim.fn.fnamemodify(path, ":t")
    end
    return vim.fn.fnamemodify(path, ":p:~")
  end

  -- Unfocused window: just the filename, nothing else.
  function _G.st_filepath_minimal()
    local path = vim.api.nvim_buf_get_name(0)
    if path == "" then
      return "[No Name]"
    end
    return vim.fn.fnamemodify(path, ":t")
  end

  -- --------------------------
  -- Macro recording
  -- --------------------------
  -- function _G.st_macro()
  --   local reg = vim.fn.reg_recording()
  --   return reg ~= "" and ("  recording @" .. reg .. " ") or ""
  -- end

  -- --------------------------
  -- Git branch
  -- --------------------------
  -- No subprocess spawning at all: find the repo's .git dir with plain
  -- fs_stat calls, read HEAD directly (same file gitsigns/mini.git read),
  -- and watch it with libuv so we only re-read on an actual branch change
  -- instead of on every redraw.
  local git_dir_cache = {} -- bufnr -> gitdir path, or false if none
  local branch_cache = {} -- gitdir -> branch (or short hash) string
  local watchers = {} -- gitdir -> uv_fs_event handle

  local function find_git_dir(path)
    local dir = vim.fn.fnamemodify(path, ":p:h")
    while true do
      local git_path = dir .. "/.git"
      local stat = vim.uv.fs_stat(git_path)
      if stat and stat.type == "directory" then
        return git_path
      elseif stat and stat.type == "file" then
        -- Worktree/submodule: ".git" is a file containing "gitdir: <path>".
        local f = io.open(git_path, "r")
        local gitdir
        if f then
          local content = f:read("*l")
          f:close()
          gitdir = content and content:match("^gitdir:%s*(.+)$")
        end
        if not gitdir then
          return nil
        end
        if not gitdir:match("^/") then
          gitdir = dir .. "/" .. gitdir
        end
        return (vim.fn.fnamemodify(gitdir, ":p"):gsub("/$", ""))
      end
      local parent = vim.fn.fnamemodify(dir, ":h")
      if parent == dir then
        return nil
      end
      dir = parent
    end
  end

  local function read_branch(gitdir)
    local f = io.open(gitdir .. "/HEAD", "r")
    if not f then
      return ""
    end
    local content = f:read("*l")
    f:close()
    if not content then
      return ""
    end
    return content:match("^ref:%s*refs/heads/(.+)$") or content:sub(1, 7)
  end

  local function watch_branch(gitdir)
    if watchers[gitdir] then
      return
    end
    local handle = vim.uv.new_fs_event()
    if not handle then
      return
    end
    watchers[gitdir] = handle
    -- Watch the *directory*, not the HEAD file itself: git updates HEAD by
    -- writing a lockfile and renaming it over HEAD, which replaces the
    -- inode. A watch on the file path stops firing after that first rename;
    -- watching the directory (and filtering by filename) survives it.
    handle:start(
      gitdir,
      {},
      vim.schedule_wrap(function(err, filename)
        if err or (filename ~= nil and filename ~= "HEAD") then
          return
        end
        branch_cache[gitdir] = read_branch(gitdir)
        vim.cmd("redrawstatus")
      end)
    )
  end

  local function refresh_git_for_buf(bufnr)
    -- Same rule gitsigns/mini.git use to decide whether to attach at all:
    -- skip any non-normal buffer (fugitive's object buffers are
    -- buftype=nowrite, dirvish listings are buftype=nofile, quickfix/help/
    -- terminal are their own types, etc.) rather than naming any of them.
    -- That's also why mini.statusline itself shows no git info there: the
    -- buffer-local var it reads is simply never set for such buffers.
    if vim.bo[bufnr].buftype ~= "" then
      git_dir_cache[bufnr] = false
      return
    end
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" then
      git_dir_cache[bufnr] = false
      return
    end
    local gitdir = find_git_dir(path)
    git_dir_cache[bufnr] = gitdir or false
    if gitdir then
      if branch_cache[gitdir] == nil then
        branch_cache[gitdir] = read_branch(gitdir)
      end
      watch_branch(gitdir)
    end
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("NightfoxStatuslineGit", { clear = true }),
    callback = function(a)
      refresh_git_for_buf(a.buf)
    end,
  })
  refresh_git_for_buf(vim.api.nvim_get_current_buf())

  -- Hardcoded (not looked up via devicons) so it always shows, even
  -- without an icon-font plugin installed. U+F418 = nf-oct-git_branch.
  local branch_icon = "\u{f418}"

  function _G.st_branch()
    -- Re-check buftype here too (not just in refresh_git_for_buf's cache):
    -- plugins like dirvish set buftype from a FileType autocmd, which runs
    -- *after* BufEnter, so a buffer can still look "normal" (buftype=="")
    -- at the moment we cache it on BufEnter, and only become nofile/nowrite
    -- afterwards. Checking live here (cheap: one option read) is what
    -- actually matches mini.statusline's effective behavior, since it always
    -- reads current buffer-local state, never a BufEnter-time snapshot.
    if is_truncated(75) or vim.bo.buftype ~= "" then
      return ""
    end
    local gitdir = git_dir_cache[vim.api.nvim_get_current_buf()]
    local branch = gitdir and branch_cache[gitdir]
    return (branch and branch ~= "") and (" " .. branch_icon .. " " .. branch .. " ") or ""
  end

  -- --------------------------
  -- Filetype + devicons icon
  -- --------------------------
  -- Resolved once (not on every redraw); icon_hl_cache holds the per-color
  -- highlight groups devicons hands back, also created lazily.
  local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
  local icon_hl_cache = {}

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("NightfoxStatuslineHL", { clear = true }),
    callback = function()
      icon_hl_cache = {}
    end,
  })
  vim.api.nvim_create_autocmd("OptionSet", {
    pattern = "background",
    callback = function()
      icon_hl_cache = {}
    end,
  })

  function _G.st_filetype_text()
    local filetype = vim.bo.filetype
    if filetype == "" then
      return ""
    end
    if not devicons_ok then
      return filetype
    end

    local path = vim.api.nvim_buf_get_name(0)
    local fname = vim.fn.fnamemodify(path, ":t")
    local ext = vim.fn.fnamemodify(path, ":e")

    local icon, color = devicons.get_icon_color(fname, ext:lower(), { default = true })
    if not icon then
      icon, color = devicons.get_icon_color("", filetype, { default = true })
    end
    if not icon then
      icon, color = devicons.get_icon_color("", filetype:lower(), { default = true })
    end

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
  function _G.st_err()
    if is_truncated(75) then
      return ""
    end
    local c = vim.diagnostic.count(0)[vim.diagnostic.severity.ERROR] or 0
    return c > 0 and ("E" .. c .. " ") or ""
  end
  function _G.st_warn()
    if is_truncated(75) then
      return ""
    end
    local c = vim.diagnostic.count(0)[vim.diagnostic.severity.WARN] or 0
    return c > 0 and ("W" .. c .. " ") or ""
  end
  function _G.st_info()
    if is_truncated(75) then
      return ""
    end
    local c = vim.diagnostic.count(0)[vim.diagnostic.severity.INFO] or 0
    return c > 0 and ("I" .. c .. " ") or ""
  end
  function _G.st_hint()
    if is_truncated(75) then
      return ""
    end
    local c = vim.diagnostic.count(0)[vim.diagnostic.severity.HINT] or 0
    return c > 0 and ("H" .. c .. " ") or ""
  end

  -- --------------------------
  -- Position
  -- --------------------------
  function _G.st_position()
    local line, total = vim.fn.line("."), vim.fn.line("$")
    if line == 1 then
      return "Top"
    elseif line == total then
      return "Bot"
    else
      return ("%2d%%"):format(math.floor(line / total * 100))
    end
  end

  -- --------------------------
  -- Autocommands
  -- --------------------------
  local aug = vim.api.nvim_create_augroup("NightfoxStatusline", { clear = true })

  vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
    group = aug,
    callback = function()
      vim.cmd("redrawstatus")
    end,
  })

  -- -- Minimal statusline for oil / empty buffers
  -- vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufModifiedSet" }, {
  --   group = aug,
  --   callback = function()
  --     local is_oil = vim.bo.filetype == "oil"
  --     local empty = vim.api.nvim_buf_get_name(0) == "" and vim.bo.buftype == "" and not vim.bo.modified
  --     vim.wo.statusline = (is_oil or empty) and "%#StatusLineMinimal# " or ""
  --   end,
  -- })

  -- --------------------------
  -- Global statusline string
  -- --------------------------
  -- "%{%...%}" (NOT "%!") re-evaluates the returned string for further %
  -- items, same as mini.statusline. This matters: a top-level "%!"
  -- expression runs in the context of the *actual* current window/buffer,
  -- while "%{}" (including "%{%...%}") runs in the context of the window
  -- the statusline is being drawn for (:h stl-%{, :h stl-%!) -- which is
  -- what g:actual_curwin needs to be meaningful below.
  -- %m%r are native flags (modified/readonly), same as mini.statusline's
  -- section_filename() uses them.
  local full_statusline = table.concat({
    "%#SLMode#%{v:lua.st_mode()}%* ",
    "%#SLGitBranch#%{v:lua.st_branch()}%*",
    "%#SLDiagError#%{v:lua.st_err()}%*",
    "%#SLDiagWarn#%{v:lua.st_warn()}%*",
    "%#SLDiagInfo#%{v:lua.st_info()}%*",
    "%#SLDiagHint#%{v:lua.st_hint()}%*",
    "%#SLFileName#%{v:lua.st_filepath()}%m%r%*",
    -- "%#SLMacro#%{v:lua.st_macro()}%*",
    "%=",
    "%{%v:lua.st_filetype_text()%} ",
    "%4{v:lua.st_position()} ",
    "%#SLMode# %l:%c %*",
  })
  local minimal_statusline = "%#SLFileName# %{v:lua.st_filepath_minimal()}%m%r%*"

  function _G.st_statusline()
    if is_focused_win() then
      return full_statusline
    end
    return minimal_statusline
  end

  vim.o.statusline = "%{%v:lua.st_statusline()%}"
end

return M
