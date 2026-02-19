local C = require("nightfox.color")

local meta = {
  name = "nightfox",
  light = false,
}

local palette = {
  black   = C.make_shade("#393b44", 0.15, -0.15),
  red     = C.make_shade("#c94f6d", 0.15, -0.15),
  green   = C.make_shade("#81b29a", 0.10, -0.15),
  yellow  = C.make_shade("#dbc074", 0.15, -0.15),
  blue    = C.make_shade("#719cd6", 0.15, -0.15),
  magenta = C.make_shade("#9d79d6", 0.30, -0.15),
  cyan    = C.make_shade("#63cdcf", 0.15, -0.15),
  white   = C.make_shade("#dfdfe0", 0.15, -0.15),
  orange  = C.make_shade("#f4a261", 0.15, -0.15),
  pink    = C.make_shade("#d67ad2", 0.15, -0.15),

  comment = "#738091",

  bg0  = "#131a24",
  bg1  = "#192330",
  bg2  = "#212e3f",
  bg3  = "#29394f",
  bg4  = "#39506d",

  fg0  = "#d6d6d7",
  fg1  = "#cdcecf",
  fg2  = "#aeafb0",
  fg3  = "#71839b",

  sel0 = "#2b3b51",
  sel1 = "#3c5372",
}

local function generate_spec(pal)
  local spec = {
    bg0  = pal.bg0,
    bg1  = pal.bg1,
    bg2  = pal.bg2,
    bg3  = pal.bg3,
    bg4  = pal.bg4,
    fg0  = pal.fg0,
    fg1  = pal.fg1,
    fg2  = pal.fg2,
    fg3  = pal.fg3,
    sel0 = pal.sel0,
    sel1 = pal.sel1,
  }

  spec.syntax = {
    bracket     = spec.fg2,
    builtin0    = pal.blue.base,
    builtin1    = pal.cyan.bright,
    builtin2    = pal.orange.bright,
    builtin3    = pal.red.bright,
    comment     = pal.comment,
    conditional = pal.magenta.bright,
    const       = pal.orange.bright,
    dep         = spec.fg3,
    field       = pal.blue.base,
    func        = pal.blue.bright,
    -- ident       = pal.cyan.base,
    ident       = pal.white.base,
    keyword     = pal.magenta.base,
    -- number      = pal.orange.base,
    number      = pal.white.base,
    -- operator    = spec.fg2,
    operator    = pal.orange.base,
    preproc     = pal.pink.bright,
    regex       = pal.yellow.bright,
    statement   = pal.magenta.base,
    string      = pal.green.base,
    type        = pal.yellow.base,
    variable    = pal.white.base,
  }

  spec.diag = {
    error = pal.red.base,
    warn  = pal.yellow.base,
    info  = pal.blue.base,
    hint  = pal.green.base,
    ok    = pal.green.base,
  }

  spec.diag_bg = {
    error = C.blend_hex(spec.bg1, spec.diag.error, 0.2),
    warn  = C.blend_hex(spec.bg1, spec.diag.warn,  0.2),
    info  = C.blend_hex(spec.bg1, spec.diag.info,  0.2),
    hint  = C.blend_hex(spec.bg1, spec.diag.hint,  0.2),
    ok    = C.blend_hex(spec.bg1, spec.diag.ok,    0.2),
  }

  spec.diff = {
    add    = C.blend_hex(spec.bg1, pal.green.dim, 0.15),
    delete = C.blend_hex(spec.bg1, pal.red.dim,   0.15),
    change = C.blend_hex(spec.bg1, pal.blue.dim,  0.15),
    text   = C.blend_hex(spec.bg1, pal.cyan.dim,  0.2),
  }

  spec.git = {
    add      = pal.green.base,
    removed  = pal.red.base,
    changed  = pal.yellow.base,
    conflict = pal.orange.base,
    ignored  = pal.comment,
  }

  return spec
end

return { meta = meta, palette = palette, generate_spec = generate_spec }
