import rails from './spec_helper'

describe('Rails UJS Remote', () => {
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

  describe('Form with "data-remote"', () => {
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
      const url = '/echo?user_name=john&user_data=value1'
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
      dom.$('#non-remote-form')[0].submit()
      await tick()
      assert.false(submitted)
      dom.off_event('ajax:before')
      dom.reset_submit()
    })

    it('should serialize form correctly', async () => {
      await rails.submit('#form-serialized', { url: '/echo', 'ajax:complete': (event) => {
        rails.assert_request(event, 'POST', '/echo', { textarea: 'textarea', 'checkbox[]': '1', radio: '0', 'select[]': ['1', '2', '4'] })
      }})
    })

    it('should not submit inputs inside disabled fieldset', async () => {
      await rails.submit('#form-disabled-fieldset', { url: '/echo', 'ajax:complete': (event) => {
        rails.assert_request(event, 'POST', '/echo', { description: 'A wise man' })
      }})
    })
  })
})
