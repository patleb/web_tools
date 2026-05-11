import '@@lib/ext_coffee/jest/core_ext/spec_helper'

describe('Boolean', () => {
  test('#blank_, #eql_, #presence_', () => {
    assert.true(false.blank_())
    assert.true(false.eql_(false))
    assert.false(false.eql_(true))
    assert.true(true.presence_())
    assert.nil(false.presence_())
  })
})
