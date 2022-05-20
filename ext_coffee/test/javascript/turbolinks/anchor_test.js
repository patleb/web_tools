import turbolinks from './spec_helper'

describe('Turbolinks Anchor', () => {
  beforeEach(() => {
    turbolinks.setup('anchor')
  })

  afterEach(() => {
    dom.reset_document()
  })

  describe('No defer', () => {
    beforeEach(() => {
      turbolinks.setup_no_defer()
    })

    afterEach(() => {
      turbolinks.reset_defer()
    })

    it('should go to location /anchor', async () => {
      await turbolinks.visit('anchor', {}, (event) => {
        turbolinks.assert_page(event, 'http://localhost/anchor', { title: 'Anchor' })
      })
    })

    it('should follow anchor on same-page', async () => {
      await turbolinks.click('a[href="#main"]', { event_name: 'hashchange' }, (event) => {
        assert.equal('main', url.get_anchor(event.newURL))
      })
      await turbolinks.back({ event_name: 'hashchange' }, (event) => {
        assert.null(url.get_anchor(event.newURL))
      })
      await turbolinks.forward({ event_name: 'hashchange' }, (event) => {
        assert.equal('main', url.get_anchor(event.newURL))
      })
      let before_visits = 0, visits = 0, popstates = 0, hashchanges = 0, total = 0
      events_log.forEach(([name, data]) => {
        switch(name){
        case 'turbolinks:before-visit': before_visits++; break
        case 'turbolinks:visit': visits++; break
        case 'popstate': popstates++; break
        case 'hashchange': hashchanges++
        }
        total++
      })
      assert.equal(1, before_visits)
      assert.equal(2, visits)
      assert.equal(2, popstates)
      assert.equal(3, hashchanges)
      assert.equal(13, total)
    })
  })

  it('should visit anchor on same-page', async () => {
    await turbolinks.visit('http://localhost/anchor#main', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/anchor#main', { title: 'Anchor', action: 'restore' })
    })
  })

  it('should follow anchor on same-page with replace', async () => {
    await turbolinks.visit('anchor#main', { action: 'replace' }, (event) => {
      turbolinks.assert_page(event, 'http://localhost/anchor#main', { title: 'Anchor', action: 'replace' })
    })
    await turbolinks.click('#replace-with-same-page-anchor', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/anchor#main', { title: 'Anchor', action: 'replace' })
    })
  })
})
