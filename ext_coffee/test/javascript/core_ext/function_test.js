import '@@lib/ext_coffee/jest/core_ext/spec_helper'

describe('Function', () => {
  let f = () => true

  test('#is_a', () => {
    assert.true(f.is_a(Function))
    assert.false(f.is_a(Object))
  })

  test('#eql', () => {
    let same = f
    let other = () => true
    assert.true(f.eql(same))
    assert.false(f.eql(other))
  })

  test('.new', () => {
    let object = Object.new()
    object.a = 1
    assert.equal({ a: 1 }, object)
    assert.equal({ a: 1 }, Object.new({ a: 1 }))
  })

  test('.include, .extend', () => {
    let klass = Class.new()
    assert.equal('Concern', klass.context())
    assert.equal('Extended', klass.__proto__.constructor.context())
    assert.true(klass.__proto__.constructor.extended)
    assert.true(klass.__proto__.constructor.included)
  })

  test('.alias_method', () => {
    let klass = Class.new()
    assert.equal('Method', klass.method())
    assert.equal('Method', klass.alias())
  })

  test('.delegate_to', () => {
    let klass = Class.new()
    assert.equal('Constructor Delegate', klass.constructor_delegate())
    assert.equal('IVar Delegate', klass.to_s().toString())
    assert.equal('Module Delegate', klass.module_delegate())
  })

  test('.deconstantize', () => {
    let string = 'Test.ScopedClass.function'
    let object = string.constantize()
    assert.equal('Test.ScopedClass', Test.ScopedClass.deconstantize())
    assert.equal('Test.ScopedClass::', Test.ScopedClass.prototype.deconstantize())
    assert.equal(object, Test.ScopedClass.function)
    assert.equal(string, object.deconstantize())
    string = 'Test.ScopedClass::method'
    object = string.constantize()
    assert.equal(object, Test.ScopedClass.prototype.method)
    assert.equal(string, object.deconstantize())
    assert.undefined(Base.deconstantize())
    assert.undefined(Base.constructor_delegate.deconstantize())
    assert.undefined(Base.prototype.method.deconstantize())
    assert.undefined(Base.prototype.deconstantize())
  })
})
