import turbolinks from './spec_helper'

describe('Turbolinks Anchor', () => {
  beforeEach(() => {
    turbolinks.setup('anchor')
  })

  afterEach(() => {
    dom.reset_document()
  })

  it('should go to location /anchor', async () => {
    await turbolinks.visit('anchor', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/anchor', { title: 'Anchor' })
    })
  })

  it('should not follow anchor on same-page', async () => {
    await turbolinks.click('a[href="#main"]', { event_name: 'hashchange' }, (event) => {
      assert.equal('main', url.get_anchor(event.newURL))
    })
    await turbolinks.back({ event_name: 'hashchange' }, (event) => {
      assert.null(url.get_anchor(event.newURL))
    })
    await turbolinks.forward({ event_name: 'hashchange' }, (event) => {
      assert.equal('main', url.get_anchor(event.newURL))
    })
    let doms = 0, loads = 0, pops = 0, hashes = 0, total = 0
    events_log.forEach(([name, data]) => {
      switch(name){
      case 'DOMContentLoaded': doms++; break
      case 'turbolinks:load': loads++; break
      case 'popstate': pops++; break
      case 'hashchange': hashes++
      }
      total++
    })
    assert.equal(total, doms + loads + pops + hashes)
    assert.equal(1, doms)
    assert.equal(1, loads)
    assert.equal(3, pops)
    assert.equal(3, hashes)
  })

  describe('Reload', () => {
    beforeAll(() => {
      url.delete_location()
    })

    afterAll(() => {
      url.reset_location()
    })

    it('should not visit anchor on same-page', async () => {
      await turbolinks.visit_reload_and_assert('http://localhost/anchor#main')
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
