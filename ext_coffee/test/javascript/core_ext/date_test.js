import '@@lib/ext_coffee/jest/core_ext/spec_helper'

const create_date = (year, month, day, hour, minute, second) => {
  let date = new Date(Date.UTC(year, month - 1, day, hour, minute, second))
  date = date.toLocaleString('en-US', { timeZone: 'GMT' })
  return new Date(Date.parse(date))
}

describe('Date', () => {
  beforeAll(() => {
    dom.fire('DOMContentLoaded')
  })

  test('.parse, .new', () => {
    let date = new Date(2013, 0, 1, 12, 0, 0)
    assert.equal(date, new Date(Date.parse('2013')))
    assert.equal(date, new Date(Date.parse('2013-01')))
    assert.equal(date, new Date(Date.parse('2013-01-01')))
    assert.equal(date, Date.new(2013))
    assert.equal(date, Date.new(2013, 0))
    assert.equal(date, Date.new(2013, 0, 1))
  })

  test('.leap', () => {
    assert.true(Date.leap(2012))
    assert.false(Date.leap(2013))
    assert.false(Date.leap(2014))
    assert.false(Date.leap(2015))
    assert.true(Date.leap(2016))
  })

  test('.week', () => {
    assert.equal(1, Date.week(2013, 1, 1))
    assert.equal(1, Date.week(2013, 1, 6))
    assert.equal(2, Date.week(2013, 1, 7))
    assert.equal(3, Date.week(2013, 1, 14))
    assert.equal(4, Date.week(2013, 1, 21))
    assert.equal(5, Date.week(2013, 1, 28))
    assert.equal(5, Date.week(2013, 1, 31))
    assert.equal(5, Date.week(2013, 2, 1))
    assert.equal(5, Date.week(2013, 2, 3))
    assert.equal(6, Date.week(2013, 2, 4))
    assert.equal(7, Date.week(2013, 2, 11))
    assert.equal(8, Date.week(2013, 2, 18))
    assert.equal(9, Date.week(2013, 2, 25))
    assert.equal(9, Date.week(2013, 2, 28))
    assert.equal(9, Date.week(2013, 3, 1))
    assert.equal(10, Date.week(2013, 3, 4))
    assert.equal(52, Date.week(2013, 12, 29))
    assert.equal(53, Date.week(2013, 12, 30))
    assert.equal(53, Date.week(2013, 12, 31))
    assert.equal(1, Date.week(2014, 1, 1))
  })

  test('#is_a', () => {
    assert.true(Date.current().is_a(Date))
    assert.false(Date.current().is_a(Object))
  })

  test('#eql', () => {
    assert.true(Date.current().eql(Date.current()))
    assert.false(Date.current().eql(create_date(2001, 1, 1, 1, 1, 1)))
  })

  test('#presence', () => {
    let date = Date.current()
    assert.equal(date, date.presence())
    assert.equal(date, new Date(date.valueOf()))
  })

  test('#advance', () => {
    let date = Date.current()
    assert.equal(date.to_i() + 123, date.advance(123).to_i())
    assert.equal(date.to_i() + 123, date.advance(Duration.new('PT123S')).to_i())
    assert.equal(date.to_i() + 123, date.advance({ seconds: 123 }).to_i())
  })

  test('#strftime', () => {
    const date_object = create_date(2001, 1, 1, 1, 1, 1)
    const dates = {
      'Jan 1, 2001': '%b %e, %Y',
      'January 1, 2001 at 1:01am GMT': '%B %e, %Y at %l:%M%P %Z',
    }
    for (const [date, format] of Object.entries(dates)) {
      assert.equal(date, date_object.strftime(format))
    }
  })
})
