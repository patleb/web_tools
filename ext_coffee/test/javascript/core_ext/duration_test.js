import '@@lib/ext_coffee/jest/core_ext/spec_helper'

describe('Duration', () => {
  test('#to_i, #to_s, #to_h', () => {
    assert.equal(-2, Duration.new('-PT2S').to_i())
    assert.equal(38994811, Duration.new('P1Y2M3W4DT5H6M7S').to_i())
    assert.equal({ sign: 1, years: 1, months: 2, weeks: 3,days: 4, hours: 5, minutes: 6, seconds: 7 }, Duration.new(38994811).to_h())
    let scales = {
      year:   'P1Y',
      month:  'P1M',
      week:   'P1W',
      day:    'P1D',
      hour:   'PT1H',
      minute: 'PT1M',
      second: 'PT1S',
    }
    for (const [scale, definiton] of Object.entries(scales)) {
      let duration = new Duration(definiton)
      let parts = { sign: 1, years: 0, months: 0, weeks: 0, days: 0, hours: 0, minutes: 0, seconds: 0 }
      parts[`${scale}s`] = 1
      assert.equal(Duration.SECONDS[scale], duration.to_i())
      assert.equal(definiton, duration.to_s())
      assert.equal(parts, duration.to_h())
    }
  })

  test('#add', () => {
    assert.equal(2 * Duration.SECONDS.month + 3 * Duration.SECONDS.hour, 2.0.months().add(3.0.hours()).to_i())
  })

  test('#presence', () => {
    let duration = new Duration({})
    assert.equal(duration, duration.presence())
  })
})
