require('@@lib/ext_coffee/core_ext/all')
require('@@vendor/turbolinks/all')

const events = [
  'DOMContentLoaded',
  'hashchange',
  'popstate',
  'ujs:everythingStopped',
  'turbolinks:before-cache',
  'turbolinks:before-render',
  'turbolinks:before-visit',
  'turbolinks:cache',
  'turbolinks:click',
  'turbolinks:load',
  'turbolinks:reload',
  'turbolinks:render',
  'turbolinks:request-start',
  'turbolinks:request-end',
  'turbolinks:scroll-only',
  'turbolinks:submit',
  'turbolinks:visit',
].concat([
  'turbolinks:click-cancel',
  'turbolinks:click-only',
  'turbolinks:visit-reload',
])

const branches = {
  click_cancel: false,
  click_only: false,
  visit_reload: false,
}

beforeAll(() => {
  fixture.set_root('ext_coffee/test/fixtures/files/turbolinks')
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

const old_click_bubbled = Turbolinks.controller.click_bubbled.bind(Turbolinks.controller)
Turbolinks.controller.click_bubbled = function (event) {
  let bubbled = !!old_click_bubbled(event)
  if (branches.click_only) {
    event.data = { bubbled }
    dom.fire('turbolinks:click-only', event)
  }
}

const old_visit = Turbolinks.controller.visit.bind(Turbolinks.controller)
Turbolinks.controller.visit = function (location, options = {}) {
  if (branches.click_only) {
    return true
  } else if (branches.visit_reload) {
    let result = old_visit(location, options)
    if (!location.match(/^http:/) && location !== 'about:blank') {
      location = `http://localhost/${location}`
    }
    dom.fire('turbolinks:visit-reload', { data: { url: new URL(location).toString() } })
    return result
  } else if (branches.click_cancel) {
    let prevented = !old_visit(location, options)
    dom.fire('turbolinks:click-cancel', { data: { prevented } })
    return prevented
  } else {
    return old_visit(location, options)
  }
}

const old_defer = Function.defer
const old_requestAnimationFrame = window.requestAnimationFrame

function navigate(direction, rest = {}) {
  const [event_name, handler] = Object.entries(rest)[0]
  return new Promise((resolve) => {
    dom.on_event({ [event_name]: (event, index) => {
      resolve(event)
      handler(event, index)
    }})
    return window.history[direction]()
  })
}

const turbolinks = {
  setup: (location) => {
    let state = { turbolinks: { restoration_id: Turbolinks.controller.restoration_id } }
    window.history.replaceState(state, '', `http://localhost/${location}`)
    Turbolinks.controller.location = Turbolinks.Location.wrap(window.location)
    dom.setup_document(fixture.html(location))
    Turbolinks.clear_cache()
    dom.fire('DOMContentLoaded')
  },
  setup_no_defer: () => {
    Function.defer = (callback) =>  callback()
    window.requestAnimationFrame = (callback) => callback()
  },
  reset_defer: () => {
    Function.defer = old_defer
    window.requestAnimationFrame = old_requestAnimationFrame
  },
  back: (rest) => {
    return navigate('back', rest)
  },
  forward: (rest) => {
    return navigate('forward', rest)
  },
  visit_reload_and_assert: (location) => {
    assert.total(4)
    assert.nil(window.location)
    dom.on_event({ 'turbolinks:before-visit': (event) => {
      assert.equal(location, event.data.url)
    }})
    turbolinks.visit_reload(location, (event) => {
      assert.equal(location, event.data.url)
      assert.equal(location, window.location.toString())
    })
  },
  visit_reload: (location, handler) => {
    return new Promise((resolve) => {
      dom.on_event({ 'turbolinks:visit-reload': (event, index) => {
        branches.visit_reload = false
        resolve(event)
        handler(event, index)
      }})
      branches.visit_reload = true
      return Turbolinks.visit(location, { action: 'advance' })
    })
  },
  visit: (location, { action = 'advance', ...rest } = {}) => {
    const [event_name, handler] = Object.entries(rest)[0]
    let origin_url = `http://localhost/${location}`
    let anchor = nav.get_anchor(origin_url)
    if (anchor != null) {
      origin_url = origin_url.replace(`#${anchor}`, '')
    }
    if (anchor == null || window.location && origin_url !== window.location.href || action === 'replace') {
      let name = location.replace(`#${anchor}`, '')
      xhr.get(origin_url, async (req, res) => {
        await tick()
        return res.status(200).header('content-type', 'text/html').body(fixture.html(name))
      })
    }
    return new Promise((resolve) => {
      dom.on_event({ [event_name]: (event, index) => {
        resolve(event)
        handler(event, index)
      }})
      return Turbolinks.visit(location, { action })
    })
  },
  click_button: (selector, handler) => {
    let button = document.querySelector(selector)
    return new Promise((resolve) => {
      dom.on_event({ 'turbolinks:before-visit': (event) => {
        event.preventDefault()
        resolve(event)
        handler(event)
      }})
      button.focus()
      return button.click()
    })
  },
  click_cancel: (selector, handler) => {
    let link = document.querySelector(selector)
    return new Promise((resolve) => {
      dom.on_event({ 'turbolinks:click-cancel': (event) => {
        branches.click_cancel = false
        resolve(event)
        handler(event)
      }})
      branches.click_cancel = true
      return link.click()
    })
  },
  click_only: (selector, handler) => {
    let link = document.querySelector(selector)
    return new Promise((resolve) => {
      dom.on_event({ 'turbolinks:click-only': (event) => {
        branches.click_only = false
        resolve(event)
        handler(event)
      }})
      branches.click_only = true
      return dom.fire('click', { target: link, cancelable: true })
    })
  },
  click_reload: (selector, handler) => {
    let responded = false
    dom.on_event({ 'turbolinks:request-end': (event) => {
      responded = true
    }})
    let rendered = false
    dom.on_event({ 'turbolinks:render': (event) => {
      rendered = true
    }})
    return turbolinks.click(selector, { 'turbolinks:load': (event) => {
      event.responded = responded
      event.rendered = rendered
      handler(event)
    }})
  },
  click: (selector, { status = 200, headers = {}, ...rest } = {}) => {
    const [event_name, handler] = Object.entries(rest)[0]
    let link = document.querySelector(selector)
    let shadow_root = link.shadowRoot
    if (shadow_root) {
      link = shadow_root.querySelector('a')
    }
    let origin_url = link.href
    let action = link.getAttribute('data-turbolinks-action')
    let anchor = nav.get_anchor(origin_url)
    if (anchor != null) {
      origin_url = origin_url.replace(`#${anchor}`, '')
    }
    if (anchor == null || window.location && origin_url !== window.location.href || action === 'replace') {
      let name = origin_url.replace(/^http:\/\/localhost\//, '')
      xhr.get(origin_url, (req, res) => {
        res = res.status(status).header('content-type', 'text/html')
        for (const [name, value] of Object.entries(headers)) {
          res = res.header(name, value)
        }
        return res.body(fixture.html(name))
      })
    }
    return new Promise((resolve) => {
      dom.on_event({ [event_name]: (event, index) => {
        resolve(event)
        handler(event, index)
      }})
      return link.click()
    })
  },
  assert_reload: (event, href) => {
    assert.true(event.responded)
    assert.false(event.rendered)
    assert.equal('advance', Turbolinks.controller.current_visit.action)
    assert.equal(href, event.data.url)
    assert.called(window.location.reload)
  },
  assert_page: (event, href, { title, h1 = title, action = 'advance' } = {}) => {
    let anchor = href.split('#')[1]
    if (anchor) {
      assert.called(Element.prototype.scrollIntoView)
    } else {
      assert.called(window.scrollTo)
    }
    assert.equal(action, Turbolinks.controller.current_visit.action)
    assert.equal(href, event.newURL || event.data.url)
    assert.equal(href, window.location.href)
    assert.equal(title, document.querySelector('title').innerHTML)
    assert.equal(h1, document.querySelector('h1').innerHTML)
  },
  assert_click_event: (event, { bubbled }) => {
    assert.equal(bubbled, event.data.bubbled)
  },
}

module.exports = turbolinks
