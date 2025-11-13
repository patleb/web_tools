import '@@lib/ext_coffee/jest/core_ext/spec_helper'

describe('Boolean', () => {
  test('#blank, #eql, #presence', () => {
    assert.true(false.blank())
    assert.true(false.eql(false))
    assert.false(false.eql(true))
    assert.true(true.presence())
    assert.nil(false.presence())
  })
})
