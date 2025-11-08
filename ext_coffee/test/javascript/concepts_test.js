import './spec_helper'

describe('Js.Concepts', () => {
  beforeAll(() => {
    dom.setup_document(fixture.html('concepts', { root: 'ext_coffee/test/fixtures/files' }))
    Js.Concepts.initialize({ modules: ['Test'], concepts: ['Test.SimpleConcept'] })
  })

  afterAll(() => {
    dom.reset_document()
  })

  it('should create all concept instances', () => {
    assert.equal(1, Js.Concepts.instances.ready_once.length)
    assert.equal(1, Js.Concepts.instances.ready.length)
    assert.equal(1, Js.Concepts.instances.leave.length)
    assert.equal(5, Js.Concepts.instances.leave_clean.length)
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

  describe('::Element', () => {
    it('should create all element classes', () => {
      assert.equal(Test.SimpleConcept, Test.SimpleConcept.Element.prototype.concept)
      assert.equal('Element', Test.SimpleConcept.Element.class_name)
      assert.equal('js_simple_name', Test.SimpleConcept.Element.prototype.NAME)
    })

    it('should define lazy #accessors on prototype and scope to it if used in #events', () => {
      let body = dom.find(Test.SimpleConcept.Element.prototype.BODY)
      dom.fire('hover', { target: body })
      assert.true(body.classes().include(Test.SimpleConcept.TRIGGERED))
      assert.equal(Test.SimpleConcept.Element.prototype.__body, Test.SimpleConcept.Element.prototype.body)
      assert.equal(['body', 'value'], Test.SimpleConcept.Element.prototype.READERS)
      let element = new Test.SimpleConcept.Element()
      assert.not.nil(element.__body)
      assert.equal(Test.SimpleConcept.Element.prototype.__body, element.__body)
      assert.equal('value', element.value)
      assert.nil(Test.SimpleConcept.Element.prototype.__value)
    })

    it('should not access parent ivars in inherited element', () => {
      let element = new Test.SimpleConcept.Element()
      let extended = new Test.SimpleConcept.ExtendElement()
      assert.equal('value', element.value)
      assert.nil(extended.__value)
    })
  })
})
