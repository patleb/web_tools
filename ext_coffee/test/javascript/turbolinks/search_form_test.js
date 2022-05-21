import turbolinks from './spec_helper'

describe('Turbolinks Search form', () => {
  beforeEach(() => {
    turbolinks.setup('search_form')
  })

  afterEach(() => {
    dom.reset_document()
  })

  it('should go to location /search_form', async () => {
    await turbolinks.visit('search_form', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/search_form', { title: 'Search form', action: 'replace' })
    })
  })

  it('should visit the submitted query form', async () => {
    assert.total(3)
    let url = 'http://localhost/search_form?page=1&search=input&commit=button#search'
    await turbolinks.on_event('turbolinks:search', {}, (event) => {
      assert.equal(url, event.data.url)
    })
    await turbolinks.on_event('turbolinks:before-visit', {}, (event) => {
      event.preventDefault()
      assert.equal(url, event.data.url)
      assert.equal('advance', event.data.action)
    })
    let button = document.querySelector('[name="commit"]')
    Turbolinks.controller.focus(button)
    button.click()
  })
})
