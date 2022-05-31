import rails from './spec_helper'

describe('Rails UJS Disable', () => {
  beforeEach(() => {
    dom.setup_document(fixture.html('disable'))
    dom.stub_submit()
    dom.stub_click()
  })

  afterEach(async () => {
    await tick()
    dom.reset_document()
    dom.reset_submit()
    dom.reset_click()
  })

  it('should disable form input fields with "data-disable" attribute', async () => {
    assert.total(16)
    dom.on_event({ 'ajax:beforeSend': (event) => {
      rails.assert_enabled(event, 'input[type=text]')
    }})
    dom.on_event({ 'ajax:send': (event) => {
      rails.assert_disabled(event, 'input[type=text]')
    }})
    dom.on_event({ 'ajax:success': (event) => {
      const data = nav.get_params(event.detail[2].req._body)
      assert.equal({ user_name: 'john', user_bio: 'born, lived, died.' }, data)
      rails.assert_disabled(event, 'input[type=text]')
      rails.assert_disabled({ target: dom.$('textarea[data-disable]')[0] })
    }})
    await rails.submit('form[data-remote]', { url: '/echo', 'ajax:complete': (event) => {
      rails.assert_enabled(event, 'input[type=text]')
      rails.assert_enabled({ target: dom.$('textarea[data-disable]')[0] })
    }})
  })

  it('should disable non-remote form input field with "data-disable" attribute', async () => {
    assert.total(5)
    rails.assert_enabled({ target: dom.$('input[type=submit]')[0] })
    await rails.submit('input[type=submit]', { 'submit': (event) => {
      rails.assert_disabled(event, 'input[type=submit]')
    }})
  })

  it('should disable non-remote link and replace inner text with "data-disable-with" attribute', async () => {
    assert.total(9)
    rails.assert_enabled({ target: dom.$('a[data-disable-with]')[0] })
    await rails.click('a[data-disable-with]', { 'click': (event) => {
      rails.assert_disabled_with(event, 'Click me', 'Processing...')
    }})
    await rails.click('a[data-disable-with]', { skip: 'click', 'ujs:everythingStopped': (event) => {
      rails.assert_disabled_with(event, 'Click me', 'Processing...')
    }})
  })

  it('should not prevent usage of "disabled" attribute', async () => {
    assert.total(3)
    await rails.click('a[data-disable]', { skip: 'click', 'ujs:everythingStopped': (event) => {
      assert.null(Rails.getData(event.target, 'ujs:disabled'))
      assert.true(event.target.hasAttribute('disabled'))
    }})
  })

  it('should not disable link with insignificant clicks', async () => {
    assert.total(4)
    await rails.click('a[data-disable-with]', { metaKey: true, 'ujs:meta-click': (event) => {
      rails.assert_enabled(event)
    }})
    await rails.click('a[data-disable-with]', { button: 1, 'ujs:meta-click': (event) => {
      rails.assert_enabled(event)
    }})
  })

  it('should disable button with "data-disable" attribute', async () => {
    assert.total(8)
    rails.assert_enabled({ target: dom.$('button[data-remote]')[0] })
    dom.on_event({ 'ajax:before': (event) => {
      rails.assert_disabled(event)
    }})
    await rails.click('button[data-remote]', { skip: 'click', url: '/echo', 'ajax:complete': (event) => {
      rails.assert_enabled(event)
    }})
  })

  it('should re-enable when "ajax:before" event is cancelled', async () => {
    assert.total(6)
    dom.on_event({ 'ajax:before': (event) => {
      rails.assert_disabled(event)
      event.preventDefault()
    }})
    await rails.click('button[data-remote]', { skip: 'ajax:beforeSend', 'ajax:stopped': (event) => {
      rails.assert_enabled(event)
    }})
  })

  it('should re-enable when "ajax:beforeSend" event is cancelled', async () => {
    assert.total(6)
    dom.on_event({ 'ajax:beforeSend': (event) => {
      rails.assert_disabled(event)
      event.preventDefault()
    }})
    await rails.click('button[data-remote]', { skip: 'ajax:send', 'ajax:stopped': (event) => {
      rails.assert_enabled(event)
    }})
  })

  it('should re-enable when "ajax:error" event is triggered', async () => {
    assert.total(5)
    dom.on_event({ 'ajax:error': (event) => {
      rails.assert_disabled(event)
    }})
    await rails.click('button[data-remote]', { url: '/echo', status: 500, 'ajax:complete': (event) => {
      rails.assert_enabled(event)
    }})
  })

  it('should re-enable when "pageshow" event is triggered', () => {
    assert.total(5)
    const target = dom.$('button[data-remote]')[0]
    Rails.disableElement(target)
    rails.assert_disabled({ target })
    dom.on_event({ 'pageshow': (event) => {
      rails.assert_enabled({ target })
    }})
    dom.off_event('pageshow')
  })

  it('should not enable elements for XHR redirects', async () => {
    assert.total(6)
    dom.on_event({ 'ajax:before': (event) => {
      rails.assert_disabled(event)
    }})
    await rails.click('button[data-remote]', { url: '/echo', headers: { 'X-Xhr-Redirect': '/home' }, 'ajax:complete': (event) => {
      rails.assert_disabled(event)
    }})
  })
})
