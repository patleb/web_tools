import turbolinks from '@@vendor/turbolinks/jest/spec_helper'

describe('Turbolinks Search form', () => {
  beforeEach(() => {
    turbolinks.setup('search_form')
  })

  afterEach(() => {
    dom.reset_document()
  })

  it('should go to location /search_form', async () => {
    await turbolinks.visit('search_form', { 'turbolinks:load': (event) => {
      turbolinks.assert_page(event, 'http://localhost/search_form', { title: 'Search form', action: 'replace' })
    }})
  })

  it('should visit the submitted query form', async () => {
    assert.total(2)
    await turbolinks.click_button('[name="commit"]', (event) => {
      assert.equal('http://localhost/search_form?search=input&commit=button#search', event.data.url)
      assert.equal('advance', event.data.action)
    })
  })
})
