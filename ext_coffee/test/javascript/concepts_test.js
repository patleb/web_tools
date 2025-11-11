import '@@lib/ext_coffee/jest/concepts/spec_helper'

describe('Js.Concepts', () => {
  beforeAll(() => {
    dom.setup_document(fixture.html('classes', { root: 'ext_coffee/test/fixtures/files/concepts' }))
    Js.Concepts.initialize({ modules: ['Test'], concepts: [
        'Js.StorageConcept',
        'Js.ComponentConcept',
        'Test.SimpleConcept',
      ]
    })
  })

  afterAll(() => {
    dom.reset_document()
  })

  it('should create all concept instances', () => {
    assert.equal(1, Js.Concepts.instances.ready_once.length)
    assert.equal(2, Js.Concepts.instances.ready.length)
    assert.equal(2, Js.Concepts.instances.leave.length)
    assert.equal(7, Js.Concepts.instances.leave_clean.length)
    assert.equal('Test', Test.SimpleConcept.module_name)
    assert.equal('SimpleConcept', Test.SimpleConcept.class_name)
    assert.equal('Test', Test.ExtendConcept.module_name)
    assert.equal('ExtendConcept', Test.ExtendConcept.class_name)
    assert.false(Test.SimpleConcept.is_a(Function))
    assert.true(Test.NotAConceptName.is_a(Function))
    assert.same(Global, Test.GlobalConcept)
    assert.same(SomeGlobal, Test.CustomGlobalConcept)
    assert.same(Scoped.Global, Test.ScopedGlobalConcept)
    const constants = {
      BODY:      '#js_simple_body',
      ROWS:      '.js_simple_rows',
      TRIGGERED: 'js_simple_triggered',
      CUSTOM:    '.js_simple_custom > a',
      BODY_ROWS: '#js_simple_body .js_simple_rows',
    }
    assert.equal(constants, Test.SimpleConcept.constructor.prototype.CONSTANTS)
    constants.each((name, value) => {
      assert.equal(value, Test.SimpleConcept[name])
    })
  })

  it('should call #ready_once and #ready on "DOMContentLoaded"', async () => {
    dom.fire('DOMContentLoaded')
    dom.fire('turbolinks:load', { data: { info: { once: true } } })
    await tick()
    assert.equal(1, Test.SimpleConcept.did_ready_once)
    assert.equal(1, Test.SimpleConcept.did_ready)
    assert.nil(Test.SimpleConcept.__did_leave)
  })

  it('should call #ready on "turbolinks:load"', () => {
    dom.fire('turbolinks:load', { data: { info: {} } })
    assert.equal(1, Test.SimpleConcept.did_ready_once)
    assert.equal(2, Test.SimpleConcept.did_ready)
    assert.nil(Test.SimpleConcept.__did_leave)
  })

  it('should call #leave on "turbolinks:before-render" and nullify #did_ready ivar', () => {
    dom.fire('turbolinks:before-render')
    assert.equal(1, Test.SimpleConcept.did_ready_once)
    assert.nil(Test.SimpleConcept.did_ready)
    assert.equal(1, Test.SimpleConcept.__did_leave)
  })

  it('should define lazy #accessors', () => {
    assert.nil(Test.SimpleConcept.__rows)
    dom.find(Test.SimpleConcept.BODY).click()
    assert.equal(Test.SimpleConcept.__rows, Test.SimpleConcept.rows)
  })

  it('should nullify non-system ivars and not from #ready_once on #leave', () => {
    assert.equal('method', Test.SimpleConcept.method())
    assert.equal('constant', Test.SimpleConcept.CONSTANT)
    assert.equal('after', Test.SimpleConcept.public)
    assert.equal('private', Test.SimpleConcept._private)
    assert.equal('system', Test.SimpleConcept.__system)
    assert.equal('inherited', Test.ExtendConcept.inherited)
    assert.nil(Test.SimpleConcept.inherited)
    dom.fire('turbolinks:before-render')
    assert.nil(Test.SimpleConcept.__rows)
    assert.not.nil(Test.SimpleConcept.method)
    assert.not.nil(Test.SimpleConcept.CONSTANT)
    assert.nil(Test.SimpleConcept.public)
    assert.nil(Test.SimpleConcept._private)
    assert.not.nil(Test.SimpleConcept.__system)
    assert.nil(Test.ExtendConcept.inherited)
  })

  describe('#events', () => {
    afterEach(() => {
      dom.find(Test.SimpleConcept.BODY).remove_class(Test.SimpleConcept.TRIGGERED)
      dom.$(Test.SimpleConcept.ROWS).each(e => e.remove_class(Test.SimpleConcept.TRIGGERED))
    })

    it('should handle click events', () => {
      let row = dom.find(Test.SimpleConcept.ROWS)
      let event = dom.fire('click', { target: row })
      assert.true(row.classes().include(Test.SimpleConcept.TRIGGERED))
      assert.true(event.events_before)
      assert.true(event.events_after)
    })

    it('should handle click events and prevent default', () => {
      let body = dom.find(Test.SimpleConcept.BODY)
      let event = dom.fire('click', { target: body, options: { skip: true } })
      assert.true(body.classes().include(Test.SimpleConcept.TRIGGERED))
      assert.true(event.defaultPrevented)
      assert.true(event.events_before)
      assert.nil(event.events_after)
    })

    it('should handle hover events', () => {
      let row = dom.find(Test.SimpleConcept.ROWS)
      let event = dom.fire('hover', { target: row })
      assert.true(row.classes().include(Test.SimpleConcept.TRIGGERED))
      assert.true(event.events_before)
      assert.true(event.events_after)
    })

    it('should skip handler and after hook if prevent default is in before hook', () => {
      let row = dom.find(Test.SimpleConcept.ROWS)
      let event = dom.fire('hover', { target: row, options: { skip_before: true } })
      assert.true(event.defaultPrevented)
      assert.false(row.classes().include(Test.SimpleConcept.TRIGGERED))
      assert.true(event.events_before)
      assert.nil(event.events_after)
    })

    it('should skip after hook if prevent default is in handler', () => {
      let row = dom.find(Test.SimpleConcept.ROWS)
      let event = dom.fire('hover', { target: row, options: { skip: true } })
      assert.true(event.defaultPrevented)
      assert.true(row.classes().include(Test.SimpleConcept.TRIGGERED))
      assert.true(event.events_before)
      assert.nil(event.events_after)
    })
  })

  describe('Js.Component.Element', () => {
    it('should create all element classes', () => {
      assert.equal('SimpleElement', Js.Component.SimpleElement.class_name)
      assert.equal('.js_simple_name', Js.Component.SimpleElement.prototype.NAME)
    })

    it('should define lazy #accessors on prototype and scope to it if used in #events', () => {
      let name = dom.find(Js.Component.SimpleElement.prototype.NAME)
      dom.fire('hover', { target: name })
      assert.true(name.classes().include(Test.SimpleConcept.TRIGGERED))
      assert.equal(Js.Component.SimpleElement.prototype.__body, Js.Component.SimpleElement.prototype.body)
      assert.equal(['name', 'value'], Js.Component.SimpleElement.prototype.READERS)
      let element = new Js.Component.SimpleElement(name)
      assert.not.nil(element.__name)
      assert.equal(Js.Component.SimpleElement.prototype.__name, element.__name)
      assert.equal('value', element.value)
      assert.nil(Js.Component.SimpleElement.prototype.__value)
    })

    it('should not access parent ivars in inherited element', () => {
      let name = dom.find(Js.Component.SimpleElement.prototype.NAME)
      let element = new Js.Component.SimpleElement(name)
      let extended = new Js.Component.ExtendElement(name)
      assert.equal('value', element.value)
      assert.nil(extended.__value)
    })
  })
})
