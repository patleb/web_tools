require('@@lib/ext_coffee/core_ext/all')

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
  'ujs:meta-click',
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
  ajax: (type, url, { status = 200, ...rest } = {}) => {
    const [event_name, handler] = Object.entries(rest)[0]
    xhr[type](url, (req, res) => {
      return res.status(status)
    })
    return new Promise((resolve) => {
      return Rails.ajax({ type, url, [event_name]: (...args) => {
        resolve(...args)
        handler(...args)
      }})
    })
  },
  click: (selector, { type = 'get', url, status = 200, headers = {}, body, skip, button, ctrlKey, altKey, shiftKey, metaKey, ...rest } = {}) => {
    const [event_name, handler] = Object.entries(rest)[0]
    const element = document.querySelector(selector)
    let skipped_event = true
    if (url) {
      xhr[type](url, (req, res) => {
        res = res.status(status)
        for (const [name, value] of Object.entries(headers)) {
          res = res.header(name, value)
        }
        return body ? res.body(body) : res
      })
    }
    if (skip) {
      dom.on_event({ [skip]: (event) => {
        skipped_event = false
      }})
    }
    return new Promise((resolve) => {
      dom.on_event({ [event_name]: (event) => {
        resolve(event)
        handler(event)
        if (skip) {
          assert.true(skipped_event)
          dom.off_event(skip)
        }
      }})
      let options = button != null ? { button }
        : ctrlKey  ? { ctrlKey }
        : altKey   ? { altKey }
        : shiftKey ? { shiftKey }
        : metaKey  ? { metaKey }
        : {}
      return element.click(options)
    })
  },
  submit: (selector, { type = 'post', url, status = 200, ...rest } = {}) => {
    const [event_name, handler] = Object.entries(rest)[0]
    const form = document.querySelector(selector).closest('form')
    if (url) {
      xhr[type](url, (req, res) => {
        return res.status(status)
      })
    }
    return new Promise((resolve) => {
      dom.on_event({ [event_name]: async (event) => {
        resolve(event)
        await tick()
        handler(event)
      }})
      return form.submit()
    })
  },
  change: (selector, { type = 'get', url, status = 200, ...rest } = {}) => {
    const [event_name, handler] = Object.entries(rest)[0]
    const option = document.querySelector(selector)
    const select = option.parentNode
    if (url) {
      xhr[type](url, (req, res) => {
        return res.status(status)
      })
    }
    return new Promise((resolve) => {
      dom.on_event({ [event_name]: (event) => {
        resolve(event)
        handler(event)
      }})
      option.selected = 'selected'
      return dom.fire('change', { target: select })
    })
  },
  assert_enabled: ({ target }, selector = null) => {
    const element = selector ? target.querySelector(selector) : target
    assert.nil(Rails.get(element, 'ujs:disabled'))
    assert.false(element.hasAttribute('disabled'))
  },
  assert_disabled: ({ target }, selector = null) => {
    const element = selector ? target.querySelector(selector) : target
    assert.true(Rails.get(element, 'ujs:disabled'))
    assert.nil(Rails.get(element, 'ujs:enable-with'))
    if(!element.matches(Rails.disableable_links)) {
      assert.true(element.hasAttribute('disabled'))
    }
  },
  assert_disabled_with: ({ target }, old_text, new_text, selector = null) => {
    const element = selector ? target.querySelector(selector) : target
    assert.true(Rails.get(element, 'ujs:disabled'))
    assert.equal(old_text, Rails.get(element, 'ujs:enable-with'))
    assert.equal(new_text, element.innerHTML)
    if(!element.matches(Rails.disableable_links)) {
      assert.true(element.hasAttribute('disabled'))
    }
  },
  assert_request: (event, method, url, body) => {
    const request = event.detail[0].req
    assert.equal(method.toUpperCase(), request._method)
    assert.equal(url, request._url.toString())
    if (body != null) {
      assert.equal(body, nav.get_params(request._body))
    }
  },
}

module.exports = rails
