-- Statusline bundled with nightfox.nvim. Called from nightfox/init.lua;
-- inactive if another statusline plugin already owns vim.o.statusline.

---@diagnostic disable: duplicate-set-field

local M = {}

local function statusline_plugin_active()
  local plugins = {
    "mini.statusline",
    "lualine",
    "feline",
    "galaxyline",
    "heirline",
    "windline",
    "staline",
    "statusline",
    "hardline",
    "express_line",
    "el",
    "neoline",
    "airline",
    "lightline",
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
  vim.api.nvim_set_hl(0, "SLFileNameParent", { fg = palette.blue.base, bold = true })
  vim.api.nvim_set_hl(0, "SLFileNameTail", { fg = spec.fg1, bold = true })
  vim.api.nvim_set_hl(0, "SLEncoding", { fg = spec.bg0, bg = palette.yellow.base })
  vim.api.nvim_set_hl(0, "SLFileType", { fg = spec.fg1, bg = spec.bg2 })
  vim.api.nvim_set_hl(0, "SLGitBranchText", { fg = spec.fg1 })
  vim.api.nvim_set_hl(0, "SLPosition", { fg = spec.fg1, bg = spec.bg0 })
  vim.api.nvim_set_hl(0, "SLInactiveText", { fg = spec.bg4 })
end

-- Call once from nightfox/init.lua with the resolved spec.
function M.apply(spec)
  setup_highlights(spec)

  if statusline_plugin_active() then
    return
  end

  -- Autocmds/caches set up once; vim.o.statusline is reassigned every call
  -- so toggling statusline=true/false via setup() takes effect immediately.
  if not _G._nightfox_statusline_loaded then
    _G._nightfox_statusline_loaded = true
    M._setup_once()
  end

  vim.o.statusline = "%{%v:lua.st_statusline()%}"
end

function M._setup_once()
  -- g:actual_curwin is the real focused window; the window being *drawn*
  -- (nvim_get_current_win()) differs from it during statusline redraws.
  local function is_focused_win()
    return vim.o.laststatus == 3 or vim.api.nvim_get_current_win() == tonumber(vim.g.actual_curwin or -1)
  end

  local function session_text()
    return vim.v.this_session ~= "" and " $" or ""
  end

  -- Filename keeps its own colors even when unfocused: parent dims to
  -- SLInactiveText, tail keeps SLFileNameTail (just not bold).
  local function filepath_text(fancy)
    local bufnr = vim.api.nvim_get_current_buf()
    local raw = vim.api.nvim_buf_get_name(bufnr)
    -- "%" is a statusline metacharacter; escape any literal ones.
    local name = raw == "" and "Untitled" or (raw:gsub("%%", "%%%%"))

    local parent, tail
    if raw:match("^%w+://") then
      -- fugitive://, guh://, etc. aren't real paths; fnamemodify(':p')
      -- would corrupt them, so show the whole thing as "tail".
      parent, tail = "", name
    else
      local help = vim.bo.buftype == "help"
      -- Directory buffers (dirvish, ...) end with "/"; fnamemodify(":~:.")
      -- collapses that to "" when the dir is exactly cwd, so strip it
      -- first -- a no-op for ordinary files, which never end in "/".
      local path = name:gsub("/$", "")
      local fname = vim.fn.fnamemodify(path, ":~:.")
      parent = help and "" or (fname:match("^(.*/)") or "")
      tail = vim.fn.fnamemodify(path, ":t")
    end

    local parent_hl, tail_hl, reset
    if fancy then
      parent_hl, tail_hl, reset = "%#SLFileNameParent#", "%#SLFileNameTail#", "%*"
    else
      -- No highlight opened, so no reset either -- "%*" would cancel the
      -- outer SLInactiveText wrap for the rest of the line.
      parent_hl, tail_hl, reset = "", "", ""
    end

    return ("%s %%<%s%s%s %s"):format(parent_hl, parent, tail_hl, tail, reset)
  end

  -- Plain "E: n W: n " summary, errors/warnings only.
  local function diagnostics_text()
    local counts = vim.diagnostic.count(0)
    local errors = counts[vim.diagnostic.severity.ERROR] or 0
    local warnings = counts[vim.diagnostic.severity.WARN] or 0
    if errors == 0 and warnings == 0 then
      return ""
    elseif warnings == 0 then
      return ("E: %d "):format(errors)
    elseif errors == 0 then
      return ("W: %d "):format(warnings)
    end
    return ("E: %d W: %d "):format(errors, warnings)
  end

  -- Fileformat/encoding badge, shown only if non-default.
  local function encoding_text()
    local parts = {}
    if vim.bo.fileformat ~= "unix" then
      table.insert(parts, vim.bo.fileformat == "dos" and "CRLF" or "CR")
    end
    local enc = vim.bo.fileencoding
    if enc ~= "" and enc ~= "utf-8" then
      table.insert(parts, enc)
    end
    if #parts == 0 then
      return ""
    end
    return " " .. table.concat(parts, " ") .. " "
  end

  -- Git branch: no subprocess spawning. Find .git via fs_stat, read HEAD
  -- directly, watch it with libuv so we only re-read on actual changes.
  local git_dir_cache = {} -- bufnr -> gitdir path, or false
  local branch_cache = {} -- gitdir -> branch (or short hash)
  local watchers = {} -- gitdir -> uv_fs_event handle

  local function find_git_dir(path)
    local dir = vim.fn.fnamemodify(path, ":p:h")
    while true do
      local git_path = dir .. "/.git"
      local stat = vim.uv.fs_stat(git_path)
      if stat and stat.type == "directory" then
        return git_path
      elseif stat and stat.type == "file" then
        -- Worktree/submodule: ".git" is a file with "gitdir: <path>".
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

  -- fugitive://<gitdir>//<sha>/<relpath>: same carve-out gitsigns.nvim
  -- uses to show git info for these despite their non-normal buftype.
  local function scheme_git_dir(path)
    local proto, gitdir = path:match("^(%a+)://(.-)//")
    if (proto == "fugitive" or proto == "gitsigns") and gitdir and gitdir ~= "" then
      return gitdir
    end
    return nil
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
    -- Watch the directory, not HEAD itself: git replaces HEAD via a
    -- lockfile rename, which breaks a watch on the file path directly.
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
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" then
      git_dir_cache[bufnr] = false
      return
    end

    local gitdir = scheme_git_dir(path)
    if not gitdir then
      -- Skip non-normal buffers (dirvish, quickfix, help, ...), same rule
      -- gitsigns/mini.git use.
      if vim.bo[bufnr].buftype ~= "" then
        git_dir_cache[bufnr] = false
        return
      end
      gitdir = find_git_dir(path)
    end

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

  -- U+F418 = nf-oct-git_branch, hardcoded so it shows without devicons.
  local branch_icon = "\u{f418}"

  local function branch_text()
    local bufnr = vim.api.nvim_get_current_buf()
    -- Live recheck: dirvish sets buftype from a FileType autocmd that runs
    -- *after* BufEnter, so the cache above can be stale.
    if vim.bo.buftype ~= "" and not scheme_git_dir(vim.api.nvim_buf_get_name(bufnr)) then
      return ""
    end
    local gitdir = git_dir_cache[bufnr]
    local branch = gitdir and branch_cache[gitdir]
    return (branch and branch ~= "") and (" " .. branch_icon .. " " .. branch .. " ") or ""
  end

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

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("NightfoxStatuslineLsp", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        vim.b[args.buf].lsp_client = client.name
      end
    end,
  })
  vim.api.nvim_create_autocmd("LspDetach", {
    group = "NightfoxStatuslineLsp",
    callback = function(args)
      vim.b[args.buf].lsp_client = nil
    end,
  })

  local function filetype_icon(fancy)
    if not devicons_ok then
      return ""
    end
    local path = vim.api.nvim_buf_get_name(0)
    local fname = vim.fn.fnamemodify(path, ":t")
    local ext = vim.fn.fnamemodify(path, ":e")
    local filetype = vim.bo.filetype

    local icon, color = devicons.get_icon_color(fname, ext:lower(), { default = true })
    if not icon then
      icon, color = devicons.get_icon_color("", filetype, { default = true })
    end
    if not icon then
      icon, color = devicons.get_icon_color("", filetype:lower(), { default = true })
    end
    if not icon then
      return ""
    end
    if not (fancy and color) then
      return icon .. " "
    end
    local hl = "SLFileIcon_" .. color:gsub("#", "")
    if not icon_hl_cache[hl] then
      vim.api.nvim_set_hl(0, hl, { fg = color })
      icon_hl_cache[hl] = true
    end
    return ("%%#%s#%s%%* "):format(hl, icon)
  end

  local function filetype_text()
    local filetype = vim.bo.filetype
    if filetype == "" then
      return ""
    end
    local lsp = vim.b.lsp_client
    return lsp and (" %s/%s "):format(filetype, lsp) or (" %s "):format(filetype)
  end

  -- Rebuilt from scratch every redraw so `fancy` can gate which highlight
  -- groups open at all. "%{%...%}" (not "%!") re-evaluates the result for
  -- further % items and runs in the drawn window's context, which is what
  -- makes g:actual_curwin meaningful in is_focused_win().
  function _G.st_statusline()
    local term = vim.bo.buftype == "terminal"
    local fancy = is_focused_win() and not term

    local left = table.concat({
      session_text(),
      filepath_text(fancy),
      "%h%w%m%r ",
      term and "%{v:lua.require('vim._core.util').term_exitcode()}" or "",
      "%=",
      "%-10.S",
      "%{ &busy > 0 ? '◐ ' : '' }",
      diagnostics_text(),
    })

    local branch = branch_text()
    local right = table.concat({
      fancy and branch ~= "" and "%#SLGitBranchText#" or "",
      branch,
      fancy and branch ~= "" and "%*" or "",
      fancy and "%#SLEncoding#" or "",
      encoding_text(),
      fancy and "%#SLFileType#" or "",
      filetype_icon(fancy),
      filetype_text(),
      fancy and "%#SLPosition#" or "",
      " %l:%c %P ",
    })

    if fancy then
      return left .. right
    end
    return "%#SLInactiveText#" .. left .. right .. "%*"
  end
end

return M
