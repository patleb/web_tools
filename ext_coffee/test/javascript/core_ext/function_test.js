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
    assert.equal('Base', klass.__proto__.context.super())
    assert.equal('Extended', klass.__proto__.constructor.context())
    assert.equal('Module', klass.__proto__.constructor.context.super())
    assert.true(klass.__proto__.constructor.extended)
    assert.true(klass.__proto__.included)
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
})
