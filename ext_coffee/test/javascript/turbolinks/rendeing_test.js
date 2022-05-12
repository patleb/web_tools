import turbolinks from './spec_helper'

describe('Turbolinks Rendering', () => {
  beforeEach(() => {
    turbolinks.setup('rendering')
  })

  afterEach(() => {
    window.reset_document()
  })

  it('should go to location /rendering', async () => {
    await turbolinks.visit('rendering', {}, (event) => {
      turbolinks.assert_page(event, 'http://localhost/rendering', { title: 'Turbolinks', h1: 'Rendering' })
    })
  })

  it('should trigger before-render and render events', async () => {
    assert.total(4)
    let new_body
    turbolinks.on_event('turbolinks:before-render', (event) => {
      new_body = event.data.newBody
      assert.not_equal(document.body.innerHTML, new_body.innerHTML)
      assert.equal('One', new_body.querySelector('h1').innerHTML)
    })
    turbolinks.on_event('turbolinks:render', (event) => {
      assert.equal(document.body.innerHTML, new_body.innerHTML)
    })
    await turbolinks.click('#same-origin-link', {}, (event) => {
      assert.not_null(event)
    })
  })

  it('should trigger before-render and render events for error pages', async () => {
    assert.total(3)
    let new_body
    turbolinks.on_event('turbolinks:before-render', (event) => {
      new_body = event.data.newBody
      assert.not_equal(document.body.innerHTML, new_body.innerHTML)
    })
    turbolinks.on_event('turbolinks:render', (event) => {
      assert.equal(document.body.innerHTML, new_body.innerHTML)
    })
    await turbolinks.click('#nonexistent-link', { event_name: 'turbolinks:render', status: 404 }, (event) => {
      assert.equal('Not found', document.body.innerHTML.trim())
    })
  })

  describe('Reload', () => {
    beforeAll(() => {
      window.mock_location()
    })

    afterAll(() => {
      window.reset_location()
    })

    it('should reload when tracked elements change', async () => {
      await turbolinks.click_reload('#tracked-asset-change-link', (event) => {
        turbolinks.assert_reload(event, 'http://localhost/tracked_asset_change')
      })
    })

    it('should reload when turbolinks-visit-control setting is reload', async () => {
      await turbolinks.click_reload('#visit-control-reload-link', (event) => {
        turbolinks.assert_reload(event, 'http://localhost/visit_control_reload')
      })
    })
  })

  it('should accumulate asset elements in head', async () => {
    assert.total(2)
    let old_elements = dom.get_asset_elements()
    let new_elements
    await turbolinks.click('#additional-assets-link', { event_name: 'turbolinks:render' }, (event) => {
      new_elements = dom.get_asset_elements()
      assert.not_equal(old_elements, new_elements)
    })
    await turbolinks.back('rendering', { event_name: 'turbolinks:render' }, (event) => {
      old_elements = dom.get_asset_elements()
      assert.equal(new_elements, old_elements)
    })
  })

  it('should replace provisional elements in head', async () => {
    assert.null(document.querySelector('meta[name=test]'))
    let old_elements = dom.get_provisional_elements()
    let new_elements
    await turbolinks.click('#same-origin-link', { event_name: 'turbolinks:render' }, (event) => {
      new_elements = dom.get_provisional_elements()
      assert.not_equal(old_elements, new_elements)
      assert.not_null(document.querySelector('meta[name=test]'))
    })
    await turbolinks.back('rendering', { event_name: 'turbolinks:render' }, (event) => {
      old_elements = dom.get_provisional_elements()
      assert.not_equal(new_elements, old_elements)
      assert.null(document.querySelector('meta[name=test]'))
    })
  })

  it('should evaluate head script elements once', async () => {
    assert.null(window.headScriptEvaluationCount)
    await turbolinks.click('#head-script-link', { event_name: 'turbolinks:render' }, (event) => {
      assert.equal(1, window.headScriptEvaluationCount)
    })
    await turbolinks.back('rendering', { event_name: 'turbolinks:render' }, (event) => {
      assert.equal(1, window.headScriptEvaluationCount)
    })
    await turbolinks.click('#head-script-link', { event_name: 'turbolinks:render' }, (event) => {
      assert.equal(1, window.headScriptEvaluationCount)
    })
    delete window.headScriptEvaluationCount
  })

  it('should evaluate body script elements on each render', async () => {
    assert.null(window.bodyScriptEvaluationCount)
    await turbolinks.click('#body-script-link', { event_name: 'turbolinks:render' }, (event) => {
      assert.equal(1, window.bodyScriptEvaluationCount)
    })
    await turbolinks.back('rendering', { event_name: 'turbolinks:render' }, (event) => {
      assert.equal(1, window.bodyScriptEvaluationCount)
    })
    await turbolinks.click('#body-script-link', { event_name: 'turbolinks:render' }, (event) => {
      assert.equal(2, window.bodyScriptEvaluationCount)
    })
    delete window.bodyScriptEvaluationCount
  })

  it('should not evaluate data-turbolinks-eval=false scripts', async () => {
    assert.null(window.bodyScriptEvaluationCount)
    await turbolinks.click('#eval-false-script-link', { event_name: 'turbolinks:render' }, (event) => {
      assert.null(window.bodyScriptEvaluationCount)
    })
  })

  it('should preserve permanent elements', async () => {
    assert.total(3)
    let old_element = document.querySelector('#permanent')
    let new_element
    assert.equal('Rendering', old_element.innerHTML)
    await turbolinks.click('#permanent-element-link', { event_name: 'turbolinks:render' }, (event) => {
      new_element = document.querySelector('#permanent')
      assert.same(old_element, new_element)
    })
    await turbolinks.back('rendering', { event_name: 'turbolinks:render' }, (event) => {
      new_element = document.querySelector('#permanent')
      assert.same(old_element, new_element)
    })
  })

  it('should trigger before-cache event', async () => {
    turbolinks.on_event('turbolinks:before-cache', (event) => {
      document.body.innerHTML = 'Modified'
    })
    await turbolinks.click('#same-origin-link', {}, (event) => {
      assert.not_equal('Modified', document.body.innerHTML)
    })
    await turbolinks.back('rendering', {}, (event) => {
      assert.equal('Modified', document.body.innerHTML)
    })
  })

  it('should mutate record on before-cache notification', async () => {
    const { documentElement, body } = document
    const observer = new MutationObserver(records => {
      for (const record of records) {
        if (Array.from(record.removedNodes).indexOf(body) > -1) {
          body.innerHTML = "Modified"
          observer.disconnect()
          break
        }
      }
    })
    observer.observe(documentElement, { childList: true })
    await turbolinks.click('#same-origin-link', {}, (event) => {
      assert.not_equal('Modified', document.body.innerHTML)
    })
    await turbolinks.back('rendering', {}, (event) => {
      assert.equal('Modified', document.body.innerHTML)
    })
  })

  it('should load error pages', async () => {
    await turbolinks.click('#nonexistent-link', { event_name: 'turbolinks:render', status: 404 }, (event) => {
      assert.equal('Not found', document.body.innerHTML.trim())
    })
  })
})