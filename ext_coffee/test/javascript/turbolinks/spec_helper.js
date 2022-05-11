import '@@vendor/rails-ujs/all'
import '@@vendor/turbolinks/all'

beforeAll(() => {
  fixture.set_root('ext_coffee/test/fixtures/files/turbolinks')
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

Turbolinks.controller.old_clickBubbled = Turbolinks.controller.clickBubbled
Turbolinks.controller.clickBubbled = function (event) {
  let bubbled = !!Turbolinks.controller.old_clickBubbled(event)
  event.data = { bubbled }
  Turbolinks.dispatch('turbolinks:click-only', event)
}

Turbolinks.controller.old_visit = Turbolinks.controller.visit
Turbolinks.controller.visit = function (location, options = {}) {
  if (Turbolinks.controller.click_only) {
    return true
  } else if (Turbolinks.controller.visit_reload) {
    let result = Turbolinks.controller.old_visit(location, options)
    Turbolinks.dispatch('turbolinks:visit-reload', { data: { url: new URL(location).toString() } })
    return result
  } else if (Turbolinks.controller.click_cancel) {
    let prevented = !Turbolinks.controller.old_visit(location, options)
    Turbolinks.dispatch('turbolinks:click-cancel', { data: { prevented } })
    return prevented
  } else {
    return Turbolinks.controller.old_visit(location, options)
  }
}

Turbolinks.controller.old_startVisitToLocationWithAction = Turbolinks.controller.startVisitToLocationWithAction
Turbolinks.controller.startVisitToLocationWithAction = function (location, ...args) {
  if (Turbolinks.controller.visit_reload) {
    let result = Turbolinks.old_startVisitToLocationWithAction(location, ...args)
    Turbolinks.dispatch('turbolinks:visit-reload', { data: { url: new URL(location).toString() } })
    return result
  } else {
    return Turbolinks.controller.old_startVisitToLocationWithAction(location, ...args)
  }
}

function navigate(direction, location, { event_name = 'turbolinks:load' } = {}, asserts) {
  return new Promise((resolve) => {
    function after(event) {
      removeEventListener(event_name, after)
      resolve(event)
      asserts(event)
    }
    addEventListener(event_name, after)
    return window.history[direction]()
  })
}

const turbolinks = {
  setup: (location) => {
    let state = { turbolinks: { restorationIdentifier: Turbolinks.controller.restorationIdentifier } }
    window.history.replaceState(state, null, `/${location}`)
    Turbolinks.controller.location = Turbolinks.Location.wrap(window.location)
    window.setup_document(fixture.html(location))
    Turbolinks.clearCache()
    Turbolinks.dispatch('DOMContentLoaded')
  },
  back: (...args) => {
    return navigate('back', ...args)
  },
  forward: (...args) => {
    return navigate('forward', ...args)
  },
  visit_reload: (location, asserts) => {
    return new Promise((resolve) => {
      function after(event) {
        removeEventListener('turbolinks:visit-reload', after)
        delete Turbolinks.controller.visit_reload
        resolve(event)
        asserts(event)
      }
      addEventListener('turbolinks:visit-reload', after)
      Turbolinks.controller.visit_reload = true
      return Turbolinks.visit(location)
    })
  },
  visit: (location, { event_name = 'turbolinks:load', status = 200, action = 'advance' } = {}, asserts) => {
    let origin_url = `http://localhost/${location}`
    xhr.get(origin_url, (req, res) => {
      return res.status(status).body(fixture.html(location))
    })
    return new Promise((resolve) => {
      function after(event) {
        removeEventListener(event_name, after)
        resolve(event)
        asserts(event)
      }
      addEventListener(event_name, after)
      return Turbolinks.visit(location, { action })
    })
  },
  click_cancel: (selector, asserts) => {
    let link = document.querySelector(selector)
    return new Promise((resolve) => {
      function after(event) {
        removeEventListener('turbolinks:click-cancel', after)
        delete Turbolinks.controller.click_cancel
        resolve(event)
        asserts(event)
      }
      addEventListener('turbolinks:click-cancel', after)
      Turbolinks.controller.click_cancel = true
      return link.click()
    })
  },
  click_reload: (selector, asserts) => {
    let responded = false
    turbolinks.on_event('turbolinks:request-end', (event) => {
      responded = true
    })
    let rendered = false
    turbolinks.on_event('turbolinks:render', (event) => {
      rendered = true
    })
    return turbolinks.click(selector, {}, (event) => {
      event.responded = responded
      event.rendered = rendered
      asserts(event)
    })
  },
  click: (selector, { event_name = 'turbolinks:load', status = 200 } = {}, asserts) => {
    let link = document.querySelector(selector)
    let origin_url = link.href
    let anchor = origin_url.split('#')[1]
    if (anchor != null) {
      origin_url = origin_url.replace(`#${anchor}`, '')
    }
    let location = origin_url.replace(/^http:\/\/localhost\//, '')
    xhr.get(origin_url, (req, res) => {
      return res.status(status).body(fixture.html(location))
    })
    return new Promise((resolve) => {
      function after(event) {
        removeEventListener(event_name, after)
        resolve(event)
        asserts(event)
      }
      addEventListener(event_name, after)
      return link.click()
    })
  },
  click_only: (selector, asserts) => {
    let link = document.querySelector(selector)
    return new Promise((resolve) => {
      function after(event) {
        removeEventListener('turbolinks:click-only', after)
        delete Turbolinks.controller.click_only
        resolve(event)
        asserts(event)
      }
      addEventListener('turbolinks:click-only', after)
      Turbolinks.controller.click_only = true
      return Turbolinks.dispatch('click', { target: link, cancelable: true })
    })
  },
  on_event: (event_name, asserts = (e) => {}) => {
    function after(event) {
      removeEventListener(event_name, after)
      asserts(event)
    }
    addEventListener(event_name, after)
  },
  assert_reload: (event, href, { action = 'advance' } = {}) => {
    assert.equal(true, event.responded)
    assert.equal(false, event.rendered)
    assert.equal(action, Turbolinks.controller.currentVisit.action)
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
    assert.equal(action, Turbolinks.controller.currentVisit.action)
    assert.equal(href, event.data.url)
    assert.equal(href, window.location.href)
    assert.equal(title, document.querySelector('title').innerHTML)
    assert.equal(h1, document.querySelector('h1').innerHTML)
  },
  assert_click_event: (event, { bubbled }) => {
    assert.equal(bubbled, event.data.bubbled)
  },
}

module.exports = turbolinks
