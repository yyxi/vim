local exclusions = require('yyxi.utilities.exclusions')

describe('yyxi.utilities.exclusions', function()
  it('returns fresh copies of reusable exclusion lists', function()
    local first = exclusions.transient_ui_filetypes()
    table.insert(first, 'mutated')

    assert.same(
      { 'cmp_menu', 'flash_prompt', 'noice', 'notify' },
      exclusions.transient_ui_filetypes()
    )
  end)

  it('builds plugin-specific lists from shared semantic groups', function()
    assert.same({ 'lazy', 'TelescopePrompt', 'vim' }, exclusions.autopairs_disabled_filetypes())
    assert.same({ 'lazy', 'TelescopePrompt' }, exclusions.which_key_disabled_filetypes())
    assert.same({
      'cmp_menu',
      'flash_prompt',
      'noice',
      'notify',
      'fugitive',
      'neo-tree',
      'qf',
    }, exclusions.cybu_excluded_filetypes())
  end)

  it('adds a focusability predicate to flash search exclusions', function()
    local flash = exclusions.flash_search_exclusions()

    assert.equals('cmp_menu', flash[1])
    assert.equals('function', type(flash[#flash]))
  end)
end)
