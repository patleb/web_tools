import turbolinks from '@@vendor/turbolinks/jest/spec_helper'

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
      await turbolinks.visit('anchor', { 'turbolinks:load': (event) => {
        turbolinks.assert_page(event, 'http://localhost/anchor', { title: 'Anchor', action: 'replace' })
      }})
    })

    it('should follow anchor on same-page', async () => {
      await turbolinks.click('a[href="#main"]', { 'hashchange': (event) => {
        assert.equal('main', nav.get_anchor(event.newURL))
      }})
      await turbolinks.back({ 'hashchange': (event) => {
        assert.nil(nav.get_anchor(event.newURL))
      }})
      await turbolinks.forward({ 'hashchange': (event) => {
        assert.equal('main', nav.get_anchor(event.newURL))
      }})
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
      assert.equal(3, visits)
      assert.equal(2, popstates)
      assert.equal(3, hashchanges)
      assert.equal(18, total)
    })
  })

  it('should visit anchor on same-page', async () => {
    await turbolinks.visit('anchor#main', { 'hashchange': (event) => {
      turbolinks.assert_page(event, 'http://localhost/anchor#main', { title: 'Anchor' })
    }})
  })

  it('should follow same-anchor on same-page with replace', async () => {
    await turbolinks.visit('anchor#main', { 'hashchange': (event) => {
      turbolinks.assert_page(event, 'http://localhost/anchor#main', { title: 'Anchor' })
    }})
    await tick()
    await turbolinks.click('#replace-with-same-page-anchor', { 'hashchange': (event) => {
      turbolinks.assert_page(event, 'http://localhost/anchor#main', { title: 'Anchor', action: 'replace' })
    }})
  })

  it('should follow same-anchor on same-page without replace', async () => {
    await turbolinks.click('#no-history-same-page-anchor', { 'turbolinks:scroll-only': (event) => {
      assert.called(Element.prototype.scrollIntoView)
    }})
  })

  it('should not do anything if the same-page anchor is invalid', async () => {
    await turbolinks.visit('anchor#!', { 'hashchange': (event) => {
      assert.not.called(Element.prototype.scrollIntoView)
      assert.not.called(window.scrollTo)
      assert.equal('http://localhost/anchor#!', event.newURL)
    }})
  })
})
