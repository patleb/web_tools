import turbolinks from '@@vendor/turbolinks/jest/spec_helper'

describe('Turbolinks Visit', () => {
  beforeEach(() => {
    turbolinks.setup('visit')
  })

  afterEach(() => {
    dom.reset_document()
  })

  it('should go to location /visit', async () => {
    await turbolinks.visit('visit', { 'turbolinks:load': (event) => {
      turbolinks.assert_page(event, 'http://localhost/visit', { title: 'Turbolinks', h1: 'Visit', action: 'replace' })
    }})
  })

  it('should programmatically visit a same-origin location', async () => {
    dom.on_event({ 'turbolinks:before-visit': (event) => {
      assert.equal('http://localhost/one', event.data.url)
    }})
    dom.on_event({ 'turbolinks:visit': (event) => {
      assert.equal('http://localhost/one', event.data.url)
      assert.equal('advance', event.data.action)
    }})
    await turbolinks.visit('one', { 'turbolinks:load': (event) => {
      turbolinks.assert_page(event, 'http://localhost/one', { title: 'One' })
      assert.not.nil(event.data.info)
    }})
  })

  describe('Reload', () => {
    beforeEach(() => {
      nav.delete_location()
    })

    afterEach(() => {
      nav.reset_location()
    })

    it('should programmatically visit a cross-origin location falls back to window.location', async () => {
      await turbolinks.visit_reload_and_assert('about:blank')
    })

    it('should visit a location served with a non-HTML content type', async () => {
      await turbolinks.visit_reload_and_assert('http://localhost/image.svg')
    })

    it('should visit a same-page reload link', async () => {
      assert.nil(window.location)
      await turbolinks.visit_reload('?', (event) => {
        assert.equal('?', window.location.toString())
      })
    })
  })

  it('should prevent navigation on canceling a visit event', async () => {
    assert.total(3)
    dom.on_event({ 'turbolinks:before-visit': (event) => {
      assert.equal('http://localhost/one', event.data.url)
      event.preventDefault()
    }})
    await turbolinks.click_cancel('#same-origin-link', (event) => {
      assert.true(event.data.prevented)
      assert.equal('http://localhost/visit', window.location.href)
    })
  })

  it('should keep navigation by history not cancelable', async () => {
    let event_locations = {}
    let old_url = 'http://localhost/visit'
    let new_url = 'http://localhost/one'
    dom.on_event({ 'turbolinks:visit': (event) => {
      assert.equal(new_url, event.data.url)
    }})
    await turbolinks.click('#same-origin-link', { 'turbolinks:load': (event) => {
      assert.equal(new_url, event.data.url)
    }})
    dom.on_event({ 'turbolinks:before-visit': (event) => {
      event_locations.before_visit = event.data.url
    }})
    dom.on_event({ 'turbolinks:visit': (event) => {
      event_locations.visit = event.data.url
    }})
    await turbolinks.back({ 'turbolinks:load': (event) => {
      assert.nil(event_locations.before_visit)
      assert.equal(old_url, event.data.url)
      assert.equal(old_url, event_locations.visit)
    }})
  })
})
