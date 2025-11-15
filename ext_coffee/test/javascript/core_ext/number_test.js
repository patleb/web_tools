import '@@lib/ext_coffee/jest/core_ext/spec_helper'

describe('Number', () => {
  test('#presence, #blank, #eql, #to_b, #to_i, #to_date, #is_integer, #is_finite, #even, #odd, #zero', () => {
    assert.nil(NaN.presence())
    assert.true(NaN.blank())
    let number = 0
    assert.equal(number, number.presence())
    assert.true(number.zero())
    assert.false(number.blank())
    assert.true(number.eql(0))
    assert.false(number.eql(1))
    assert.false(number.to_b())
    assert.equal(new Date(0), number.to_date())
    assert.true(number.is_integer())
    number = 1
    assert.equal(number, number.presence())
    assert.false(number.zero())
    assert.true(number.to_b())
    assert.equal(new Date(1000), number.to_date())
    assert.true(number.is_integer())
    assert.false(number.even())
    assert.true(number.odd())
    number = 1.23
    assert.equal(1, number.to_i())
    assert.true(number.is_finite())
    assert.false(number.is_integer())
    assert.false(Infinity.is_finite())
    number = 2
    assert.true(number.even())
    assert.false(number.odd())
    assert.false((3).even())
    assert.true((3).odd())
  })

  test('#to_s', () => {
    Number.METRIC_PREFIX.each((prefix, i) => {
      assert.equal(
        prefix === 'null' ? '16.123':`16.123 ${prefix}`,
        (16.123 * 10 ** Number.METRIC_EXPONENT[i]).to_s('metric', 3)
      )
    })
  })

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

  test('#seconds, #minutes, #hours, #days, #weeks, #days, #hours, #minutes, #seconds', () => {
    for (const [scale, seconds] of Object.entries(Duration.SECONDS)) {
      let result = 1[scale]().to_h().reject((k, v) => v.zero())
      let expect = { sign: 1, [scale.pluralize()]: 1 }
      assert.equal(expect, result)
      assert.equal(3.45 * seconds, 3.45[scale.pluralize()]().to_i())
    }
  })

  test('#times', () => {
    assert.equal([0, 1, 2], 3.0.times(i => i))
  })
})
