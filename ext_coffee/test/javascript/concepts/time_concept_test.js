import concepts from '@@lib/ext_coffee/jest/concepts/spec_helper'
import rails from '@@vendor/rails-ujs/jest/spec_helper'

describe('Js.TimeConcept', () => {
  concepts.with_page('time', { root: 'ext_coffee' })

  it('should refresh _timezone input and format time elements', () => {
    const input = dom.find('#refresh > input')
    const time = dom.find('time')
    assert.nil(dom.find('#fresh > input'))
    assert.equal('0', input.value)
    assert.equal('2020-01-01 01:01:01 GMT', time.textContent)
    assert.equal('2020-01-01 01:01:01 GMT', time.getAttribute('aria-label'))
  })

  it('should refresh component elements as well', () => {
    assert.total(3)
    dom.on_event({ [Js.TimeConcept.FORMATTED]: ({ detail: { elements: [element] } }) => {
      assert.not.nil(element.closest('[data-uid]'))
      assert.equal('2020-01-01 01:01:01 GMT', element.textContent)
      assert.equal('2020-01-01 01:01:01 GMT', element.getAttribute('aria-label'))
    }})
    Js.Storage.set({ time: '2020-01-01 01:01:01 GMT' })
  })

  it('should add timezone to Rails.ajax request headers', async () => {
    assert.total(2)
    dom.on_event({ 'ajax:beforeSend': (event) => {
      event.preventDefault()
    }})
    await rails.ajax('get', '/', { 'complete': (xhr) => {
      assert.equal(-0, Time.zone)
      assert.equal(-0, xhr.req._headers['x-timezone'])
    }})
    dom.off_event('ajax:beforeSend')
  })
})
