import '@@lib/ext_coffee/jest/core_ext/spec_helper'

describe('Object', () => {
  test('#is_a', () => {
    assert.true({}.is_a(Object))
    assert.false({}.is_a(Array))
    assert.false({}.is_a(Function))
    assert.false({}.is_a(Element))
  })

  test('#to_a', () => {
    assert.equal([], {}.to_a())
    assert.equal([['a', 1], ['b', 2]], { a: 1, b: 2 }.to_a())
  })

  test('#blank', () => {
    assert.true({}.blank())
    assert.false({ null: null }.blank())
    assert.false({ null: undefined }.blank())
  })

  test('#presence', () => {
    assert.nil({}.presence())
    assert.equal({ a: 1 }, { a: 1 }.presence())
    assert.equal({ null: null }, { null: null }.presence())
  })

  test('#empty', () => {
    assert.true({}.empty())
    assert.false({ null: null }.empty())
    assert.false({ null: undefined }.empty())
  })

  test('#eql', () => {
    assert.true({}.eql({}))
    assert.true({ a: 1 }.eql({ a: 1.0 }))
    assert.true({ null: null }.eql({ null: undefined }))
    assert.false({ a: 1 }.eql({ a: 1, b: 2 }))
    assert.false({}.eql([]))
  })

  test('#tap', () => {
    let value
    assert.equal({ a: 1 }, { a: 1 }.tap((object) => value = object.a ))
    assert.equal(1, value)
    assert.equal('value', 'value'.tap((string) => value = string.to_s() ).to_s())
    assert.equal('value', value)
  })

  test('#has_key', () => {
    assert.true({ a: 1 }.has_key('a'))
    assert.true({ null: null }.has_key('null'))
    assert.false({ a: 1 }.has_key('b'))
  })

  test('#delete', () => {
    let hash = { a: 1, b: 2 }
    assert.equal(2, hash.delete('b'))
    assert.equal({ a: 1 }, hash)
  })

  test('#dig', () => {
    assert.equal(1, { a: 1 }.dig('a'))
    assert.equal(2, { a: { b: 2 } }.dig('a.b'))
    assert.equal(3, { a: { b: [2, 3] } }.dig('a.b.1'))
  })

  test('#any', () => {
    assert.false({}.any())
    assert.true({ a: 1 }.any())
    assert.true({ a: 1, b: 2 }.any((k, v) => v === 1))
    assert.false({ a: 1, b: 2 }.any((k, v) => v === 3))
  })

  test('#all', () => {
    assert.true({ a: 1, b: 1 }.all((k, v) => v === 1))
    assert.false({ a: 1, b: 2 }.all((k, v) => v === 1))
  })

  test('#each_while', () => {
    const hash = { a: 1, b: 2, c: 3 }
    let count = 0
    hash.each_while((k, v) => ++count && v < 2)
    assert.equal(2, count)
  })

  test('#each_with_object', () => {
    assert.equal(['a', 1, 'b', 2], { a: 1, b: 2 }.each_with_object([], (k, v, memo) => memo.push(k, v)))
  })

  test('#map', () => {
    assert.equal([1, 2], { a: 1, b: 2 }.map((k, v) => v))
  })

  test('#flatten_keys', () => {
    assert.equal({ 'a.b': [2, 3] }, { a: { b: [2, 3] } }.flatten_keys())
  })

  test('#find', () => {
    const hash = { a: 1, b: 2, c: 3 }
    let count = 0
    assert.equal(2, hash.find((k, v) => ++count && v === 2))
    assert.equal(2, count)
  })

  test('#values', () => {
    assert.equal([1, 2], { a: 1, b: 2 }.values())
  })

  test('#values_at', () => {
    assert.equal([1, 3], { a: 1, b: 2, c: 3 }.values_at('a', 'c'))
  })

  test('#select', () => {
    assert.equal({ b: 2 }, { a: 1, b: 2, c: 3 }.select((k, v) => v === 2))
  })

  test('#select_map', () => {
    assert.equal(['b'], { a: 1, b: 2, c: 3 }.select_map((k, v) => v === 2 ? k : null))
  })

  test('#reject', () => {
    assert.equal({ a: 1, c: 3 }, { a: 1, b: 2, c: 3 }.reject((k, v) => v === 2))
  })

  test('#slice', () => {
    assert.equal({ a: 1, c: 3 }, { a: 1, b: 2, c: 3 }.slice('a', 'c', 'd'))
  })

  test('#except', () => {
    assert.equal({ b: 2 }, { a: 1, b: 2, c: 3 }.except('a', 'c'))
  })

  test('#compact', () => {
    assert.equal({}, { null: null, undefined: undefined }.compact())
    assert.equal({ a: 0, b: false, c: '' }, { a: 0, b: false, c: '', d: null, e: undefined }.compact())
  })

  test('#deep_merge', () => {
    const object = { a: { b: 1 }, d: {} }
    assert.equal({ a: { b: 1, c: 2 }, d: null }, object.deep_merge({ a: { c: 2 }, d: null }))
    assert.equal({ a: { b: 1, c: 2 }, d: null }, object)
  })
})
