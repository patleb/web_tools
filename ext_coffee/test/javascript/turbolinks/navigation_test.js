import turbolinks from './spec_helper'

describe('Turbolinks Navigation', () => {
  beforeEach(() => {
    turbolinks.setup('navigation')
  })

  afterEach(() => {
    window.reset_document()
  })

  it('should go to location /navigation', async () => {
    await turbolinks.visit('navigation', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/navigation', { title: 'Turbolinks', h1: 'Navigation' })
    })
  })

  it('should follow a same-origin unannotated link', async () => {
    await turbolinks.click('#same-origin-unannotated-link', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/one', { title: 'One' })
    })
  })

  it('should follow a same-origin data-turbolinks-action=replace link', async () => {
    await turbolinks.click('#same-origin-replace-link', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/one', { title: 'One', action: 'replace' })
    })
  })

  it('should not follow a same-origin data-turbolinks=false link', async () => {
    await turbolinks.click_only('#same-origin-false-link', (event) => {
      turbolinks.assert_click_event(event, { bubbled: false })
    })
  })

  it('should not follow a same-origin unannotated link inside a data-turbolinks=false container', async () => {
    await turbolinks.click_only('#same-origin-unannotated-link-inside-false-container', (event) => {
      turbolinks.assert_click_event(event, { bubbled: false })
    })
  })

  it('should follow a same-origin data-turbolinks=true link inside a data-turbolinks=false container', async () => {
    await turbolinks.click_only('#same-origin-true-link-inside-false-container', (event) => {
      turbolinks.assert_click_event(event, { bubbled: true })
    })
  })

  it('should follow a same-origin anchored link', async () => {
    await turbolinks.click('#same-origin-anchored-link', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/one#element-id', { title: 'One' })
    })
  })

  it('should follow a same-origin link to named anchor', async () => {
    await turbolinks.click('#same-origin-anchored-link-named', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/one#named-anchor', { title: 'One' })
    })
  })

  it('should not follow a cross-origin unannotated link', async () => {
    await turbolinks.click_only('#cross-origin-unannotated-link', (event) => {
      turbolinks.assert_click_event(event, { bubbled: false })
    })
  })

  it('should not follow a same-origin [target] link', async () => {
    await turbolinks.click_only('#same-origin-targeted-link', (event) => {
      turbolinks.assert_click_event(event, { bubbled: false })
    })
  })

  it('should not follow a same-origin [download] link', async () => {
    await turbolinks.click_only('#same-origin-download-link', (event) => {
      turbolinks.assert_click_event(event, { bubbled: false })
    })
  })

  it('should follow a same-origin link inside an SVG element', async () => {
    await turbolinks.click_only('#same-origin-link-inside-svg-element', (event) => {
      turbolinks.assert_click_event(event, { bubbled: true })
    })
  })

  it('should not follow a cross-origin link inside an SVG element', async () => {
    await turbolinks.click_only('#cross-origin-link-inside-svg-element', (event) => {
      turbolinks.assert_click_event(event, { bubbled: false })
    })
  })

  it('should click the back button', async () => {
    await turbolinks.click('#same-origin-unannotated-link', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/one', { title: 'One' })
    })
    await turbolinks.back('navigation', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/navigation', { title: 'Turbolinks', h1: 'Navigation', action: 'restore' })
    })
  })

  it('should click the forward button', async () => {
    await turbolinks.click('#same-origin-unannotated-link', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/one', { title: 'One' })
    })
    await turbolinks.back('navigation', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/navigation', { title: 'Turbolinks', h1: 'Navigation', action: 'restore' })
    })
    await turbolinks.forward('one', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/one', { title: 'One', action: 'restore' })
    })
  })
})
