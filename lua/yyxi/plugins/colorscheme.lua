local M = {}

function M.setup()
  local opts = {
    palette = {
      base00 = '#1d2021',
      base01 = '#3c3836',
      base02 = '#504945',
      base03 = '#665c54',
      base04 = '#bdae93',
      base05 = '#d5c4a1',
      base06 = '#ebdbb2',
      base07 = '#fbf1c7',
      base0C = '#fb4833',
      base0E = '#d3859a',
      base0A = '#fabc2e',
      base0D = '#fe8019',
      base09 = '#d65d0e',
      base0B = '#83a597',

      base08 = '#8ec07b',
      base0F = '#b8ba25',
    },

    use_cterm = not vim.o.termguicolors,
    plugins = {
      default = false,
      ['nvim-mini/mini.nvim'] = true,
      ['folke/lazy.nvim'] = true,
      ['folke/which-key.nvim'] = true,
      ['hrsh7th/nvim-cmp'] = true,
      ['lukas-reineke/indent-blankline.nvim'] = true,
      ['nvim-lualine/lualine.nvim'] = true,
      ['nvim-telescope/telescope.nvim'] = true,
    },
  }

  require('mini.base16').setup(opts)

  -- stylua: ignore start

  local p = opts.palette
  local hi = function(name, data) vim.api.nvim_set_hl(0, name, data) end
  local hm = function(name, data)
    local d = vim.tbl_extend('force',
      vim.api.nvim_get_hl(0,
        { name = data.link, link = false, create = false }), data)
    d.link = nil
    hi(name, d)
  end

  hi('Cursor',
    { force = true, fg = p.base00, bg = p.base06, attr = nil, sp = nil, nocombine = true, italic = true })
  hi('Function',
    { force = true, fg = p.base0D, bg = nil, attr = nil, sp = nil, nocombine = false, })
  hi('Comment',
    { force = true, fg = p.base03, bg = nil, attr = nil, sp = nil, nocombine = false, })
  hi('Delimiter',
    { force = true, fg = p.base09, bg = nil, attr = nil, sp = nil, nocombine = false, })
  hi('Boolean',
    { force = true, fg = p.base08, bg = nil, attr = nil, sp = nil, nocombine = false, })
  hi('Float',
    { force = true, fg = p.base0B, bg = nil, attr = nil, sp = nil, nocombine = false, italic = true })
  hi('Number',
    { force = true, fg = p.base0B, bg = nil, attr = nil, sp = nil, nocombine = false, italic = true })
  hi('Constant',
    { force = true, fg = p.base06, bg = nil, attr = nil, sp = nil, nocombine = false })
  hi('Operator',
    { force = true, fg = p.base0C, bg = nil, attr = nil, sp = nil, nocombine = false })
  hi('Structure',
    { force = true, fg = p.base05, bg = nil, attr = nil, sp = nil, nocombine = false })
  hi('Identifier', { force = true, link = 'Normal', })

  hi('Folded',
    { force = true, fg = p.base04, bg = '#262A2B', attr = nil, sp = nil, nocombine = false })

  hi('TelescopeBorder',
    { force = true, fg = p.base01, bg = p.base00 })

  hi('SignColumn', { force = true, bg = p.base00 })

  hi('TelescopeTitle',
    { force = true, fg = p.base03, bg = p.base00 })

  -- FIXME https://github.com/microsoft/vscode/issues/97063
  -- TreeSitter Highlights https://github.com/nvim-treesitter/nvim-treesitter/blob/master/CONTRIBUTING.md

  -- Identifiers

  hi('@variable',
    { force = true, fg = p.base05, bg = nil })
  hm('@variable.builtin',
    { force = true, link = '@variable', bold = true })
  hi('@variable.member', { force = true, link = '@variable' })
  hi('@variable.parameter', { force = true, link = '@variable' })
  hm('@variable.parameter.builtin',
    { force = true, link = '@variable.parameter', bold = true })

  hi('@constant', { force = true, link = 'Constant' })
  hm('@constant.builtin',
    { force = true, link = '@constant', bold = true })
  hi('@constant.macro', { force = true, link = 'Macro' })

  hi('@module', { force = true, link = 'Identifier' })
  hm('@module.builtin',
    { force = true, link = '@module', bold = true })
  hi('@label', { force = true, link = 'Label' })

  -- Literals

  hi('@string', { force = true, link = 'String' })
  hi('@string.documentation', { force = true, link = '@string' })
  hm('@string.escape',
    { force = true, link = '@string', bold = true })
  hm('@string.regexp',
    { force = true, link = '@string', italic = true, bold = true })
  hm('@string.special',
    { force = true, link = '@string', italic = true, bold = true })
  hi('@string.special.path', { force = true, link = 'Directory' })
  hi('@string.special.symbol', { force = true, link = '@constant' })
  hi('@string.special.url', { force = true, link = '@markup.link.url' })
  hm('@string.special.url.comment',
    { force = true, link = 'Comment', --[[ underline = true ]] })

  hi('@character', { force = true, link = 'Character' })
  hm('@character.special',
    { force = true, link = '@character', bold = true })

  hi('@boolean', { force = true, link = 'Boolean' })
  hi('@number', { force = true, link = 'Number' })
  hi('@number.float', { force = true, link = 'Float' })

  -- Types

  hi('@type', { force = true, link = 'Type' })
  hm('@type.builtin',
    { force = true, link = '@type', bold = true })
  hi('@type.definition', { force = true, link = 'Typedef' })
  hi('@type.qualifier', { force = true, link = 'StorageClass' })

  hi('@attribute', { force = true, link = 'Macro' })
  hm('@attribute.builtin',
    { force = true, link = '@attribute', bold = true })
  hi('@property', { force = true, link = '@variable' })

  -- Functions

  hi('@function', { force = true, link = 'Function' })
  hm('@function.builtin',
    { force = true, link = '@function', bold = true })
  hm('@function.call',
    { force = true, link = '@function', italic = true })
  hi('@function.macro', { force = true, link = 'Macro' })

  hi('@function.method', { force = true, link = '@function' })
  hi('@function.method.call', { force = true, link = '@function.call' })

  hi('@constructor', { force = true, link = '@function.builtin' })
  hi('@operator', { force = true, link = 'Operator' })

  -- Keywords

  hi('@keyword', { force = true, link = 'Keyword' })
  hi('@keyword.coroutine', { force = true, link = '@keyword' })
  hi('@keyword.debug', { force = true, link = '@keyword' })
  hi('@keyword.exception', { force = true, link = '@keyword' })
  hi('@keyword.function', { force = true, link = '@keyword' })
  hi('@keyword.import', { force = true, link = '@keyword' })
  hi('@keyword.modifier', { force = true, link = '@keyword' })
  hi('@keyword.operator', { force = true, link = '@keyword' })
  hi('@keyword.repeat', { force = true, link = '@keyword' })
  hi('@keyword.return', { force = true, link = '@keyword' })
  hi('@keyword.storage', { force = true, link = '@keyword' })
  hi('@keyword.type', { force = true, link = '@keyword' })

  hi('@keyword.conditional', { force = true, link = 'Conditional' })
  hi('@keyword.conditional.ternary',
    { force = true, link = 'Conditional' })

  hi('@keyword.directive', { force = true, link = '@keyword' })
  hi('@keyword.directive.define',
    { force = true, link = '@keyword.directive' })

  -- Punctuation

  hi('@punctuation', { force = true, link = 'Delimiter' })
  hi('@punctuation.bracket', { force = true, link = '@punctuation' })
  hi('@punctuation.delimiter', { force = true, link = '@punctuation' })
  hm('@punctuation.special',
    { force = true, link = '@punctuation', bold = true })

  -- Comments

  hi('@comment', { force = true, link = 'Comment' })
  hi('@comment.documentation', { force = true, link = '@comment' })

  -- TODO: minihipatterns
  hi('@comment.error', { force = true, link = '@text.danger' })
  hi('@comment.note', { force = true, link = '@text.note' })
  hi('@comment.todo', { force = true, link = '@text.todo' })
  hi('@comment.warning', { force = true, link = '@text.warning' })

  -- Markup

  hi('@markup.strong', { force = true, link = '@text.strong' })
  hi('@markup.italic', { force = true, link = '@text.emphasis' })
  hi('@markup.strikethrough',
    { force = true, link = '@text.strikethrough' })
  hi('@markup.underline', { force = true, link = '@text.underline' })

  hi('@markup.heading', { force = true, link = '@text.title' })
  hi('@markup.heading.1', { force = true, link = '@text.title' })
  hi('@markup.heading.2', { force = true, link = '@text.title' })
  hi('@markup.heading.3', { force = true, link = '@text.title' })
  hi('@markup.heading.4', { force = true, link = '@text.title' })
  hi('@markup.heading.5', { force = true, link = '@text.title' })
  hi('@markup.heading.6', { force = true, link = '@text.title' })

  hi('@markup.quote', { force = true, link = '@string.special' })
  hi('@markup.math', { force = true, link = '@string.special' })

  hi('@markup.link', { force = true, link = '@text.reference' })
  hi('@markup.link.label', { force = true, link = '@markup.link' })
  hi('@markup.link.url',
    { force = true, fg = p.base05, bg = nil, underline = true })

  hi('@markup.raw', { force = true, link = '@text.literal' })
  hi('@markup.raw.block', { force = true, link = '@markup.raw' })

  hi('@markup.list', { force = true, link = '@punctuation.special' })
  hi('@markup.list.checked', { force = true, link = 'DiagnosticOk' })
  hi('@markup.list.unchecked', { force = true, link = 'DiagnosticWarn' })

  hi('@markup.environment', { force = true, link = '@module' })

  -- Other: Text

  hi('@text.strong',
    { force = true, fg = nil, bg = nil, bold = true })
  hi('@text.strike',
    { force = true, fg = nil, bg = nil, strikethrough = true })
  hi('@text.emphasis',
    { force = true, fg = nil, bg = nil, italic = true })
  hi('@text.underline', { force = true, link = 'Underlined' })

  hi('@text.danger', { force = true, link = 'ErrorMsg' })
  hi('@text.literal', { force = true, link = 'Special' })
  hi('@text.note', { force = true, link = 'MoreMsg' })
  hi('@text.reference', { force = true, link = 'Identifier' })
  hi('@text.title', { force = true, link = 'Title' })
  hi('@text.todo', { force = true, link = 'Todo' })
  hi('@text.uri', { force = true, link = 'Underlined' })
  hi('@text.warning', { force = true, link = 'WarningMsg' })

  -- Other

  hi('@diff.delta', { force = true, link = 'Changed' })
  hi('@diff.minus', { force = true, link = 'Removed' })
  hi('@diff.plus', { force = true, link = 'Added' })

  hi('@symbol', { force = true, link = 'Keyword' })

  hi('@tag', { force = true, link = 'Tag' })
  hi('@tag.attribute', { force = true, link = '@tag' })
  hm('@tag.builtin',
    { force = true, link = '@tag', bold = true })
  hi('@tag.delimiter', { force = true, link = '@punctuation' })

  -- Source: `:h lsp-semantic-highlight`

  -- hi('@lsp.type.class',                      { })
  hi('@lsp.type.class', { force = true, link = 'Structure' })
  hi('@lsp.type.comment', { force = true, link = '@comment' })
  hi('@lsp.type.decorator', { force = true, link = '@function' })
  hi('@lsp.type.enum', { force = true, link = '@type' })
  hi('@lsp.type.enumMember', { force = true, link = '@constant' })
  hi('@lsp.type.event', { force = true, link = '@type' })
  hi('@lsp.type.function', { force = true, link = '@function' })
  hi('@lsp.type.interface', { force = true, link = '@type' })
  hi('@lsp.type.keyword', { force = true, link = '@keyword' })
  hi('@lsp.type.macro', { force = true, link = '@function.macro' })
  hi('@lsp.type.method', { force = true, link = '@function.method' })
  hi('@lsp.type.modifier', { force = true, link = '@type.qualifier' })
  hi('@lsp.type.namespace', { force = true, link = '@module' })
  hi('@lsp.type.number', { force = true, link = '@number' })
  hi('@lsp.type.operator', { force = true, link = '@operator' })
  hi('@lsp.type.parameter',
    { force = true, link = '@variable.parameter' })
  hi('@lsp.type.property', { force = true, link = '@property' })
  hi('@lsp.type.regexp', { force = true, link = '@string.regexp' })
  hi('@lsp.type.string', { force = true, link = '@string' })
  hi('@lsp.type.struct', { force = true, link = 'Structure' })
  hi('@lsp.type.type', { force = true, link = '@type' })
  hi('@lsp.type.typeParameter',
    { force = true, link = '@type.definition' })
  hi('@lsp.type.variable', { force = true, link = '@variable' })
  hi('@lsp.typemod.variable.readonly',
    { force = true, link = '@constant' })
  hm('@lsp.typemod.function.async',
    { force = true, link = '@function', bold = true })

  hi('@lsp.mod.defaultLibrary', {})
  hi("@lsp.typemod.function.defaultLibrary", { link = "@function.builtin" })
  hi("@lsp.typemod.method.defaultLibrary", { link = "@function.builtin" })
  hi("@lsp.typemod.variable.defaultLibrary", { link = "@variable.builtin" })
  hi('@lsp.mod.deprecated', { fg = p.base08, bg = nil })
  hi('@lsp.mod.documentation', { link = '@string.documentation' })

  -- TODO: integrate this https://github.com/eldritch-theme/eldritch.nvim/blob/master/lua/eldritch/groups.lua
  hi("@lsp.type.boolean", { link = "@boolean" })
  -- hi("@lsp.type.builtinType", { link = "@type.builtin" })
  hi("@lsp.type.deriveHelper", { link = "@attribute" })
  hi("@lsp.type.escapeSequence", { link = "@string.escape" })
  -- hi("@lsp.type.formatSpecifier", { link = "@markup.list" })
  -- hi("@lsp.type.generic", { link = "@variable" })
  hi("@lsp.type.selfKeyword", { link = "@variable.builtin" })
  hi("@lsp.type.selfTypeKeyword", { link = "@variable.builtin" })
  -- hi("@lsp.type.typeAlias", { link = "@type.def" })
  -- hi("@lsp.typemod.class.defaultLibrary", { link = "@type.builtin" })
  -- hi("@lsp.typemod.enum.defaultLibrary", { link = "@type.builtin" })
  -- hi("@lsp.typemod.enumMember.defaultLibrary", { link = "@constant.builtin" })
  hi("@lsp.typemod.function.defaultLibrary", { link = "@function.builtin" })
  hi("@lsp.typemod.keyword.injected", { link = "@keyword" })
  -- hi("@lsp.typemod.macro.defaultLibrary", { link = "@function.builtin" })
  -- hi("@lsp.typemod.method.defaultLibrary", { link = "@function.builtin" })
  -- hi("@lsp.typemod.operator.injected", { link = "@operator" })
  -- hi("@lsp.typemod.string.injected", { link = "@string" })
  -- -- hi("@lsp.typemod.struct.defaultLibrary", { link = "@type.builtin" })
  -- hi("@lsp.typemod.variable.callable", { link = "@function" })
  -- hi("@lsp.typemod.variable.injected", { link = "@variable" })
  -- hi("@lsp.typemod.variable.static", { link = "@constant" })
  -- hi("@lsp.type.namespace.python", { link = "@variable" })

  -- hi('@lsp.typemod',                 {})
  -- hi('@lsp.mod.abstract',                 {})
  -- hi('@lsp.mod.async',                    {})
  -- hi('@lsp.mod.declaration',              {})
  -- hi('@lsp.mod.definition',               {})
  -- hi('@lsp.mod.deprecated',               {})
  -- hi('@lsp.mod.modification',             {})
  -- hi('@lsp.mod.readonly',                 {})
  -- hi('@lsp.mod.static',                   {})

  -- hm('@lsp.mod.declaration',              { link = "@variable" })
  hi('@type.typescript', { link = "Normal" })

  hi('FlashLabel', { underline = true, bold = true, fg = '#ffffff' })

  hi('IndentBlanklineChar',
    { nocombine = true, ctermbg = nil, ctermfg = 8, bg = nil, fg = '#332E33' })
  hi('IndentBlanklineCharScope',
    {
      nocombine = true,
      ctermbg = nil,
      ctermfg = 8,
      bold = false,
      bg = nil,
      fg =
      '#474247'
    })

  hi('Todo', { force = true, link = 'MiniHipatternsTodo' })
  hi('@comment.todo', { force = true, link = 'MiniHipatternsTodo' })
  hi('NormalFloat', { force = true, link = 'Normal' })
  hi('FloatBorder', { force = true, link = 'Normal' })
  hi('FloatBorder', { force = true, link = 'Normal' })
  hi('NormalFloat', { force = true, link = 'Normal' })

  hi('DiagnosticFloatingError', { force = true, link = 'Normal' })
  hi('DiagnosticFloatingHint', { force = true, link = 'Normal' })
  hi('DiagnosticFloatingInfo', { force = true, link = 'Normal' })
  hi('DiagnosticFloatingWarn', { force = true, link = 'Normal' })
  hi('DiagnosticUnnecessary',
    { force = true, fg = p.base04, bg = nil, nocombine = false })

  hi('DiagnosticUnderlineError', { underline = true, sp = p.base0C })
  hi('DiagnosticUnderlineWarn', { underline = true, sp = p.base0D })
  hi('DiagnosticUnderlineHint', { underline = true, sp = p.base0F })
  hi('DiagnosticUnderlineInfo', { underline = true, sp = p.base0B })

  hi('WinSeparator', { force = true, link = 'Normal' })
  hi('WhichKeySeparator', { force = true, link = 'String' })
  hi('WhichKeyFloat', { force = true, link = 'Normal' })
  hi('WhichKeyBorder', { force = true, link = 'Normal' })
  hi('ZenBg', { force = true, link = 'Normal' })
  hi('LazyButton', { force = true, link = 'Comment' })
  hi('LazyButtonActive', { force = true, link = 'Normal' })
  hi('LazyH1', { force = true, link = 'Normal' })


  hi('LazyH1', { force = true, link = 'Normal' })

  hi('Pmenu', { fg = p.base05, bg = p.base00, sp = nil, force = true })
  hi('PmenuExtra', { fg = p.base05, bg = p.base00, sp = nil, force = true })
  hi('PmenuKind', { fg = p.base05, bg = p.base00, sp = nil, force = true })
  hi('PmenuSbar', { fg = nil, bg = p.base01, sp = nil, force = true })
  hi('PmenuThumb', { fg = nil, bg = p.base07, sp = nil, force = true })
  hi('PmenuExtraSel',
    { fg = p.base05, bg = p.base00, reverse = true, sp = nil, force = true })
  hi('PmenuKindSel',
    { fg = p.base05, bg = p.base00, reverse = true, sp = nil, force = true })
  hi('PmenuSel',
    { fg = p.base05, bg = p.base00, reverse = true, sp = nil, force = true })
  hi('PmenuMatch',
    { fg = p.base05, bg = p.base00, bold = true, sp = nil, force = true })
  hi('PmenuMatchSel',
    { fg = p.base05, bg = p.base00, bold = true, reverse = true, sp = nil, force = true })

  hi('CmpItemAbbr', { fg = p.base05, bg = nil, sp = nil, force = true })
  hi('CmpItemAbbrDeprecated',
    { fg = p.base03, bg = nil, sp = nil, force = true })
  hi('CmpItemAbbrMatch',
    { fg = p.base0A, bg = nil, bold = true, sp = nil, force = true })
  hi('CmpItemAbbrMatchFuzzy',
    { fg = p.base0A, bg = nil, bold = true, sp = nil, force = true })
  hi('CmpItemKind', { fg = p.base0F, bg = p.base00, sp = nil, force = true })
  hi('CmpItemMenu', { fg = p.base05, bg = p.base00, sp = nil, force = true })

  hi('BlinkCmpLabelDescription', { force = true, link = 'Comment' })

  -- hi('MasonHeader', { force = true, fg = p.base00, bg = nil, nocombine = true })

  -- hi('@conditional',                      { force = true,     link = 'Conditional' })
  -- hi('@debug',                            { force = true,     link = 'Debug' })
  -- hi('@define',                           { force = true,     link = 'Define' })
  -- hi('@exception',                        { force = true,     link = 'Exception' })
  -- hi('@field',                            { force = true,     link = 'Identifier' })
  -- hi('@float',                            { force = true,     link = 'Float' })
  -- hi('@include',                          { force = true,     link = 'Include' })
  -- hi('@macro',                            { force = true,     link = 'Macro' })
  -- hi('@method',                           { force = true,     link = 'Function' })
  -- hi('@method.call',                      { force = true,     link = 'Function' })
  -- hi('@namespace',                        { force = true,     link = 'Identifier' })
  -- hi('@none',                             { force = true,     link = 'Normal' })
  -- hi('@preproc',                          { force = true,     link = 'PreProc' })
  -- hi('@repeat',                           { force = true,     link = 'Repeat' })
  -- hi('@storageclass',                     { force = true,     link = 'StorageClass' })
  -- hi('@structure',                        { force = true,     link = 'Structure' })

  -- stylua: ignore end
end

return M
