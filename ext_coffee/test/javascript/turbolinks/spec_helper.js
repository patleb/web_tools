import '@@vendor/rails-ujs/all'
import '@@vendor/turbolinks/all'

const events = [
  'DOMContentLoaded',
  'hashchange',
  'popstate',
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
  'turbolinks:search',
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

global.pretty_events_log = () => window.events_log.map(([type, data]) => `${type} -- ${data ? JSON.stringify(data): ''}`)

beforeAll(() => {
  fixture.set_root('ext_coffee/test/fixtures/files/turbolinks')
  for (const event_name of events) {
    addEventListener(event_name, (event) => {
      window.events_log.push([event.type, event.data])
    }, false)
  }
})

afterAll(() => {
  fixture.reset_root()
})

beforeEach(() => {
  window.events_log = []
  xhr.setup()
})

afterEach(() => {
  xhr.teardown()
})

const old_click_bubbled = Turbolinks.controller.click_bubbled.bind(Turbolinks.controller)
Turbolinks.controller.click_bubbled = function (event) {
  let bubbled = !!old_click_bubbled(event)
  if (branches.click_only) {
    event.data = { bubbled }
    Turbolinks.dispatch('turbolinks:click-only', event)
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
    Turbolinks.dispatch('turbolinks:visit-reload', { data: { url: new URL(location).toString() } })
    return result
  } else if (branches.click_cancel) {
    let prevented = !old_visit(location, options)
    Turbolinks.dispatch('turbolinks:click-cancel', { data: { prevented } })
    return prevented
  } else {
    return old_visit(location, options)
  }
}

const old_defer = Turbolinks.defer
const old_requestAnimationFrame = window.requestAnimationFrame

function listen_on(event_name, event_count, handler) {
  let countdown = event_count
  addEventListener(event_name, function eventListener(event) {
    if (--countdown === 0) {
      removeEventListener(event_name, eventListener, false)
    }
    handler(event, event_count - countdown - 1)
  }, false)
}

function navigate(direction, { event_name = 'turbolinks:load', event_count = 1 } = {}, asserts) {
  return new Promise((resolve) => {
    listen_on(event_name, event_count, (event) => {
      resolve(event)
      asserts(event)
    })
    return window.history[direction]()
  })
}

const turbolinks = {
  setup: (location) => {
    let state = { turbolinks: { restoration_id: Turbolinks.controller.restoration_id } }
    window.history.replaceState(state, '', `http://localhost/${location}`)
    Turbolinks.controller.location = Turbolinks.Location.wrap(window.location)
    dom.setup_document(fixture.html(location))
    Turbolinks.clearCache()
    Turbolinks.dispatch('DOMContentLoaded')
  },
  setup_no_defer: () => {
    Turbolinks.defer = (callback) =>  callback()
    window.requestAnimationFrame = (callback) => callback()
  },
  reset_defer: () => {
    Turbolinks.defer = old_defer
    window.requestAnimationFrame = old_requestAnimationFrame
  },
  back: (...args) => {
    return navigate('back', ...args)
  },
  forward: (...args) => {
    return navigate('forward', ...args)
  },
  visit_reload_and_assert: (location, { action = 'advance' } = {}) => {
    assert.total(4)
    assert.null(window.location)
    turbolinks.on_event('turbolinks:before-visit', {}, (event) => {
      assert.equal(location, event.data.url)
    })
    turbolinks.visit_reload(location, { action }, (event) => {
      assert.equal(location, event.data.url)
      assert.equal(location, window.location.toString())
    })
  },
  visit_reload: (location, { action = 'advance', event_count = 1 } = {}, asserts) => {
    return new Promise((resolve) => {
      listen_on('turbolinks:visit-reload', event_count, (event) => {
        branches.visit_reload = false
        resolve(event)
        asserts(event)
      })
      branches.visit_reload = true
      return Turbolinks.visit(location, { action })
    })
  },
  visit: (location, { event_name = 'turbolinks:load', event_count = 1, status = 200, action = 'advance' } = {}, asserts) => {
    let origin_url = `http://localhost/${location}`
    let anchor = url.get_anchor(origin_url)
    if (anchor != null) {
      origin_url = origin_url.replace(`#${anchor}`, '')
    }
    if (anchor == null || window.location && origin_url !== window.location.href || action === 'replace') {
      let name = location.replace(`#${anchor}`, '')
      xhr.get(origin_url, async (req, res) => {
        await tick()
        return res.status(status).header('content-type', 'text/html').body(fixture.html(name))
      })
    }
    return new Promise((resolve) => {
      listen_on(event_name, event_count, (event) => {
        resolve(event)
        asserts(event)
      })
      return Turbolinks.visit(location, { action })
    })
  },
  click_cancel: (selector, asserts) => {
    let link = document.querySelector(selector)
    return new Promise((resolve) => {
      listen_on('turbolinks:click-cancel', 1, (event) => {
        branches.click_cancel = false
        resolve(event)
        asserts(event)
      })
      branches.click_cancel = true
      return link.click()
    })
  },
  click_only: (selector, asserts) => {
    let link = document.querySelector(selector)
    return new Promise((resolve) => {
      listen_on('turbolinks:click-only', 1, (event) => {
        branches.click_only = false
        resolve(event)
        asserts(event)
      })
      branches.click_only = true
      return Turbolinks.dispatch('click', { target: link, cancelable: true })
    })
  },
  click_reload: (selector, asserts) => {
    let responded = false
    turbolinks.on_event('turbolinks:request-end', {}, (event) => {
      responded = true
    })
    let rendered = false
    turbolinks.on_event('turbolinks:render', {}, (event) => {
      rendered = true
    })
    return turbolinks.click(selector, {}, (event) => {
      event.responded = responded
      event.rendered = rendered
      asserts(event)
    })
  },
  click: (selector, { event_name = 'turbolinks:load', event_count = 1, status = 200, headers = {} } = {}, asserts) => {
    let link = document.querySelector(selector)
    let shadow_root = link.shadowRoot
    if (shadow_root) {
      link = shadow_root.querySelector('a')
    }
    let origin_url = link.href
    let action = link.getAttribute('data-turbolinks-action')
    let anchor = url.get_anchor(origin_url)
    if (anchor != null) {
      origin_url = origin_url.replace(`#${anchor}`, '')
    }
    if (anchor == null || window.location && origin_url !== window.location.href || action === 'replace') {
      let name = origin_url.replace(/^http:\/\/localhost\//, '')
      xhr.get(origin_url, (req, res) => {
        res = res.status(status).header('content-type', 'text/html')
        for(const [name, value] of Object.entries(headers)) {
          res = res.header(name, value)
        }
        return res.body(fixture.html(name))
      })
    }
    return new Promise((resolve) => {
      listen_on(event_name, event_count, (event) => {
        resolve(event)
        asserts(event)
      })
      return link.click()
    })
  },
  on_event: (event_name, { event_count = 1 } = {}, asserts = (e) => {}) => {
    listen_on(event_name, event_count, (event, index) => {
      asserts(event, index)
    })
  },
  assert_reload: (event, href, { action = 'advance' } = {}) => {
    assert.true(event.responded)
    assert.false(event.rendered)
    assert.equal(action, Turbolinks.controller.current_visit.action)
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
