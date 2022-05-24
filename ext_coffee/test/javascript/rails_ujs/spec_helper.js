import './override'
import '@@vendor/rails-ujs/all'

const events = [
  'DOMContentLoaded',
  'ajax:before',
  'ajax:beforeSend',
  'ajax:send',
  'ajax:stopped',
  'ajax:success',
  'ajax:error',
  'ajax:complete',
  'confirm',
  'confirm:complete',
  'rails:attachBindings',
  'ujs:everythingStopped',
]

beforeAll(() => {
  fixture.set_root('ext_coffee/test/fixtures/files/rails_ujs')
  dom.setup_events_log(events)
})

afterAll(() => {
  fixture.reset_root()
})

beforeEach(() => {
  xhr.setup()
})

afterEach(() => {
  xhr.teardown()
  dom.reset_events_log()
})

const rails = {
  ajax: (type, url, { event_name = 'complete', status = 200 } = {}, handler) => {
    xhr[type](url, (req, res) => {
      return res.status(status)
    })
    return new Promise((resolve) => {
      return Rails.ajax({ type, url, [event_name]: (...args) => {
          resolve(...args)
          handler(...args)
      } })
    })
  },
  click: (selector, { type = 'get', url, event_name = 'ajax:complete', status = 200, skip } = {}, handler) => {
    let element = document.querySelector(selector)
    let skipped_event = true
    if (url) {
      xhr[type](url, async (req, res) => {
        return res.status(status)
      })
    }
    if (skip) {
      dom.on_event(skip, {}, (event) => {
        skipped_event = false
      })
    }
    return new Promise((resolve) => {
      dom.on_event(event_name, {}, (event) => {
        resolve(event)
        handler(event)
        if (skip) {
          assert.true(skipped_event)
          dom.off_event(skip)
        }
      })
      return element.click()
    })
  },
}

module.exports = rails
