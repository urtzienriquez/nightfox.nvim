-- Applies all highlight groups for a given spec
local M = {}

local function hi(name, opts)
  vim.api.nvim_set_hl(0, name, opts)
end

local function link(name, target)
  vim.api.nvim_set_hl(0, name, { link = target })
end

-- ============================================================================
-- M.apply — main highlight pass
-- ============================================================================

function M.apply(spec, config)
  local syn = spec.syntax
  local trans = config and config.transparent or false
  local bg1 = trans and "NONE" or spec.bg1

  -- --------------------------------------------------------------------------
  -- EDITOR › Core
  -- --------------------------------------------------------------------------

  hi("Normal", { fg = spec.fg1, bg = bg1 })
  hi("NormalNC", { fg = spec.fg1, bg = trans and "NONE" or spec.bg1 })
  hi("NormalFloat", { fg = spec.fg1, bg = spec.bg1 })
  hi("FloatBorder", { fg = spec.fg3 })
  hi("ColorColumn", { bg = spec.bg2 })
  hi("Conceal", { fg = spec.bg4 })
  hi("EndOfBuffer", { fg = spec.bg1 })
  hi("NonText", { fg = spec.bg4 })
  hi("Whitespace", { fg = spec.bg3 })
  link("SpecialKey", "NonText")

  -- --------------------------------------------------------------------------
  -- EDITOR › Cursor & current line
  -- --------------------------------------------------------------------------

  hi("Cursor", { fg = spec.bg1, bg = spec.fg1 })
  hi("CursorLine", { bg = spec.bg3 })
  hi("CursorLineNr", { fg = spec.diag.warn, bold = true })
  hi("CursorLineNrNC", { fg = spec.fg3, bold = true })
  hi("MsgArea", { fg = spec.fg3, bg = spec.bg1 })
  link("lCursor", "Cursor")
  link("CursorIM", "Cursor")
  link("CursorColumn", "CursorLine")

  -- --------------------------------------------------------------------------
  -- EDITOR › Gutter (line numbers, signs, folds)
  -- --------------------------------------------------------------------------

  hi("LineNr", { fg = spec.fg3 })
  hi("SignColumn", { fg = spec.fg3 })
  hi("FoldColumn", { fg = spec.fg3 })
  hi("Folded", { fg = spec.fg3, bg = spec.bg2 })

  -- --------------------------------------------------------------------------
  -- EDITOR › Windows & splits
  -- --------------------------------------------------------------------------

  hi("WinSeparator", { fg = spec.syntax.func })
  hi("WinBar", { fg = spec.fg3, bg = bg1, bold = true })
  hi("WinBarNC", { fg = spec.fg3, bg = bg1, bold = true })
  link("VertSplit", "WinSeparator")

  -- --------------------------------------------------------------------------
  -- EDITOR › Statusline & tabline
  -- --------------------------------------------------------------------------

  hi("StatusLine", { fg = spec.fg2, bg = spec.bg0 })
  hi("StatusLineNC", { fg = spec.fg3, bg = spec.bg0 })
  hi("TabLine", { fg = spec.fg2, bg = spec.bg2 })
  hi("TabLineFill", { bg = spec.bg0 })
  hi("TabLineSel", { fg = spec.bg1, bg = spec.fg3 })
  hi("Title", { fg = syn.func, bold = true })

  -- --------------------------------------------------------------------------
  -- EDITOR › Popup menu
  -- --------------------------------------------------------------------------

  hi("Pmenu", { bg = spec.bg2 })
  hi("PmenuSel", { bg = spec.sel1 })
  hi("PmenuSbar", { bg = spec.bg2 })
  hi("PmenuThumb", { bg = spec.bg3 })
  link("WildMenu", "Pmenu")

  -- --------------------------------------------------------------------------
  -- EDITOR › Selection & search
  -- --------------------------------------------------------------------------

  hi("Visual", { bg = spec.sel0 })
  hi("Search", { fg = spec.fg1, bg = spec.sel1 })
  hi("IncSearch", { fg = spec.bg1, bg = spec.diag.hint })
  hi("Substitute", { fg = spec.bg1, bg = spec.diag.error })
  hi("MatchParen", { fg = spec.diag.warn, bold = true })
  link("VisualNOS", "Visual")
  link("CurSearch", "IncSearch")

  -- --------------------------------------------------------------------------
  -- EDITOR › Messages & prompts
  -- --------------------------------------------------------------------------

  hi("ModeMsg", { fg = spec.diag.warn, bold = true })
  hi("MoreMsg", { fg = spec.diag.info, bold = true })
  hi("ErrorMsg", { fg = spec.diag.error })
  hi("WarningMsg", { fg = spec.diag.warn })
  hi("Directory", { fg = syn.func })
  link("Question", "MoreMsg")
  link("QuickFixLine", "CursorLine")

  -- --------------------------------------------------------------------------
  -- EDITOR › Spell
  -- --------------------------------------------------------------------------

  hi("SpellBad", { sp = spec.diag.error, undercurl = true })
  hi("SpellCap", { sp = spec.diag.warn, undercurl = true })
  hi("SpellLocal", { sp = spec.diag.info, undercurl = true })
  hi("SpellRare", { sp = spec.diag.info, undercurl = true })

  -- --------------------------------------------------------------------------
  -- EDITOR › Misc formatting
  -- --------------------------------------------------------------------------

  hi("Underlined", { underline = true })
  hi("Bold", { bold = true })
  hi("Italic", { italic = true })

  -- --------------------------------------------------------------------------
  -- EDITOR › Notification area (msg filetype)
  -- --------------------------------------------------------------------------

  hi("MsgNotificationArea", { fg = spec.fg3, bg = "NONE" })
  hi("MsgBorder", { fg = syn.func, bg = "NONE" })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "msg" },
    callback = function()
      local win = vim.api.nvim_get_current_win()
      vim.wo[win].winhighlight = "NormalFloat:MsgNotificationArea,FloatBorder:MsgBorder"
    end,
  })

  -- --------------------------------------------------------------------------
  -- SYNTAX › Base groups
  -- --------------------------------------------------------------------------

  -- Comments
  hi("Comment", { fg = syn.comment, italic = true })

  -- Constants
  hi("Constant", { fg = syn.const })
  hi("String", { fg = syn.string })
  hi("Number", { fg = syn.number })
  hi("Error", { fg = spec.diag.error })
  hi("Todo", { fg = spec.bg1, bg = spec.diag.info })
  link("Character", "String")
  link("Float", "Number")
  link("Boolean", "Constant")

  -- Identifiers & functions
  hi("Identifier", { fg = syn.ident })
  hi("Function", { fg = syn.func })

  -- Statements & control flow
  hi("Statement", { fg = syn.keyword })
  hi("Conditional", { fg = syn.conditional })
  hi("Operator", { fg = syn.operator })
  hi("Keyword", { fg = syn.keyword })
  link("Repeat", "Conditional")
  link("Label", "Conditional")
  link("Exception", "Keyword")

  -- Pre-processor
  hi("PreProc", { fg = syn.preproc })
  link("Include", "PreProc")
  link("Define", "PreProc")
  link("Macro", "PreProc")
  link("PreCondit", "PreProc")

  -- Types
  hi("Type", { fg = syn.type })
  link("StorageClass", "Type")
  link("Structure", "Type")
  link("Typedef", "Type")

  -- Special
  hi("Special", { fg = syn.ident })
  link("SpecialChar", "Special")
  link("Tag", "Special")
  link("Delimiter", "Special")
  link("SpecialComment", "Special")
  link("Debug", "Special")

  -- --------------------------------------------------------------------------
  -- SYNTAX › Citation & reference fixes (Pandoc / LaTeX / Markdown)
  -- --------------------------------------------------------------------------

  hi("pandocCiteKey", { fg = syn.keyword })
  hi("pandocCiteAnchor", { fg = syn.keyword })
  hi("pandocCiteLocator", { fg = syn.keyword })
  hi("pandocPCite", { fg = syn.keyword })
  hi("texRefZone", { fg = syn.keyword })
  hi("texStatement", { fg = syn.keyword })
  hi("texDelimiter", { fg = syn.keyword })
  hi("markdownCode", { fg = syn.keyword })
  hi("@markup.raw.markdown_inline", { fg = syn.builtin1 })
  hi("@string.escape.markdown_inline", { fg = syn.keyword })
  link("@markup.math.latex", "Function")
  link("@operator.latex", "Function")

  -- --------------------------------------------------------------------------
  -- DIFF › Buffer-level diff highlights
  -- --------------------------------------------------------------------------

  hi("DiffAdd", { bg = spec.diff.add })
  hi("DiffChange", { bg = spec.diff.change })
  hi("DiffDelete", { bg = spec.diff.delete })
  hi("DiffText", { bg = spec.diff.text })

  -- --------------------------------------------------------------------------
  -- DIFF › diff/patch filetype syntax
  -- --------------------------------------------------------------------------

  hi("diffAdded", { fg = spec.git.add })
  hi("diffRemoved", { fg = spec.git.removed })
  hi("diffChanged", { fg = spec.git.changed })
  hi("diffOldFile", { fg = spec.diag.warn })
  hi("diffNewFile", { fg = spec.diag.hint })
  hi("diffFile", { fg = spec.diag.info })
  hi("diffLine", { fg = syn.builtin2 })
  hi("diffIndexLine", { fg = syn.preproc })

  -- --------------------------------------------------------------------------
  -- DIAGNOSTICS
  -- --------------------------------------------------------------------------

  -- Base colors
  hi("DiagnosticError", { fg = spec.diag.error })
  hi("DiagnosticWarn", { fg = spec.diag.warn })
  hi("DiagnosticInfo", { fg = spec.diag.info })
  hi("DiagnosticHint", { fg = spec.diag.hint })
  hi("DiagnosticOk", { fg = spec.diag.ok })

  -- Sign column
  link("DiagnosticSignError", "DiagnosticError")
  link("DiagnosticSignWarn", "DiagnosticWarn")
  link("DiagnosticSignInfo", "DiagnosticInfo")
  link("DiagnosticSignHint", "DiagnosticHint")
  link("DiagnosticSignOk", "DiagnosticOk")

  -- Virtual text (tinted background)
  hi("DiagnosticVirtualTextError", { fg = spec.diag.error, bg = spec.diag_bg.error })
  hi("DiagnosticVirtualTextWarn", { fg = spec.diag.warn, bg = spec.diag_bg.warn })
  hi("DiagnosticVirtualTextInfo", { fg = spec.diag.info, bg = spec.diag_bg.info })
  hi("DiagnosticVirtualTextHint", { fg = spec.diag.hint, bg = spec.diag_bg.hint })
  hi("DiagnosticVirtualTextOk", { fg = spec.diag.ok, bg = spec.diag_bg.ok })

  -- Underlines
  hi("DiagnosticUnderlineError", { undercurl = true, sp = spec.diag.error })
  hi("DiagnosticUnderlineWarn", { undercurl = true, sp = spec.diag.warn })
  hi("DiagnosticUnderlineInfo", { undercurl = true, sp = spec.diag.info })
  hi("DiagnosticUnderlineHint", { undercurl = true, sp = spec.diag.hint })
  hi("DiagnosticUnderlineOk", { undercurl = true, sp = spec.diag.ok })

  -- --------------------------------------------------------------------------
  -- TREESITTER › Variables
  -- --------------------------------------------------------------------------

  link("@variable", "Identifier")
  link("@variable.builtin", "@property")
  -- link("@variable.parameter", "@property")
  hi("@variable.parameter", { fg = spec.palette.pblue.base })
  hi("@variable.member", { fg = syn.builtin1 })

  -- --------------------------------------------------------------------------
  -- TREESITTER › Constants
  -- --------------------------------------------------------------------------

  link("@constant", "Constant")
  hi("@constant.builtin", { fg = syn.builtin2 })
  link("@constant.macro", "Macro")

  -- --------------------------------------------------------------------------
  -- TREESITTER › Strings & characters
  -- --------------------------------------------------------------------------

  link("@string", "String")
  hi("@string.regexp", { fg = syn.regex })
  hi("@string.escape", { fg = syn.regex, bold = true })
  link("@string.special", "Special")
  hi("@string.special.url", { fg = syn.const, italic = true, underline = true })
  link("@character", "Character")
  link("@character.special", "SpecialChar")

  -- --------------------------------------------------------------------------
  -- TREESITTER › Numbers & booleans
  -- --------------------------------------------------------------------------

  link("@boolean", "Boolean")
  link("@number", "Number")
  link("@number.float", "Float")

  -- --------------------------------------------------------------------------
  -- TREESITTER › Types
  -- --------------------------------------------------------------------------

  link("@type", "Type")

  -- --------------------------------------------------------------------------
  -- TREESITTER › Functions & constructors
  -- --------------------------------------------------------------------------

  link("@function", "Function")
  hi("@function.builtin", { fg = syn.builtin0 })
  hi("@function.macro", { fg = syn.builtin0 })
  hi("@function.call.lua", { fg = syn.builtin0 })
  hi("@constructor", { fg = syn.operator })

  -- --------------------------------------------------------------------------
  -- TREESITTER › Keywords
  -- --------------------------------------------------------------------------

  link("@keyword", "Keyword")
  -- hi("@keyword.function", { fg = syn.keyword })
  link("@keyword.function", "Keyword")
  link("@keyword.operator", "Keyword")
  -- hi("@keyword.operator", { fg = syn.operator })
  hi("@keyword.return", { fg = syn.builtin0 })
  hi("@keyword.luadoc", { fg = spec.palette.magenta.bright })
  link("@keyword.return.lua", "Keyword")
  link("@keyword.import", "Include")
  link("@keyword.storage", "StorageClass")
  link("@keyword.repeat", "Keyword")
  link("@keyword.exception", "Exception")
  link("@keyword.conditional", "Conditional")

  -- --------------------------------------------------------------------------
  -- TREESITTER › Operators & punctuation
  -- --------------------------------------------------------------------------

  link("@operator", "Operator")
  hi("@punctuation.delimiter", { fg = syn.bracket })
  hi("@punctuation.bracket", { fg = syn.bracket })
  hi("@punctuation.special", { fg = syn.builtin1 })

  -- --------------------------------------------------------------------------
  -- TREESITTER › Modules, labels, attributes, properties
  -- --------------------------------------------------------------------------

  hi("@module", { fg = syn.builtin1 })
  hi("@module.python", { fg = syn.ident })
  link("@label", "Label")
  link("@attribute", "Constant")
  hi("@property", { fg = syn.field })

  -- --------------------------------------------------------------------------
  -- TREESITTER › Comments
  -- --------------------------------------------------------------------------

  link("@comment", "Comment")
  hi("@comment.error", { fg = spec.bg1, bg = spec.diag.error })
  hi("@comment.warning", { fg = spec.bg1, bg = spec.diag.warn })
  hi("@comment.todo", { fg = spec.bg1, bg = spec.diag.hint })
  hi("@comment.note", { fg = spec.bg1, bg = spec.diag.info })

  -- --------------------------------------------------------------------------
  -- TREESITTER › Tags (HTML / XML / JSX)
  -- --------------------------------------------------------------------------

  link("@tag", "Keyword")
  hi("@tag.attribute", { fg = syn.func, italic = true })
  hi("@tag.delimiter", { fg = syn.builtin1 })

  -- --------------------------------------------------------------------------
  -- TREESITTER › Markup (Markdown / LaTeX)
  -- --------------------------------------------------------------------------

  link("@markup.heading", "WarningMsg")
  hi("@markup.link.label.markdown_inline", { fg = syn.keyword, underline = false })
  hi("@markup.link.label.latex", { fg = syn.keyword })
  link("@markup.link.markdown_inline", "@markup.link.label.markdown_inline")

  -- --------------------------------------------------------------------------
  -- GIT › Signs
  -- --------------------------------------------------------------------------

  hi("GitSignsAdd", { fg = spec.git.add })
  hi("GitSignsChange", { fg = spec.git.changed })
  hi("GitSignsDelete", { fg = spec.git.removed })

  -- --------------------------------------------------------------------------
  -- fugitive
  -- --------------------------------------------------------------------------

  hi("fugitiveHash", { fg = syn.field })

  -- --------------------------------------------------------------------------
  -- PLUGINS › Telescope
  -- --------------------------------------------------------------------------

  hi("TelescopeBorder", { fg = spec.bg4 })
  hi("TelescopeSelectionCaret", { fg = spec.palette.orange.base })
  link("TelescopeSelection", "CursorLine")
  link("TelescopeMatching", "Search")

  -- --------------------------------------------------------------------------
  -- PLUGINS › fzf-lua
  -- --------------------------------------------------------------------------

  hi("FzfLuaNormal", { fg = spec.fg1, bg = spec.bg1 })
  hi("FzfLuaBorder", { fg = spec.fg3, bg = spec.bg1 })
  hi("FzfLuaTitle", { fg = spec.fg3, bg = spec.bg1, bold = true })
  link("FzfLuaPreviewNormal", "FzfLuaNormal")
  link("FzfLuaPreviewBorder", "FzfLuaBorder")
  link("FzfLuaPreviewTitle", "FzfLuaTitle")

  -- --------------------------------------------------------------------------
  -- PLUGINS › Snacks
  -- --------------------------------------------------------------------------

  hi("SnacksPickerTitle", { fg = spec.fg3, bg = spec.bg1, bold = true })
  link("SnacksTitle", "SnacksPickerTitle")

  -- --------------------------------------------------------------------------
  -- PLUGINS › nvim-cmp
  -- --------------------------------------------------------------------------

  hi("CmpDocumentation", { fg = spec.fg1, bg = spec.bg0 })
  hi("CmpDocumentationBorder", { fg = spec.sel0, bg = spec.bg0 })
  hi("CmpItemAbbr", { fg = spec.fg1 })
  hi("CmpItemAbbrMatch", { fg = syn.func })
  hi("CmpItemAbbrMatchFuzzy", { fg = syn.func })
  link("CmpItemKindDefault", "Identifier")
  link("CmpItemKindFunction", "Function")
  link("CmpItemKindMethod", "Function")
  link("CmpItemKindVariable", "Identifier")
  link("CmpItemKindConstant", "Constant")
  link("CmpItemKindClass", "Type")
  link("CmpItemKindStruct", "Type")
  link("CmpItemKindKeyword", "Keyword")
  link("CmpItemKindOperator", "Operator")
  link("CmpItemMenu", "Comment")

  -- --------------------------------------------------------------------------
  -- PLUGINS › blink.cmp
  -- --------------------------------------------------------------------------

  hi("BlinkCmpMenu", { bg = spec.bg1, fg = spec.fg1 })
  hi("BlinkCmpMenuBorder", { bg = spec.bg1, fg = spec.fg3 })
  hi("BlinkCmpMenuSelection", { bg = spec.sel1, fg = spec.fg1, bold = true })
  hi("BlinkCmpDocSeparator", { bg = spec.bg1, fg = spec.palette.blue.base })
  hi("BlinkCmpLabelMatch", { fg = spec.palette.blue.bright, bold = true })
  link("BlinkCmpDoc", "BlinkCmpMenu")
  link("BlinkCmpDocBorder", "BlinkCmpMenuBorder")
  link("BlinkCmpSignatureHelp", "BlinkCmpMenu")
  link("BlinkCmpSignatureHelpBorder", "BlinkCmpMenuBorder")

  -- --------------------------------------------------------------------------
  -- PLUGINS › which-key
  -- --------------------------------------------------------------------------

  link("WhichKey", "Identifier")
  link("WhichKeyGroup", "Function")
  link("WhichKeyDesc", "Keyword")
  link("WhichKeySeparator", "Comment")
  link("WhichKeyFloat", "NormalFloat")
  link("WhichKeyValue", "Comment")

  -- --------------------------------------------------------------------------
  -- RMD / Pandoc ref highlighting (matchadd — overrides treesitter bold spans)
  -- --------------------------------------------------------------------------

  hi("NightfoxRmdRef", { fg = syn.keyword })
  M.apply_rmd_refs(spec)

  -- --------------------------------------------------------------------------
  -- AUTOCMDS › CursorLineNr active / inactive
  -- --------------------------------------------------------------------------

  local group = vim.api.nvim_create_augroup("NightfoxCursorLineNr", { clear = true })
  vim.api.nvim_create_autocmd({ "WinLeave", "FocusLost" }, {
    group = group,
    callback = function()
      vim.wo.winhighlight = "CursorLineNr:CursorLineNrNC"
    end,
  })
  vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained", "BufEnter" }, {
    group = group,
    callback = function()
      vim.wo.winhighlight = ""
    end,
  })
end

-- ============================================================================
-- M.apply_terminal
-- ============================================================================

function M.apply_terminal(palette)
  local p = palette
  vim.g.terminal_color_0 = p.black.base
  vim.g.terminal_color_8 = p.black.bright
  vim.g.terminal_color_1 = p.red.base
  vim.g.terminal_color_9 = p.red.bright
  vim.g.terminal_color_2 = p.green.base
  vim.g.terminal_color_10 = p.green.bright
  vim.g.terminal_color_3 = p.yellow.base
  vim.g.terminal_color_11 = p.yellow.bright
  vim.g.terminal_color_4 = p.blue.base
  vim.g.terminal_color_12 = p.blue.bright
  vim.g.terminal_color_5 = p.magenta.base
  vim.g.terminal_color_13 = p.magenta.bright
  vim.g.terminal_color_6 = p.cyan.base
  vim.g.terminal_color_14 = p.cyan.bright
  vim.g.terminal_color_7 = p.white.base
  vim.g.terminal_color_15 = p.white.bright
end

-- ============================================================================
-- M.apply_dim_inactive
-- ============================================================================

function M.apply_dim_inactive(spec, factor)
  local C = require("nightfox.color")

  local function dim(hex)
    return C.blend_hex(hex, spec.bg1, factor)
  end

  local syn = spec.syntax
  local groups = {
    NormalNCDim = { fg = dim(spec.fg1), bg = C.blend_hex(spec.bg1, spec.bg0, 0.7) },
    CommentDim = { fg = dim(syn.comment), italic = true },
    ConstantDim = { fg = dim(syn.const) },
    StringDim = { fg = dim(syn.string) },
    NumberDim = { fg = dim(syn.number) },
    IdentifierDim = { fg = dim(syn.ident) },
    FunctionDim = { fg = dim(syn.func) },
    KeywordDim = { fg = dim(syn.keyword) },
    TypeDim = { fg = dim(syn.type) },
    StatementDim = { fg = dim(syn.keyword) },
    PreProcDim = { fg = dim(syn.preproc) },
    OperatorDim = { fg = dim(syn.operator) },
    SpecialDim = { fg = dim(syn.func) },
  }

  for name, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, name, opts)
  end

  local winhighlight = table.concat({
    "Normal:NormalNCDim",
    "CursorLineNr:CursorLineNrNC",
    "Comment:CommentDim",
    "Constant:ConstantDim",
    "String:StringDim",
    "Number:NumberDim",
    "Identifier:IdentifierDim",
    "Function:FunctionDim",
    "Keyword:KeywordDim",
    "Type:TypeDim",
    "Statement:StatementDim",
    "PreProc:PreProcDim",
    "Operator:OperatorDim",
    "Special:SpecialDim",
  }, ",")

  local group = vim.api.nvim_create_augroup("NightfoxDimInactive", { clear = true })
  vim.api.nvim_create_autocmd({ "WinLeave", "FocusLost" }, {
    group = group,
    callback = function()
      vim.wo.winhighlight = winhighlight
    end,
  })
  vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained", "BufEnter" }, {
    group = group,
    callback = function()
      vim.wo.winhighlight = ""
    end,
  })
end

-- ============================================================================
-- Fenced code block background (extmark-based)
-- ============================================================================

local NS = vim.api.nvim_create_namespace("nightfox_code_blocks")

local ENABLED_FT = {
  markdown = true,
  rmd = true,
  quarto = true,
  pandoc = true,
}

local function get_open_fence(line)
  local backticks = line:match("^%s*(`+)")
  if backticks and #backticks >= 3 then
    return "`", #backticks
  end
  local tildes = line:match("^%s*(~+)")
  if tildes and #tildes >= 3 then
    return "~", #tildes
  end
  return nil
end

local function is_close_fence(line, char, count)
  local found = line:match("^%s*(" .. vim.pesc(char) .. "+)%s*$")
  return found ~= nil and #found >= count
end

local function mark_row(bufnr, row)
  vim.api.nvim_buf_set_extmark(bufnr, NS, row, 0, {
    line_hl_group = "NightfoxCodeBlock",
    hl_eol = true,
    virt_text = { { string.rep(" ", 400), "NightfoxCodeBlock" } },
    virt_text_pos = "eol",
    virt_text_hide = true,
    priority = 90,
  })
end

local function redraw_code_blocks(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local ft = vim.bo[bufnr].filetype
  local base_ft = ft:match("^([^%.]+)") or ft
  if not ENABLED_FT[base_ft] and not ENABLED_FT[ft] then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local inside = false
  local fence_char, fence_count, fence_start

  for i, line in ipairs(lines) do
    if not inside then
      local char, count = get_open_fence(line)
      if char then
        inside = true
        fence_char = char
        fence_count = count
        fence_start = i - 1
      end
    elseif is_close_fence(line, fence_char, fence_count) then
      for row = fence_start, i - 1 do
        mark_row(bufnr, row)
      end
      inside = false
      fence_char = nil
      fence_count = nil
      fence_start = nil
    end
  end
end

function M.apply_code_blocks(spec)
  hi("NightfoxCodeBlock", { bg = spec.bg2 })
  hi("RCodeBlock", { bg = spec.bg2 })
  hi("CodeBlock", { bg = spec.bg2 })
  hi("mkdCode", { bg = spec.bg2 })
  hi("mkdCodeStart", { bg = spec.bg2 })
  hi("mkdCodeEnd", { bg = spec.bg2 })
  hi("pandocCodeBlock", { bg = spec.bg2 })
  hi("pandocCodeBlockDelim", { bg = spec.bg2 })
  hi("OtterBackground", { bg = spec.bg2 })
  vim.cmd("silent! hi! link rmdChunk NightfoxCodeBlock")

  local group = vim.api.nvim_create_augroup("NightfoxCodeBlocks", { clear = true })
  vim.api.nvim_create_autocmd(
    { "BufEnter", "BufWritePost", "TextChanged", "TextChangedI", "BufWinEnter", "WinEnter", "CursorMoved" },
    {
      group = group,
      callback = function(ev)
        vim.schedule(function()
          vim.schedule(function()
            redraw_code_blocks(ev.buf)
          end)
        end)
      end,
    }
  )

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      vim.schedule(function()
        redraw_code_blocks(bufnr)
      end)
    end
  end
end

-- ============================================================================
-- RMD / Pandoc ref highlighting (matchadd — overrides treesitter bold spans)
-- ============================================================================

local REF_PATTERNS = {
  [[@ref([^)]*)]], -- \@ref(tab:something) — the \ is eaten by the parser
  [[\\ref{[^}]*}]], -- \ref{appendix1}
}

local REF_FT = {
  markdown = true,
  rmd = true,
  quarto = true,
  pandoc = true,
}

function M.apply_rmd_refs(spec)
  local group = vim.api.nvim_create_augroup("NightfoxRmdRefs", { clear = true })

  local function repaint(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    local ft = vim.bo[bufnr].filetype
    local base_ft = ft:match("^([^%.]+)") or ft
    if not REF_FT[base_ft] and not REF_FT[ft] then
      return
    end

    for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
      -- clear old matches for this group in this window
      for _, match in ipairs(vim.fn.getmatches(winid)) do
        if match.group == "NightfoxRmdRef" then
          vim.fn.matchdelete(match.id, winid)
        end
      end
      -- add fresh matches
      for _, pat in ipairs(REF_PATTERNS) do
        vim.fn.matchadd("NightfoxRmdRef", pat, 20, -1, { window = winid })
      end
    end
  end

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "FileType", "ColorScheme" }, {
    group = group,
    callback = function(ev)
      vim.schedule(function()
        vim.schedule(function()
          repaint(ev.buf)
        end)
      end)
    end,
  })

  -- paint any already-loaded buffers immediately
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      vim.schedule(function()
        vim.schedule(function()
          repaint(bufnr)
        end)
      end)
    end
  end
end

return M
