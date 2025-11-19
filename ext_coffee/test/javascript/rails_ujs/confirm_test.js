import rails from '@@vendor/rails-ujs/jest/spec_helper'

const old_confirm = window.confirm
let confirm_message = null
let confirm_count = 0

describe('Rails UJS Confirm', () => {
  beforeEach(() => {
    dom.setup_document(fixture.html('confirm'))
  })

  afterEach(() => {
    dom.reset_document()
    window.confirm = old_confirm
    confirm_message = null
    confirm_count = 0
  })

  it('should click on a link with data-confirm attribute and confirm yes', async () => {
    window.confirm = (message) => { confirm_message = message; return true }
    assert.total(2)
    dom.on_event({ 'confirm:complete': (event) => {
      assert.true(event.detail[0])
    }})
    await rails.click('a[data-confirm]', { url: 'http://localhost/echo', 'ajax:success': (event) => {
      assert.equal('Are you absolutely sure?', confirm_message)
    }})
  })

  it('should click on a button with data-confirm attribute and confirm yes', async () => {
    window.confirm = (message) => { confirm_message = message; return true }
    assert.total(2)
    dom.on_event({ 'confirm:complete': (event) => {
      assert.true(event.detail[0])
    }})
    await rails.click('button[data-confirm]', { url: '/echo', 'ajax:success': (event) => {
      assert.equal('Are you absolutely sure?', confirm_message)
    }})
  })

  it('should click on a button with data-confirm attribute and confirm no', async () => {
    window.confirm = (message) => { confirm_message = message; return false }
    await rails.click('button[data-confirm]', { skip: 'ajax:before_send', 'confirm:complete': (event) => {
      assert.false(event.detail[0])
    }})
  })

  it('should click on a link with data-confirm attribute and confirm no', async () => {
    window.confirm = (message) => { confirm_message = message; return false }
    await rails.click('a[data-confirm]', { skip: 'ajax:before_send', 'confirm:complete': (event) => {
      assert.false(event.detail[0])
    }})
  })

  it('should click on a button with data-confirm attribute confirm error', async () => {
    window.confirm = (message) => { confirm_message = message; throw 'some random error' }
    await rails.click('button[data-confirm]', { skip: 'ajax:before_send', 'confirm:complete': (event) => {
      assert.false(event.detail[0])
    }})
  })

  it('should click on a submit button with form and data-confirm attributes and confirm no', async () => {
    window.confirm = (message) => { confirm_message = message; return false }
    await rails.click('input[type=submit][form]', { skip: 'ajax:before_send', 'confirm:complete': (event) => {
      assert.false(event.detail[0])
    }})
  })

  it('should bind to confirm event of a link and return false', async () => {
    window.confirm = (message) => { confirm_message = message; return false }
    await rails.click('a[data-confirm]', { skip: 'confirm:complete', 'confirm': (event) => {
      event.preventDefault()
      assert.nil(confirm_message)
    }})
  })

  it('should bind to confirm event of a button and return false', async () => {
    window.confirm = (message) => { confirm_message = message; return false }
    await rails.click('button[data-confirm]', { skip: 'confirm:complete', 'confirm': (event) => {
      event.preventDefault()
      assert.nil(confirm_message)
    }})
  })

  it('should bind to confirm:complete event of a link and return false', async () => {
    window.confirm = (message) => { confirm_message = message; return true }
    await rails.click('a[data-confirm]', { skip: 'ajax:before_send', 'confirm:complete': (event) => {
      event.preventDefault()
      assert.not.nil(event)
      assert.equal('Are you absolutely sure?', confirm_message)
    }})
  })

  it('should bind to confirm:complete event of a button and return false', async () => {
    window.confirm = (message) => { confirm_message = message; return true }
    await rails.click('button[data-confirm]', { skip: 'ajax:before_send', 'confirm:complete': (event) => {
      event.preventDefault()
      assert.not.nil(event)
      assert.equal('Are you absolutely sure?', confirm_message)
    }})
  })

  it('should confirm only once a button inside a form', async () => {
    window.confirm = (message) => { confirm_count++; return true }
    await rails.click('form > button[data-confirm]', { 'ajax:before': (event) => {
      event.preventDefault()
      assert.equal(1, confirm_count)
    }})
  })

  it('should also trigger a confirm when clicking on the children of a link', async () => {
    window.confirm = (message) => { confirm_message = message; return true }
    assert.total(2)
    dom.on_event({ 'confirm:complete': (event) => {
      assert.true(event.detail[0])
    }})
    await rails.click('a[data-confirm] > strong', { url: 'http://localhost/echo', 'ajax:success': (event) => {
      assert.equal('Are you absolutely sure?', confirm_message)
    }})
  })

  it('should not trigger a confirm when clicking on the children of a disabled button', async () => {
    window.confirm = (message) => { confirm_message = message; return false }
    let skipped_event = true
    dom.on_event({ 'click': (event) => {
      skipped_event = false
    }})
    document.querySelector('button[data-confirm][disabled] > strong').click()
    await tick()
    assert.true(skipped_event)
    dom.off_event('click')
  })

  it('should click on a link with data-confirm attribute with custom confirm handler and confirm yes', async () => {
    window.confirm = (message) => { confirm_message = message; return true }

    const old_rails_confirm = Rails.confirm
    let element
    Rails.confirm = (message, e) => { confirm_message = message; element = e; return true }

    assert.total(3)
    dom.on_event({ 'confirm:complete': (event) => {
      assert.true(event.detail[0])
    }})
    await rails.click('a[data-confirm]', { url: 'http://localhost/echo', 'ajax:success': (event) => {
      assert.equal('Are you absolutely sure?', confirm_message)
      assert.equal(element, document.querySelector('a[data-confirm'))
    }})

    Rails.confirm = old_rails_confirm
  })
})
