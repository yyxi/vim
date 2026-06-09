local assert = require('luassert')
local utf8_validator = require('yyxi.utilities.utf8_validator')

local function bytes(...) return string.char(...) end

describe('yyxi.utilities.utf8_validator', function()
  it('accepts valid utf-8 sequences', function()
    assert.is_true(utf8_validator.validate('hello'))
    assert.is_true(utf8_validator.validate(bytes(0x00)))
    assert.is_true(utf8_validator.validate(bytes(0xC2, 0xA2)))
    assert.is_true(utf8_validator.validate(bytes(0xE2, 0x82, 0xAC)))
    assert.is_true(utf8_validator.validate(bytes(0xF0, 0x9F, 0x92, 0xA9)))
  end)

  it('returns the first invalid byte position for malformed sequences', function()
    local valid, position = utf8_validator.validate(bytes(0xC2))
    assert.is_false(valid)
    assert.equals(1, position)

    valid, position = utf8_validator.validate('ok' .. bytes(0xC0, 0xAF))
    assert.is_false(valid)
    assert.equals(3, position)

    valid, position = utf8_validator.validate(bytes(0xED, 0xA0, 0x80))
    assert.is_false(valid)
    assert.equals(1, position)

    valid, position = utf8_validator.validate(bytes(0xF4, 0x90, 0x80, 0x80))
    assert.is_false(valid)
    assert.equals(1, position)
  end)

  it('supports call syntax', function() assert.is_true(utf8_validator('hello')) end)
end)
