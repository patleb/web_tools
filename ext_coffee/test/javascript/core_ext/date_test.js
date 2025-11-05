import './spec_helper'

const create_date = (year, month, day, hour, minute, second) => {
  let date = new Date(Date.UTC(year, month - 1, day, hour, minute, second))
  date = date.toLocaleString('en-US', { timeZone: 'GMT' })
  return new Date(Date.parse(date))
}

describe('Date', () => {
  beforeAll(() => {
    dom.fire('DOMContentLoaded')
  })

  test('#is_a', () => {
    assert.true(Date.current().is_a(Date))
    assert.false(Date.current().is_a(Object))
  })

  test('#eql', () => {
    assert.true(Date.current().eql(Date.current()))
    assert.false(Date.current().eql(create_date(2001, 1, 1, 1, 1, 1)))
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
