# nightfox.nvim

My fork of [EdenEast's nightfox.nvim](https://github.com/EdenEast/nightfox.nvim). Check his repo for a more flexible and feature rich foxy theme :).

I rewrote and removed most of the original repo's code, I tweaked the colors to my liking and I included an autocommand to disable `client.server_capabilities.semanticTokensProvider` from lsp-s. That way, colors are more simply defined just using treesitter. 

This is just a minimal Lua-only Neovim colorscheme plugin with two themes:

- **nightfox** — dark
- **dayfox** — light

No compilation step, no extra foxes, no Vim compatibility layer.

The theme follows the GNOME light/dark setting automatically. See [Automatic theme selection (GNOME)](#automatic-theme-selection-gnome).

The same documentation is available inside Neovim with `:help nightfox`.

---

## Installation

With the built-in plugin manager (`vim.pack`, Neovim 0.12+):

```lua
vim.pack.add({ "https://github.com/urtzienriquez/nightfox.nvim" })

require("nightfox").setup({
    -- options go here (all optional)
})
```

`require("nightfox")` applies a theme by itself (nightfox or dayfox, picked from GNOME), so there is no need to call `:colorscheme` afterwards. `setup()` only re-applies the theme when the options you pass actually change the config. Calling it again at runtime with new options updates the theme in place.

---

## Automatic theme selection (GNOME)

On startup the theme is picked from GNOME's `org.gnome.desktop.interface color-scheme` setting: `nightfox` if it contains "dark", `dayfox` otherwise.

- **Startup is instant**: the last detected theme is cached in `stdpath("state")/nightfox_theme` and applied right away. A `gsettings` check then runs asynchronously after startup and switches the theme if the cache was stale.
- **First run**: with no cache yet, `gsettings` is queried synchronously once. If it is unavailable (non-GNOME desktops), this falls back to `dayfox`.
- **Live sync**: GNOME is checked again when Neovim regains focus (`FocusGained`, at most every 2 seconds) and on every terminal resize (`SIGWINCH`). If the GNOME setting differs from the current theme, the theme is switched to match.

As a consequence, a theme picked manually with `:colorscheme` is replaced by the GNOME one on the next check if the two differ. The sync cannot be disabled currently. When `gsettings` fails (e.g. not on GNOME), the checks do nothing and the manually picked theme stays.

---

## Options

All options are passed to `setup()`. Every option has a default and is optional.

```lua
require("nightfox").setup({
    transparent     = false,  -- transparent background
    terminal_colors = true,   -- set vim.g.terminal_color_* variables
    dim_inactive    = false,  -- dim inactive windows (see below)
    code_block_bg   = true,   -- tinted background on fenced code blocks in markdown/quarto/rmd
    statusline      = true,   -- built-in statusline (disabled if a statusline plugin is detected)
    on_load         = nil,    -- callback for highlight/palette overrides (see below)
})
```

### `transparent` (boolean, default: `false`)

Removes the background from the main `Normal` highlight group, letting the terminal background show through.

```lua
require("nightfox").setup({ transparent = true })
```

---

### `terminal_colors` (boolean, default: `true`)

Sets `vim.g.terminal_color_0` through `vim.g.terminal_color_15` to the palette colors so embedded terminals match the theme.

```lua
require("nightfox").setup({ terminal_colors = false })
```

---

### `dim_inactive` (boolean | number, default: `false`)

Dims the text in unfocused windows and gives them a slightly darker background (applied through `winhighlight` when leaving a window or when Neovim loses focus). Accepts either `true` (uses the default blend factor of `0.4`) or a number between `0` and `1` to control the intensity — lower values are more subtle, higher values are more aggressive.

```lua
-- use default factor
require("nightfox").setup({ dim_inactive = true })

-- custom factor (0 = no dimming, 1 = fully blended into background)
require("nightfox").setup({ dim_inactive = 0.25 })
```

---

### `code_block_bg` (boolean, default: `true`)

Applies a full-line tinted background (`spec.bg2`) to fenced code blocks in markdown, quarto, rmd, pandoc and rnoweb files. Uses extmarks so the background covers the entire line including empty lines and trailing whitespace.

```lua
require("nightfox").setup({ code_block_bg = false })
```

---

### `statusline` (boolean, default: `true`)

Enables the built-in statusline. It is automatically suppressed if a known statusline plugin (lualine, heirline, feline, etc.) is detected in `package.loaded`. The check runs when the theme is applied, so the statusline plugin must be loaded before nightfox for the detection to work. Otherwise, set this to `false`.

```lua
require("nightfox").setup({ statusline = false })
```

---

### `on_load` (function, default: `nil`)

A callback fired after the main highlight groups have been applied. It runs *before* the terminal colors, `dim_inactive`, code-block and statusline highlights are set, so overrides of those groups (e.g. `NightfoxCodeBlock`, `RNvimTitle`, `SL*`, `*Dim`) are overwritten. Receives `spec` and `palette` as arguments, which gives you access to all theme colors for overriding individual highlight groups.

```lua
require("nightfox").setup({
    on_load = function(spec, palette)
        -- your overrides here
    end,
})
```

This is the main extension point — see the full reference below.

---

## Highlight overrides via `on_load`

The `on_load` callback receives two arguments:

- **`spec`** — the resolved color spec (backgrounds, foregrounds, semantic colors, diagnostic colors, git colors, diff colors)
- **`palette`** — the raw palette (the named colors like `blue`, `red`, etc., each with `.base`, `.bright`, and `.dim` variants)

### `spec` fields

| Field | Description |
|---|---|
| `spec.bg0` | Darkest background (statusline, etc.) |
| `spec.bg1` | Main background (`Normal`) |
| `spec.bg2` | Slightly lighter background (popups, code blocks) |
| `spec.bg3` | Cursor line background |
| `spec.bg4` | Subtle UI elements, borders |
| `spec.fg0` | Brightest foreground |
| `spec.fg1` | Main foreground (`Normal`) |
| `spec.fg2` | Dimmer foreground (statusline text) |
| `spec.fg3` | Muted foreground (line numbers, sign column, float borders) |
| `spec.sel0` | Visual selection background |
| `spec.sel1` | Active selection / pmenu selection |
| `spec.syntax.comment` | Comment color |
| `spec.syntax.string` | String color |
| `spec.syntax.keyword` | Keyword color |
| `spec.syntax.func` | Function color |
| `spec.syntax.type` | Type color |
| `spec.syntax.const` | Constant color |
| `spec.syntax.number` | Number color |
| `spec.syntax.operator` | Operator color |
| `spec.syntax.field` | Struct/object field color |
| `spec.syntax.ident` | Identifier color |
| `spec.syntax.bracket` | Bracket/delimiter color |
| `spec.syntax.builtin0` | Built-in functions |
| `spec.syntax.builtin1` | Built-in types/modules |
| `spec.syntax.builtin2` | Built-in constants |
| `spec.syntax.builtin3` | Extra built-in color (not used by the default groups) |
| `spec.syntax.preproc` | Preprocessor directives |
| `spec.syntax.regex` | Regex color |
| `spec.syntax.conditional` | Conditionals (if/else/etc.) |
| `spec.syntax.statement` | Statement color (not used by the default groups) |
| `spec.syntax.variable` | Variable color (not used by the default groups) |
| `spec.syntax.dep` | Deprecated-symbol color (not used by the default groups) |
| `spec.diag.error` | Diagnostic error color |
| `spec.diag.warn` | Diagnostic warning color |
| `spec.diag.info` | Diagnostic info color |
| `spec.diag.hint` | Diagnostic hint color |
| `spec.diag.ok` | Diagnostic ok color |
| `spec.diag_bg.error` / `.warn` / `.info` / `.hint` / `.ok` | Tinted backgrounds for diagnostic virtual text |
| `spec.diff.add` | Diff added-line background |
| `spec.diff.delete` | Diff deleted-line background |
| `spec.diff.change` | Diff changed-line background |
| `spec.diff.text` | Diff changed-text background |
| `spec.git.add` | Git added color |
| `spec.git.removed` | Git removed color |
| `spec.git.changed` | Git changed color |
| `spec.git.conflict` | Git conflict color (not used by the default groups) |
| `spec.git.ignored` | Git ignored color (not used by the default groups) |

### `palette` fields

Each color in the palette has three variants:

```
palette.blue.base    -- the base color
palette.blue.bright  -- lighter variant
palette.blue.dim     -- darker variant
```

Available colors: `black`, `red`, `green`, `yellow`, `blue`, `pblue`, `magenta`, `cyan`, `ecyan`, `white`, `orange`, `pink`.

The palette also has plain hex fields (no variants): `comment`, `bg0`–`bg4`, `fg0`–`fg3`, `sel0`, `sel1`.

---

### Examples

```lua
require("nightfox").setup({
    on_load = function(spec, palette)

        -- Override highlight groups using spec semantic colors
        vim.api.nvim_set_hl(0, "NormalNC",    { fg = spec.fg1,             bg = spec.bg1 })
        vim.api.nvim_set_hl(0, "WinSeparator",{ fg = palette.blue.base,    bg = "none"   })

        -- Override syntax groups using spec.syntax
        vim.api.nvim_set_hl(0, "Comment",     { fg = spec.syntax.comment,  italic = true })
        vim.api.nvim_set_hl(0, "Keyword",     { fg = spec.syntax.keyword,  bold   = true })

        -- Override treesitter groups
        vim.api.nvim_set_hl(0, "@markup.strong", { bold = true })

        -- Use raw palette colors directly
        vim.api.nvim_set_hl(0, "Search",      { fg = palette.yellow.base,  bg = palette.blue.dim })

    end,
})
```

---

## Switching themes at runtime

Both themes can be loaded at any time with `:colorscheme`:

```
:colorscheme nightfox
:colorscheme dayfox
```

Or from Lua:

```lua
vim.cmd.colorscheme("dayfox")
```

On GNOME, a manually selected theme only lasts until the next GNOME check (focus regained or terminal resized), which switches back to the theme matching the GNOME setting. See [Automatic theme selection (GNOME)](#automatic-theme-selection-gnome).

To bind a toggle:

```lua
vim.keymap.set("n", "<leader>ub", function()
    if vim.o.background == "dark" then
        vim.cmd.colorscheme("dayfox")
    else
        vim.cmd.colorscheme("nightfox")
    end
end, { desc = "Toggle background" })
```
