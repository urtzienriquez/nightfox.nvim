-- Applies all highlight groups for a given spec
local M = {}

local function hi(name, opts)
	vim.api.nvim_set_hl(0, name, opts)
end

local function link(name, target)
	vim.api.nvim_set_hl(0, name, { link = target })
end

function M.apply(spec, config)
	local syn = spec.syntax
	local trans = config and config.transparent or false
	local bg1 = trans and "NONE" or spec.bg1

	-- Editor
	hi("Normal", { fg = spec.fg1, bg = bg1 })
	hi("NormalNC", { fg = spec.fg1, bg = trans and "NONE" or spec.bg1 })
	hi("NormalFloat", { fg = spec.fg1, bg = spec.bg1 })
	hi("FloatBorder", { fg = spec.fg3 })
	hi("ColorColumn", { bg = spec.bg2 })
	hi("Conceal", { fg = spec.bg4 })
	hi("Cursor", { fg = spec.bg1, bg = spec.fg1 })
	hi("MsgArea", { fg = spec.fg3, bg = spec.bg1 })
	link("lCursor", "Cursor")
	link("CursorIM", "Cursor")
	hi("CursorLine", { bg = spec.bg3 })
	link("CursorColumn", "CursorLine")
	hi("CursorLineNr", { fg = spec.diag.warn, bold = true })
	hi("Directory", { fg = syn.func })
	hi("DiffAdd", { bg = spec.diff.add })
	hi("DiffChange", { bg = spec.diff.change })
	hi("DiffDelete", { bg = spec.diff.delete })
	hi("DiffText", { bg = spec.diff.text })
	hi("EndOfBuffer", { fg = spec.bg1 })
	hi("ErrorMsg", { fg = spec.diag.error })
	hi("WinSeparator", { fg = spec.syntax.func })
	link("VertSplit", "WinSeparator")
	hi("Folded", { fg = spec.fg3, bg = spec.bg2 })
	hi("FoldColumn", { fg = spec.fg3 })
	hi("SignColumn", { fg = spec.fg3 })
	hi("Substitute", { fg = spec.bg1, bg = spec.diag.error })
	hi("LineNr", { fg = spec.fg3 })
	hi("MatchParen", { fg = spec.diag.warn, bold = true })
	hi("ModeMsg", { fg = spec.diag.warn, bold = true })
	hi("MoreMsg", { fg = spec.diag.info, bold = true })
	hi("NonText", { fg = spec.bg4 })
	link("SpecialKey", "NonText")
	hi("Pmenu", { bg = spec.bg2 })
	hi("PmenuSel", { bg = spec.sel1 })
	hi("PmenuSbar", { bg = spec.bg2 })
	hi("PmenuThumb", { bg = spec.bg3 })
	link("Question", "MoreMsg")
	link("QuickFixLine", "CursorLine")
	hi("Search", { fg = spec.fg1, bg = spec.sel1 })
	hi("IncSearch", { fg = spec.bg1, bg = spec.diag.hint })
	link("CurSearch", "IncSearch")
	hi("SpellBad", { sp = spec.diag.error, undercurl = true })
	hi("SpellCap", { sp = spec.diag.warn, undercurl = true })
	hi("SpellLocal", { sp = spec.diag.info, undercurl = true })
	hi("SpellRare", { sp = spec.diag.info, undercurl = true })
	hi("StatusLine", { fg = spec.fg2, bg = spec.bg0 })
	hi("StatusLineNC", { fg = spec.fg3, bg = spec.bg0 })
	hi("TabLine", { fg = spec.fg2, bg = spec.bg2 })
	hi("TabLineFill", { bg = spec.bg0 })
	hi("TabLineSel", { fg = spec.bg1, bg = spec.fg3 })
	hi("Title", { fg = syn.func, bold = true })
	hi("Visual", { bg = spec.sel0 })
	link("VisualNOS", "Visual")
	hi("WarningMsg", { fg = spec.diag.warn })
	hi("Whitespace", { fg = spec.bg3 })
	link("WildMenu", "Pmenu")
	hi("WinBar", { fg = spec.fg3, bg = bg1, bold = true })
	hi("WinBarNC", { fg = spec.fg3, bg = bg1, bold = true })

	-- Syntax
	hi("Comment", { fg = syn.comment, italic = true })
	hi("Constant", { fg = syn.const })
	hi("String", { fg = syn.string })
	link("Character", "String")
	hi("Number", { fg = syn.number })
	link("Float", "Number")
	link("Boolean", "Number")
	hi("Identifier", { fg = syn.ident })
	hi("Function", { fg = syn.func })
	hi("Statement", { fg = syn.keyword })
	hi("Conditional", { fg = syn.conditional })
	link("Repeat", "Conditional")
	link("Label", "Conditional")
	hi("Operator", { fg = syn.operator })
	hi("Keyword", { fg = syn.keyword })
	link("Exception", "Keyword")
	hi("PreProc", { fg = syn.preproc })
	link("Include", "PreProc")
	link("Define", "PreProc")
	link("Macro", "PreProc")
	link("PreCondit", "PreProc")
	hi("Type", { fg = syn.type })
	link("StorageClass", "Type")
	link("Structure", "Type")
	link("Typedef", "Type")
	hi("Special", { fg = syn.func })
	link("SpecialChar", "Special")
	link("Tag", "Special")
	link("Delimiter", "Special")
	link("SpecialComment", "Special")
	link("Debug", "Special")
	hi("Underlined", { underline = true })
	hi("Bold", { bold = true })
	hi("Italic", { italic = true })
	hi("Error", { fg = spec.diag.error })
	hi("Todo", { fg = spec.bg1, bg = spec.diag.info })

	-- Citation & Reference Fixes
	hi("pandocCiteKey", { fg = syn.keyword })
	hi("pandocCiteAnchor", { fg = syn.keyword })
	hi("pandocCiteLocator", { fg = syn.keyword })
	hi("pandocPCite", { fg = syn.keyword })
	hi("texRefZone", { fg = syn.keyword })
	hi("texStatement", { fg = syn.keyword })

	-- Diff filetype
	hi("diffAdded", { fg = spec.git.add })
	hi("diffRemoved", { fg = spec.git.removed })
	hi("diffChanged", { fg = spec.git.changed })
	hi("diffOldFile", { fg = spec.diag.warn })
	hi("diffNewFile", { fg = spec.diag.hint })
	hi("diffFile", { fg = spec.diag.info })
	hi("diffLine", { fg = syn.builtin2 })
	hi("diffIndexLine", { fg = syn.preproc })

	-- Diagnostics
	hi("DiagnosticError", { fg = spec.diag.error })
	hi("DiagnosticWarn", { fg = spec.diag.warn })
	hi("DiagnosticInfo", { fg = spec.diag.info })
	hi("DiagnosticHint", { fg = spec.diag.hint })
	hi("DiagnosticOk", { fg = spec.diag.ok })
	link("DiagnosticSignError", "DiagnosticError")
	link("DiagnosticSignWarn", "DiagnosticWarn")
	link("DiagnosticSignInfo", "DiagnosticInfo")
	link("DiagnosticSignHint", "DiagnosticHint")
	link("DiagnosticSignOk", "DiagnosticOk")
	hi("DiagnosticVirtualTextError", { fg = spec.diag.error, bg = spec.diag_bg.error })
	hi("DiagnosticVirtualTextWarn", { fg = spec.diag.warn, bg = spec.diag_bg.warn })
	hi("DiagnosticVirtualTextInfo", { fg = spec.diag.info, bg = spec.diag_bg.info })
	hi("DiagnosticVirtualTextHint", { fg = spec.diag.hint, bg = spec.diag_bg.hint })
	hi("DiagnosticVirtualTextOk", { fg = spec.diag.ok, bg = spec.diag_bg.ok })
	hi("DiagnosticUnderlineError", { undercurl = true, sp = spec.diag.error })
	hi("DiagnosticUnderlineWarn", { undercurl = true, sp = spec.diag.warn })
	hi("DiagnosticUnderlineInfo", { undercurl = true, sp = spec.diag.info })
	hi("DiagnosticUnderlineHint", { undercurl = true, sp = spec.diag.hint })
	hi("DiagnosticUnderlineOk", { undercurl = true, sp = spec.diag.ok })

	-- LSP
	hi("LspReferenceText", { bg = spec.sel0 })
	link("LspReferenceRead", "LspReferenceText")
	link("LspReferenceWrite", "LspReferenceText")
	hi("LspCodeLens", { fg = syn.comment })
	hi("LspCodeLensSeparator", { fg = spec.fg3 })
	hi("LspSignatureActiveParameter", { fg = spec.sel1 })
	hi("LspInlayHint", { fg = syn.comment, bg = spec.bg2 })

	-- Treesitter
	link("@variable", "Identifier")
	link("@variable.builtin", "@variable")
	link("@variable.parameter", "@variable")
	link("@variable.member", "@variable")
	link("@constant", "Constant")
	hi("@constant.builtin", { fg = syn.builtin2 })
	link("@constant.macro", "Macro")
	hi("@module", { fg = syn.builtin1 })
	link("@label", "Label")
	link("@string", "String")
	hi("@string.regexp", { fg = syn.regex })
	hi("@string.escape", { fg = syn.regex, bold = true })
	link("@string.special", "Special")
	hi("@string.special.url", { fg = syn.const, italic = true, underline = true })
	link("@character", "Character")
	link("@character.special", "SpecialChar")
	link("@boolean", "Boolean")
	link("@number", "Number")
	link("@number.float", "Float")
	link("@type", "Type")
	hi("@type.builtin", { fg = syn.builtin1 })
	link("@attribute", "Constant")
	hi("@property", { fg = syn.field })
	link("@function", "Function")
	hi("@function.builtin", { fg = syn.builtin0 })
	hi("@function.macro", { fg = syn.builtin0 })
	hi("@constructor", { fg = syn.ident })
	link("@operator", "Operator")
	link("@keyword", "Keyword")
	hi("@keyword.function", { fg = syn.keyword })
	hi("@keyword.operator", { fg = syn.operator })
	link("@keyword.import", "Include")
	link("@keyword.storage", "StorageClass")
	link("@keyword.repeat", "Repeat")
	hi("@keyword.return", { fg = syn.builtin0 })
	link("@keyword.exception", "Exception")
	link("@keyword.conditional", "Conditional")
	hi("@punctuation.delimiter", { fg = syn.bracket })
	hi("@punctuation.bracket", { fg = syn.bracket })
	hi("@punctuation.special", { fg = syn.builtin1 })
	link("@comment", "Comment")
	hi("@comment.error", { fg = spec.bg1, bg = spec.diag.error })
	hi("@comment.warning", { fg = spec.bg1, bg = spec.diag.warn })
	hi("@comment.todo", { fg = spec.bg1, bg = spec.diag.hint })
	hi("@comment.note", { fg = spec.bg1, bg = spec.diag.info })
	link("@tag", "Keyword")
	hi("@tag.attribute", { fg = syn.func, italic = true })
	hi("@tag.delimiter", { fg = syn.builtin1 })

	-- Treesitter Markdown/LaTeX overrides
	hi("@markup.link.label.markdown_inline", { fg = syn.keyword })
	hi("@markup.link.label.latex", { fg = syn.keyword })

	-- Git signs
	hi("GitSignsAdd", { fg = spec.git.add })
	hi("GitSignsChange", { fg = spec.git.changed })
	hi("GitSignsDelete", { fg = spec.git.removed })

	-- Telescope
	hi("TelescopeBorder", { fg = spec.bg4 })
	hi("TelescopeSelectionCaret", { fg = spec.diag.hint })
	link("TelescopeSelection", "CursorLine")
	link("TelescopeMatching", "Search")

	-- fzf-lua
	hi("FzfLuaNormal", { fg = spec.fg1, bg = spec.bg1 })
	hi("FzfLuaBorder", { fg = spec.bg4, bg = spec.bg1 })
	hi("FzfLuaTitle", { fg = spec.palette.orange.base, bg = spec.bg1, bold = true })
	link("FzfLuaPreviewNormal", "FzfLuaNormal")
	link("FzfLuaPreviewBorder", "FzfLuaBorder")
	link("FzfLuaPreviewTitle", "FzfLuaTitle")

	-- nvim-cmp
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

	-- blink.cmp / Pmenu
	hi("CmpPmenu", { bg = spec.bg2, fg = spec.fg2 })
	hi("CmpSel", { bg = spec.sel1, fg = spec.fg1, bold = true })
	hi("CmpDoc", { bg = spec.bg2, fg = spec.fg2 })
	hi("CmpSignatureHelp", { bg = spec.bg2, fg = spec.fg2 })
	hi("BlinkCmpDocSeparator", { bg = spec.bg2, fg = spec.palette.blue.base })
	hi("BlinkCmpLabelMatch", { fg = spec.palette.blue.bright, bold = true })

	-- which-key
	link("WhichKey", "Identifier")
	link("WhichKeyGroup", "Function")
	link("WhichKeyDesc", "Keyword")
	link("WhichKeySeparator", "Comment")
	link("WhichKeyFloat", "NormalFloat")
	link("WhichKeyValue", "Comment")
end

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

function M.apply_dim_inactive(spec, factor)
    local C = require("nightfox.color")

    -- Create dimmed versions of all main syntax colors by blending toward bg
    local function dim(hex)
        return C.blend_hex(hex, spec.bg1, factor)
    end

    local syn = spec.syntax
    local groups = {
        NormalNCDim        = { fg = dim(spec.fg1), bg = C.blend_hex(spec.bg1, spec.bg0, 0.7) },
        CommentDim         = { fg = dim(syn.comment), italic = true },
        ConstantDim        = { fg = dim(syn.const) },
        StringDim          = { fg = dim(syn.string) },
        NumberDim          = { fg = dim(syn.number) },
        IdentifierDim      = { fg = dim(syn.ident) },
        FunctionDim        = { fg = dim(syn.func) },
        KeywordDim         = { fg = dim(syn.keyword) },
        TypeDim            = { fg = dim(syn.type) },
        StatementDim       = { fg = dim(syn.keyword) },
        PreProcDim         = { fg = dim(syn.preproc) },
        OperatorDim        = { fg = dim(syn.operator) },
        SpecialDim         = { fg = dim(syn.func) },
    }

    for name, opts in pairs(groups) do
        vim.api.nvim_set_hl(0, name, opts)
    end

    -- remaps/dim active groups
    local winhighlight = table.concat({
        "Normal:NormalNCDim",
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

    -- apply/remove winhighlight on focus change
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

return M
