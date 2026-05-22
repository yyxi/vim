local strings = require('yyxi.utilities.strings')

describe('yyxi.utilities.strings', function()
  it(
    'trims surrounding whitespace',
    function() assert.equals('value', strings.trim('  value  ')) end
  )

  it('detects empty or whitespace-only strings', function()
    assert.is_true(strings.is_blank(''))
    assert.is_true(strings.is_blank('  \t  '))
    assert.is_false(strings.is_blank('value'))
  end)
end)
