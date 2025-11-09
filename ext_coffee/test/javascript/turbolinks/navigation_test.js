import turbolinks from '@@vendor/turbolinks/jest/spec_helper'

describe('Turbolinks Navigation', () => {
  beforeAll(() => {
    class CustomLinkElement extends HTMLElement {
      constructor() {
        super()
        this.attachShadow({ mode: 'open' })
      }
      connectedCallback() {
        this.shadowRoot.innerHTML = `
          <a href="${this.getAttribute('link')}">
            ${this.getAttribute('text')}
          </a>
        `
      }
    }
    window.customElements.define('custom-link-element', CustomLinkElement)
  })

  beforeEach(() => {
    turbolinks.setup('navigation')
    Turbolinks.controller.stop()
    Turbolinks.controller.progress_bar = new Turbolinks.ProgressBar
    Turbolinks.controller.start()
    assert.equal('123', document.head.querySelector('style').getAttribute('nonce'))
  })

  afterEach(() => {
    dom.reset_document()
  })

  it('should go to location /navigation', async () => {
    await turbolinks.visit('navigation', { 'turbolinks:load': (event) => {
      turbolinks.assert_page(event, 'http://localhost/navigation', { title: 'Turbolinks', h1: 'Navigation', action: 'replace' })
    }})
  })

  it('should follow a same-origin unannotated link', async () => {
    dom.on_event({ 'turbolinks:request-end': (event) => {
      assert.equal('123', event.data.xhr.req.header('X-Xhr-Nonce'))
    }})
    await turbolinks.click('#same-origin-unannotated-link', { headers: { 'X-Xhr-Nonce': '123' }, 'turbolinks:load': (event) => {
      assert.equal('en', document.documentElement.getAttribute('lang'))
      turbolinks.assert_page(event, 'http://localhost/one', { title: 'One' })
    }})
  })

  it('should follow a same-origin unannotated custom element link', async () => {
    await turbolinks.click('#custom-link-element', { 'turbolinks:load': (event) => {
      turbolinks.assert_page(event, 'http://localhost/one', { title: 'One' })
    }})
  })

  it('should follow a same-origin data-turbolinks-action=replace link', async () => {
    await turbolinks.click('#same-origin-replace-link', { 'turbolinks:load': (event) => {
      turbolinks.assert_page(event, 'http://localhost/one', { title: 'One', action: 'replace' })
    }})
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
    await turbolinks.click('#same-origin-anchored-link', { 'turbolinks:load': (event) => {
      turbolinks.assert_page(event, 'http://localhost/one#element-id', { title: 'One' })
    }})
  })

  it('should follow a same-origin link to named anchor', async () => {
    await turbolinks.click('#same-origin-anchored-link-named', { 'turbolinks:load': (event) => {
      turbolinks.assert_page(event, 'http://localhost/one#named-anchor', { title: 'One' })
    }})
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

  it('should follow the back button click', async () => {
    await turbolinks.click('#same-origin-unannotated-link', { 'turbolinks:load': (event) => {
      turbolinks.assert_page(event, 'http://localhost/one', { title: 'One' })
    }})
    await turbolinks.back({ 'turbolinks:load': (event) => {
      turbolinks.assert_page(event, 'http://localhost/navigation', { title: 'Turbolinks', h1: 'Navigation', action: 'restore' })
    }})
  })

  it('should follow the forward button click', async () => {
    await turbolinks.click('#same-origin-unannotated-link', { 'turbolinks:load': (event) => {
      turbolinks.assert_page(event, 'http://localhost/one', { title: 'One' })
    }})
    await turbolinks.back({ 'turbolinks:load': (event) => {
      turbolinks.assert_page(event, 'http://localhost/navigation', { title: 'Turbolinks', h1: 'Navigation', action: 'restore' })
    }})
    await turbolinks.forward({ 'turbolinks:load': (event) => {
      turbolinks.assert_page(event, 'http://localhost/one', { title: 'One', action: 'restore' })
    }})
  })

  it('should not follow a same-page reload link', async () => {
    await turbolinks.click_only('#same-origin-reloadable-link', (event) => {
      turbolinks.assert_click_event(event, { bubbled: false })
    })
  })

  it('should not follow a "data-remote" link', async () => {
    let turbolinks_click = false
    dom.on_event({ 'turbolinks:click': (event) => {
       turbolinks_click = true
    }})
    let data_remote_click = false
    await turbolinks.click('#data-remote-link', { 'ajax:complete': (event) => {
      data_remote_click = true
    }})
    await tick()
    assert.false(turbolinks_click)
    assert.true(data_remote_click)
    dom.off_event('turbolinks:click')
  })
})
