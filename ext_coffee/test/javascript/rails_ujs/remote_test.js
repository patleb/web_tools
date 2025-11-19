import rails from '@@vendor/rails-ujs/jest/spec_helper'
import '@@vendor/turbolinks/all'

describe('Rails UJS Remote', () => {
  beforeAll(() => {
    Turbolinks.supported = false
  })

  afterAll(() => {
    Turbolinks.supported = true
  })

  beforeEach(() => {
    dom.setup_document(fixture.html('remote'))
  })

  afterEach(() => {
    dom.reset_document()
  })

  it('should fire on a link with "data-remote" attribute and merge existing params', async () => {
    const url = 'http://localhost/echo?data3=value3&data1=value1&data2=value2'
    await rails.click('a[data-remote]', { url, 'ajax:complete': (event) => {
      rails.assert_request(event, 'GET', url)
    }})
  })

  it('should fire on a meta click of a link with "data-params" attribute', async () => {
    const url = 'http://localhost/echo?data3=value3&data1=value1&data2=value2'
    await rails.click('a[data-remote]', { url, metaKey: true, 'ajax:complete': (event) => {
      rails.assert_request(event, 'GET', url)
    }})
  })

  it('should fire on a button with "data-remote" and post "data-method" attributes and keep params in body', async () => {
    const url = '/echo?data3=value3'
    await rails.click('button[data-remote]', { type: 'post', url, 'ajax:complete': (event) => {
      rails.assert_request(event,'POST', url, { data1: 'value1', data2: 'value2' })
    }})
  })

  it('should not fire on a disabled link', async () => {
    dom.stub_click()
    await rails.click('a[data-remote][disabled]', { skip: 'ajax:before', 'click': (event) => {}})
    await tick()
    dom.reset_click()
  })

  it('should fire on changing a select option with "data-remote" attribute', async () => {
    const url = '/echo?user_data=optionValue2&data1=value1'
    await rails.change('#select option[value=optionValue2]', { url , 'ajax:complete': (event) => {
      rails.assert_request(event, 'GET', url)
    }})
  })

  it('should fire with current location on changing a select option without "data-url" attribute', async () => {
    const url = 'http://localhost/?user_data=optionValue2&data1=value1'
    await rails.change('#select-no-url option[value=optionValue2]', { url , 'ajax:complete': (event) => {
      rails.assert_request(event, 'GET', url)
    }})
  })

  describe('Form with "data-remote" attribute', () => {
    afterEach(async () => {
      await tick()
    })

    it('should submit with "method" only attributes', async () => {
      await rails.submit('#my-remote-form', { url: '/echo', 'ajax:complete': (event) => {
        rails.assert_request(event, 'POST', '/echo', { user_name: 'john' })
      }})
    })

    it('should submit include inputs in a fieldset', async () => {
      await rails.submit('#form-with-fieldset', { url: '/echo', 'ajax:complete': (event) => {
        rails.assert_request(event, 'POST', '/echo', { user_name: 'john', 'items[]': 'Item' })
      }})
    })

    it('should submit without "method" as GET and input with matching "form" attribute', async () => {
      const url = '/echo?user_name=john&user_data=value1#anchor'
      await rails.submit('#form-with-form-attributes', { type: 'get', url, 'ajax:complete': (event) => {
        rails.assert_request(event, 'GET', url)
      }})
    })

    it('should by clicking button with matching "form" attribute and use "formaction" and "formmethod" attributes', async () => {
      await rails.click('#form-with-buttons button[value=value2]', { type: 'post', url: '/echo', 'ajax:complete': (event) => {
        rails.assert_request(event, 'POST', '/echo', { user_name: 'john', user_data: 'value2' })
      }})
    })

    it('should not submit with ajax if "data-remote" is false', async () => {
      dom.stub_submit()
      let submitted = false
      dom.on_event({ 'ajax:before': (event) => {
        submitted = true
      }})
      dom.find('#non-remote-form').submit()
      await tick()
      assert.false(submitted)
      dom.off_event('ajax:before')
      dom.reset_submit()
    })

    it('should serialize form correctly', async () => {
      const url = '/echo?stripped=false'
      await rails.submit('#form-serialized', { url, 'ajax:complete': (event) => {
        rails.assert_request(event, 'POST', url, { textarea: 'textarea', 'checkbox[]': '1', radio: '0', 'select[]': ['1', '2', '4'] })
      }})
    })

    it('should not submit inputs inside disabled fieldset', async () => {
      await rails.submit('#form-disabled-fieldset', { url: '/echo', 'ajax:complete': (event) => {
        rails.assert_request(event, 'POST', '/echo', { description: 'A wise man' })
      }})
    })

    it('should allow blank "action"', async () => {
      const url = 'http://localhost/'
      await rails.submit('#blank-action', { url, 'ajax:before_send': (event) => {
        assert.equal(url, event.detail[1].url)
        event.preventDefault()
      }})
    })

    it('should allow blank "formaction"', async () => {
      const url = 'http://localhost/'
      await rails.click('#blank-formaction button[type="submit"]', { 'ajax:before_send': (event) => {
        assert.equal(url, event.detail[1].url)
        event.preventDefault()
      }})
    })
  })

  it('should run javascript when "data-type" attribute is empty or "script"', async () => {
    const url = 'http://localhost/echo'
    const body = fixture.read('ajax.js')
    const size = document.documentElement.outerHTML.length
    await rails.click('#ajax-script', { url, body, headers: { 'content-type': 'text/javascript' }, 'ajax:complete': (event) => {
      assert.equal(1, window.ajax_count)
      assert.equal(size, document.documentElement.outerHTML.length)
    }})
  })

  it('should parse JSON when "data-type" attribute is "json"', async () => {
    const url = 'http://localhost/echo'
    const body = fixture.json('ajax')
    await rails.click('#ajax-json', { url, body, headers: { 'content-type': 'application/json' }, 'ajax:success': (event) => {
      assert.equal(body, event.detail[0])
    }})
  })

  it('should parse HTML when "data-type" attribute is "html" and response is a full page', async () => {
    const url = 'http://localhost/echo'
    const body = fixture.html('ajax_page')
    await rails.click('#ajax-page-html', { url, body, headers: { 'content-type': 'text/html' }, 'ajax:success': (event) => {
      const page = new DOMParser().parseFromString(body, 'text/html')
      assert.equal(page, event.detail[0])
    }})
  })

  it('should not parse HTML when "data-type" attribute is "html" and response is a partial page', async () => {
    const url = 'http://localhost/echo'
    const body = fixture.html('ajax_partial')
    await rails.click('#ajax-partial-html', { url, body, headers: { 'content-type': 'text/html' }, 'ajax:success': (event) => {
      const partial = new DOMParser().parseFromString(body, 'text/html').body
      assert.equal(partial, event.detail[0])
    }})
  })

  it('should detect cross-domain request', async () => {
    await rails.click('#cross-domain', { 'ajax:before_send': (event) => {
      assert.true(event.detail[1].crossDomain)
      event.preventDefault()
    }})
  })

  describe('Turbolinks', () => {
    beforeAll(() => {
      Turbolinks.supported = true
    })

    it('should execute a turbolinks visit', async () => {
      const url = '/echo'
      const redirect = 'http://localhost/success'
      const headers = { 'content-type': 'text/html', 'X-Xhr-Redirect': redirect }
      const body = fixture.html('ajax_page')
      await rails.click('#turbolinks [type="submit"]', { type: 'post', url, body, headers, 'turbolinks:load': (event) => {
        assert.equal(redirect, window.location.href)
        assert.equal('Ajax page', document.querySelector('title').innerHTML)
      }})
    })
  })
})
