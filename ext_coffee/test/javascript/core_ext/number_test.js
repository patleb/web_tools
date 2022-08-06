import './spec_helper'

describe('Number', () => {
  test('#round', () => {
    assert.equal(1, 0.5.round())
    assert.equal(-1, (-0.5).round())
    assert.equal(5.1, 5.12.round(1))
    assert.equal(-5.1, (-5.12).round(1))
    assert.equal(1.01, 1.005.round(2))
    assert.equal(39.43, 39.425.round(2))
    assert.equal(-1.01, (-1.005).round(2))
    assert.equal(-39.43, (-39.425).round(2))
    assert.equal(1260, 1262.48.round(-1))
    assert.equal(1300, 1262.48.round(-2))
    assert.equal(-1260, (-1262.48).round(-1))
    assert.equal(-1300, (-1262.48).round(-2))
    assert.equal(3e-52, 3e-52.round(-52))
  })

  test('#floor', () => {
    assert.equal(0, 1e-8.floor(2))
    assert.equal(5.1, 5.12.floor(1))
    assert.equal(-5.2, (-5.12).floor(1))
    assert.equal(2.26, 2.26.floor(2))
    assert.equal(18.15, 18.15.floor(2))
    assert.equal(-9.13, (-9.13).floor(2))
    assert.equal(-65.18, (-65.18).floor(2))
    assert.equal(1260, 1262.48.floor(-1))
    assert.equal(1200, 1262.48.floor(-2))
  })

  test('#ceil', () => {
    assert.equal(0.01, 1e-8.ceil(2))
    assert.equal(5.2, 5.12.ceil(1))
    assert.equal(-5.1, (-5.12).ceil(1))
    assert.equal(9.13, 9.13.ceil(2))
    assert.equal(65.18, 65.18.ceil(2))
    assert.equal(-2.26, (-2.26).ceil(2))
    assert.equal(-18.15, (-18.15).ceil(2))
    assert.equal(1270, 1262.48.ceil(-1))
    assert.equal(1300, 1262.48.ceil(-2))
  })

  test('#trunc', () => {
    assert.equal(5.1, 5.12.trunc(1))
    assert.equal(-5.1, (-5.12).trunc(1))
    assert.equal(2.26, 2.26.trunc(2))
    assert.equal(18.15, 18.15.trunc(2))
    assert.equal(-2.26, (-2.26).trunc(2))
    assert.equal(-18.15, (-18.15).trunc(2))
  })
})
