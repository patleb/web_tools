import turbolinks from './spec_helper'

describe('Turbolinks Visit', () => {
  beforeEach(() => {
    turbolinks.setup('visit')
  })

  afterEach(() => {
    window.reset_document()
  })

  it('should go to location /visit', async () => {
    await turbolinks.visit('visit', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/visit', { title: 'Turbolinks', h1: 'Visit' })
    })
  })

  it('should programmatically visit a same-origin location', async () => {
    turbolinks.on_event('turbolinks:before-visit', (event) => {
      assert.equal('http://localhost/one', event.data.url)
    })
    turbolinks.on_event('turbolinks:visit', (event) => {
      assert.equal('http://localhost/one', event.data.url)
    })
    await turbolinks.visit('one', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/one', { title: 'One' })
    })
  })

  describe('Reload', () => {
    beforeAll(() => {
      delete window.location
    })

    afterAll(() => {
      window.reset_location()
    })

    it('should programmatically visit a cross-origin location falls back to window.location', async () => {
      assert.total(4)
      assert.undefined(window.location)
      turbolinks.on_event('turbolinks:before-visit', (event) => {
        assert.equal('about:blank', event.data.url)
      })
      await turbolinks.visit_reload('about:blank', (event) => {
        assert.equal('about:blank', event.data.url)
        assert.equal('about:blank', window.location.toString())
      })
    })
  })

  it('should prevent navigation on canceling a visit event', async () => {
    assert.total(3)
    turbolinks.on_event('turbolinks:before-visit', (event) => {
      assert.equal('http://localhost/one', event.data.url)
      event.preventDefault()
    })
    await turbolinks.click_cancel('#same-origin-link', (event) => {
      assert.equal(true, event.data.prevented)
      assert.equal('http://localhost/visit', window.location.href)
    })
  })

  it('should keep navigation by history not cancelable', async () => {
    let event_locations = {}
    await turbolinks.click('#same-origin-link', { event_name: 'turbolinks:visit' }, (event) => {
      assert.equal('http://localhost/one', event.data.url)
    })
    turbolinks.on_event('turbolinks:before-visit', (event) => {
      event_locations.before_visit = event.data.url
    })
    turbolinks.on_event('turbolinks:visit', (event) => {
      event_locations.visit = event.data.url
    })
    await turbolinks.back('visit', {}, (event) => {
      assert.undefined(event_locations.before_visit)
      assert.equal(event_locations.visit, event.data.url)
    })
  })
})
