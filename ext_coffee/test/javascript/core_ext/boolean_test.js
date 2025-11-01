import './spec_helper'

describe('Boolean', () => {
  test('#blank, #eql', () => {
    assert.true(false.blank())
    assert.true(false.eql(false))
    assert.false(false.eql(true))
  })
})
