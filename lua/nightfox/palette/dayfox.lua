local C = require("nightfox.color")

local meta = {
  name = "dayfox",
  light = true,
}

local palette = {
  black   = C.make_shade("#352c24", 0.15, -0.15, true),
  red     = C.make_shade("#a5222f", 0.15, -0.15, true),
  green   = C.make_shade("#396847", 0.15, -0.15, true),
  yellow  = C.make_shade("#AC5402", 0.15, -0.15, true),
  blue    = C.make_shade("#2848a9", 0.15, -0.15, true),
  magenta = C.make_shade("#6e33ce", 0.15, -0.15, true),
  cyan    = C.make_shade("#287980", 0.15, -0.15, true),
  white   = C.make_shade("#f2e9e1", 0.15, -0.15, true),
  orange  = C.make_shade("#955f61", 0.15, -0.15, true),
  pink    = C.make_shade("#a440b5", 0.15, -0.15, true),

  comment = "#837a72",

  bg0  = "#e4dcd4",
  bg1  = "#f6f2ee",
  bg2  = "#dbd1dd",
  bg3  = "#d3c7bb",
  bg4  = "#aab0ad",

  fg0  = "#302b5d",
  fg1  = "#3d2b5a",
  fg2  = "#643f61",
  fg3  = "#824d5b",

  sel0 = "#e7d2be",
  sel1 = "#a4c1c2",
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
    builtin0    = pal.red.base,
    builtin1    = pal.cyan.dim,
    builtin2    = pal.orange.dim,
    builtin3    = pal.red.dim,
    comment     = pal.comment,
    conditional = pal.magenta.dim,
    const       = pal.orange.dim,
    dep         = spec.fg3,
    field       = pal.blue.base,
    func        = pal.blue.dim,
    ident       = pal.cyan.base,
    keyword     = pal.magenta.base,
    number      = pal.orange.base,
    operator    = spec.fg2,
    preproc     = pal.pink.dim,
    regex       = pal.yellow.dim,
    statement   = pal.magenta.base,
    string      = pal.green.base,
    type        = pal.yellow.base,
    variable    = pal.black.base,
  }

  spec.diag = {
    error = pal.red.base,
    warn  = pal.yellow.base,
    info  = pal.blue.base,
    hint  = pal.green.base,
    ok    = pal.green.base,
  }

  spec.diag_bg = {
    error = C.blend_hex(spec.bg1, spec.diag.error, 0.3),
    warn  = C.blend_hex(spec.bg1, spec.diag.warn,  0.3),
    info  = C.blend_hex(spec.bg1, spec.diag.info,  0.3),
    hint  = C.blend_hex(spec.bg1, spec.diag.hint,  0.3),
    ok    = C.blend_hex(spec.bg1, spec.diag.ok,    0.3),
  }

  spec.diff = {
    add    = C.blend_hex(spec.bg1, pal.green.base, 0.2),
    delete = C.blend_hex(spec.bg1, pal.red.base,   0.2),
    change = C.blend_hex(spec.bg1, pal.blue.base,  0.2),
    text   = C.blend_hex(spec.bg1, pal.blue.base,  0.4),
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
