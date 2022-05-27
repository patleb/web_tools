import rails from './spec_helper'

describe('Rails UJS Disable', () => {
  beforeEach(() => {
    dom.setup_document(fixture.html('disable'))
  })

  afterEach(async () => {
    await tick()
    dom.reset_document()
  })

  it('should disable form input field with "data-disable" attribute', async () => {
    assert.total(rails.assert_disabled_count * 2 + rails.assert_enabled_count * 2)
    dom.on_event({ 'ajax:beforeSend': (event) => {
      rails.assert_enabled(event, 'input[type=text]')
    }})
    dom.on_event({ 'ajax:send': (event) => {
      rails.assert_disabled(event, 'input[type=text]')
    }})
    dom.on_event({ 'ajax:success': (event) => {
      rails.assert_disabled(event, 'input[type=text]')
    }})
    await rails.submit('form[data-remote]', { url: '/echo', 'ajax:complete': (event) => {
      rails.assert_enabled(event, 'input[type=text]')
    }})
  })

  describe('Submit', () => {
    beforeAll(() => {
      url.stub_submit()
    })

    afterAll(() => {
      url.reset_submit()
    })

    it('should disable non-remote form input field with "data-disable" attribute', async () => {
      assert.total(rails.assert_enabled_count + rails.assert_disabled_count)
      rails.assert_enabled({ target: document }, 'input[type=submit]')
      await rails.submit('input[type=submit]', { 'submit': (event) => {
        rails.assert_disabled(event, 'input[type=submit]')
      }})
    })
  })
})
