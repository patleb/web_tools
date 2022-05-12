import turbolinks from './spec_helper'

describe('Turbolinks Async script', () => {
  beforeEach(() => {
    turbolinks.setup('async_script', { async: true })
  })

  afterEach(() => {
    window.reset_document()
  })

  it('should go to location /async_script', async () => {
    await turbolinks.visit('async_script', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/async_script', { title: 'Turbolinks', h1: 'Async script' })
    })
  })

  it('should not emit turbolinks:load when loaded asynchronously after DOMContentLoaded', async () => {
    assert.equal(0, window.events_log.length)
  })

  it('should follow a link when loaded asynchronously after DOMContentLoaded', async () => {
    await turbolinks.click('#async-link', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/async_script_2', { title: 'Turbolinks', h1: 'Async script 2' })
    })
  })
})
