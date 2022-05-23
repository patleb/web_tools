import './override'
import '@@vendor/rails-ujs/all'

beforeAll(() => {
  fixture.set_root('ext_coffee/test/fixtures/files/rails_ujs')
})

afterAll(() => {
  fixture.reset_root()
})

beforeEach(() => {
  xhr.setup()
})

afterEach(() => {
  xhr.teardown()
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
  click: (selector, { url, event_name = 'ajax:complete', status = 200 } = {}, handler) => {
    let element = document.querySelector(selector)
    if (url) {
      xhr.get(url, async (req, res) => {
        return res.status(status)
      })
    }
    return new Promise((resolve) => {
      dom.on_event(event_name, {}, (event) => {
        resolve(event)
        handler(event)
      })
      return dom.click(element)
    })
  },
}

module.exports = rails
