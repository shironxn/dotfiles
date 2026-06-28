-- pywal colorscheme
-- loads wallpaper colors from ~/.cache/wal/colors.json
-- auto-generated; re-run pywal to update
vim.g.colors_name = "pywal"

local pywal_file = vim.fn.readfile(vim.fn.expand("~/.cache/wal/colors.json"))
if not pywal_file then
  return
end
local ok, data = pcall(vim.json.decode, table.concat(pywal_file, "\n"))
if not ok or not data then
  return
end

local c = data.colors
local bg = data.special.background
local fg = data.special.foreground

-- transparent bg → inherits terminal pywal
for _, hl in ipairs({ "Normal", "NormalFloat", "SignColumn", "LineNr", "MsgArea", "ModeArea" }) do
  pcall(vim.api.nvim_set_hl, 0, hl, { bg = nil })
end

-- gutter / UI
pcall(vim.api.nvim_set_hl, 0, "Directory", { fg = c.color5 })
pcall(vim.api.nvim_set_hl, 0, "Title", { fg = c.color4, bold = true })
pcall(vim.api.nvim_set_hl, 0, "SpecialKey", { fg = c.color8 })
pcall(vim.api.nvim_set_hl, 0, "MoreMsg", { fg = c.color2 })
pcall(vim.api.nvim_set_hl, 0, "Question", { fg = c.color5 })
pcall(vim.api.nvim_set_hl, 0, "WarningMsg", { fg = c.color3 })
pcall(vim.api.nvim_set_hl, 0, "ErrorMsg", { fg = c.color1 })
pcall(vim.api.nvim_set_hl, 0, "NonText", { fg = c.color8 })
pcall(vim.api.nvim_set_hl, 0, "CursorLineNr", { fg = c.color6, bold = true })
pcall(vim.api.nvim_set_hl, 0, "CursorLine", { bg = c.color0 })
pcall(vim.api.nvim_set_hl, 0, "ColorColumn", { bg = c.color0 })
pcall(vim.api.nvim_set_hl, 0, "VertSplit", { fg = c.color8 })
pcall(vim.api.nvim_set_hl, 0, "WinSeparator", { fg = c.color8 })
pcall(vim.api.nvim_set_hl, 0, "Visual", { bg = c.color8, fg = bg })
pcall(vim.api.nvim_set_hl, 0, "VisualNOS", { bg = c.color8 })

-- syntax
local syn = {
  Comment = { fg = c.color8, italic = true },
  String = { fg = c.color2 },
  Number = { fg = c.color1 },
  Boolean = { fg = c.color1 },
  Function = { fg = c.color4 },
  Identifier = { fg = fg },
  Keyword = { fg = c.color5 },
  Conditional = { fg = c.color5 },
  Repeat = { fg = c.color5 },
  Operator = { fg = c.color5 },
  Type = { fg = c.color3 },
  StorageClass = { fg = c.color3 },
  Structure = { fg = c.color3 },
  Constant = { fg = c.color1 },
  PreProc = { fg = c.color4 },
  Include = { fg = c.color4 },
  Special = { fg = c.color6 },
  Todo = { fg = bg, bg = c.color6 },
  Error = { fg = c.color1 },
  Underlined = { underline = true, sp = c.color5 },
  Label = { fg = c.color6 },
  Delimiter = { fg = c.color8 },
  Exception = { fg = c.color1 },
  Character = { fg = c.color2 },
  Float = { fg = c.color1 },
}
for name, opts in pairs(syn) do
  pcall(vim.api.nvim_set_hl, 0, name, opts)
end

-- pmenu (completion)
pcall(vim.api.nvim_set_hl, 0, "Pmenu", { bg = c.color0, fg = fg })
pcall(vim.api.nvim_set_hl, 0, "PmenuSel", { bg = c.color5, fg = bg })
pcall(vim.api.nvim_set_hl, 0, "PmenuSbar", { bg = c.color0 })
pcall(vim.api.nvim_set_hl, 0, "PmenuThumb", { bg = c.color8 })

-- tabs & status
local ui = {
  TabLine = { bg = c.color0, fg = c.color8 },
  TabLineSel = { bg = c.color5, fg = bg },
  TabLineFill = { bg = c.color0 },
  StatusLine = { bg = c.color0, fg = fg },
  StatusLineNC = { bg = c.color0, fg = c.color8 },
}
for name, opts in pairs(ui) do
  pcall(vim.api.nvim_set_hl, 0, name, opts)
end

-- search
pcall(vim.api.nvim_set_hl, 0, "Search", { bg = c.color3, fg = bg })
pcall(vim.api.nvim_set_hl, 0, "IncSearch", { bg = c.color5, fg = bg })
pcall(vim.api.nvim_set_hl, 0, "MatchParen", { bg = c.color8, bold = true })

-- diagnostics
pcall(vim.api.nvim_set_hl, 0, "DiagnosticError", { fg = c.color1 })
pcall(vim.api.nvim_set_hl, 0, "DiagnosticWarn", { fg = c.color3 })
pcall(vim.api.nvim_set_hl, 0, "DiagnosticInfo", { fg = c.color5 })
pcall(vim.api.nvim_set_hl, 0, "DiagnosticHint", { fg = c.color8 })
pcall(vim.api.nvim_set_hl, 0, "DiagnosticSignError", { fg = c.color1 })
pcall(vim.api.nvim_set_hl, 0, "DiagnosticSignWarn", { fg = c.color3 })
pcall(vim.api.nvim_set_hl, 0, "DiagnosticSignInfo", { fg = c.color5 })
pcall(vim.api.nvim_set_hl, 0, "DiagnosticSignHint", { fg = c.color8 })

-- float / border
pcall(vim.api.nvim_set_hl, 0, "FloatBorder", { fg = c.color5 })
pcall(vim.api.nvim_set_hl, 0, "FloatTitle", { fg = c.color5, bold = true })

-- which-key
pcall(vim.api.nvim_set_hl, 0, "WhichKey", { fg = c.color4, bold = true })
pcall(vim.api.nvim_set_hl, 0, "WhichKeyGroup", { fg = c.color5 })
pcall(vim.api.nvim_set_hl, 0, "WhichKeyDesc", { fg = c.color6 })

-- treesitter
local ts = {
  ["@variable"] = { fg = fg },
  ["@variable.builtin"] = { fg = c.color5 },
  ["@property"] = { fg = fg },
  ["@field"] = { fg = fg },
  ["@parameter"] = { fg = fg },
  ["@constant"] = { fg = c.color1 },
  ["@string"] = { fg = c.color2 },
  ["@string.regex"] = { fg = c.color5 },
  ["@function"] = { fg = c.color4 },
  ["@function.builtin"] = { fg = c.color4 },
  ["@method"] = { fg = c.color4 },
  ["@keyword"] = { fg = c.color5 },
  ["@keyword.function"] = { fg = c.color5 },
  ["@keyword.return"] = { fg = c.color5 },
  ["@type"] = { fg = c.color3 },
  ["@type.builtin"] = { fg = c.color3 },
  ["@comment"] = { fg = c.color8, italic = true },
  ["@number"] = { fg = c.color1 },
  ["@boolean"] = { fg = c.color1 },
  ["@operator"] = { fg = c.color5 },
  ["@exception"] = { fg = c.color1 },
  ["@punctuation.delimiter"] = { fg = c.color8 },
  ["@punctuation.bracket"] = { fg = c.color8 },
  ["@tag"] = { fg = c.color4 },
  ["@tag.delimiter"] = { fg = c.color8 },
  ["@tag.attribute"] = { fg = c.color6 },
  ["@label"] = { fg = c.color6 },
  ["@include"] = { fg = c.color4 },
  ["@conditional"] = { fg = c.color5 },
  ["@repeat"] = { fg = c.color5 },
  ["@diff.plus"] = { fg = c.color2 },
  ["@diff.minus"] = { fg = c.color1 },
  ["@diff.delta"] = { fg = c.color3 },
}
for name, opts in pairs(ts) do
  pcall(vim.api.nvim_set_hl, 0, name, opts)
end

-- blink/cmp
pcall(vim.api.nvim_set_hl, 0, "BlinkCmpDoc", { bg = c.color0 })
pcall(vim.api.nvim_set_hl, 0, "BlinkCmpDocBorder", { fg = c.color5 })
pcall(vim.api.nvim_set_hl, 0, "BlinkCmpMenu", { bg = c.color0 })
pcall(vim.api.nvim_set_hl, 0, "BlinkCmpMenuSelection", { bg = c.color5, fg = bg })
