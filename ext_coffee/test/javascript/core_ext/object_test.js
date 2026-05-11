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

  test('#to_query', () => {
    assert.equal('a=1&b=2', { a: 1, b: 2 }.to_query())
    assert.equal('a=1', { a: 1, b: ' ' }.to_query({ blanks: false }))
    assert.equal('a=1', { a: 1, ' ': 2 }.to_query({ blanks: false }))
    assert.equal('a%5B%5D=1&a%5B%5D=2', { a: [1, 2] }.to_query())
    assert.equal('a%5Bb%5D=1&a%5Bc%5D=2&d%5B%5D=3&e=4', { a: { b: 1, c: 2 }, d: [3], e: 4 }.to_query())
  })

  test('#blank_', () => {
    assert.true({}.blank_())
    assert.false({ null: null }.blank_())
    assert.false({ null: undefined }.blank_())
  })

  test('#presence_', () => {
    assert.nil({}.presence_())
    assert.equal({ a: 1 }, { a: 1 }.presence_())
    assert.equal({ null: null }, { null: null }.presence_())
  })

  test('#empty_', () => {
    assert.true({}.empty_())
    assert.false({ null: null }.empty_())
    assert.false({ null: undefined }.empty_())
  })

  test('#eql_', () => {
    assert.true({}.eql_({}))
    assert.true({ a: 1 }.eql_({ a: 1.0 }))
    assert.true({ null: null }.eql_({ null: undefined }))
    assert.false({ a: 1 }.eql_({ a: 1, b: 2 }))
    assert.false({}.eql_([]))
  })

  test('#tap_', () => {
    let value
    assert.equal({ a: 1 }, { a: 1 }.tap_(object => value = object.a ))
    assert.equal(1, value)
    assert.equal('value', 'value'.tap_(string => value = string.toString() ).toString())
    assert.equal('value', value)
  })

  test('#has_key', () => {
    assert.true({ a: 1 }.has_key('a'))
    assert.true({ null: null }.has_key('null'))
    assert.false({ a: 1 }.has_key('b'))
  })

  test('#delete_', () => {
    let hash = { a: 1, b: 2 }
    assert.equal(2, hash.delete_('b'))
    assert.equal({ a: 1 }, hash)
  })

  test('#dig_', () => {
    assert.equal(1, { a: 1 }.dig_('a'))
    assert.equal(2, { a: { b: 2 } }.dig_('a.b'))
    assert.equal(3, { a: { b: [2, 3] } }.dig_('a.b.1'))
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

  test('#map_', () => {
    assert.equal([1, 2], { a: 1, b: 2 }.map_((k, v) => v))
  })

  test('#flatten_keys', () => {
    assert.equal({ 'a.b': [2, 3] }, { a: { b: [2, 3] } }.flatten_keys())
  })

  test('#find_', () => {
    const hash = { a: 1, b: 2, c: 3 }
    let count = 0
    assert.equal(2, hash.find_((k, v) => ++count && v === 2))
    assert.equal(2, count)
  })

  test('#values_', () => {
    assert.equal([1, 2], { a: 1, b: 2 }.values_())
  })

  test('#values_at', () => {
    assert.equal([1, 3], { a: 1, b: 2, c: 3 }.values_at('a', 'c'))
  })

  test('#select_', () => {
    assert.equal({ b: 2 }, { a: 1, b: 2, c: 3 }.select_((k, v) => v === 2))
  })

  test('#select_map', () => {
    assert.equal(['b'], { a: 1, b: 2, c: 3 }.select_map((k, v) => v === 2 ? k : null))
  })

  test('#reject_', () => {
    assert.equal({ a: 1, c: 3 }, { a: 1, b: 2, c: 3 }.reject_((k, v) => v === 2))
  })

  test('#slice_', () => {
    assert.equal({ a: 1, c: 3 }, { a: 1, b: 2, c: 3 }.slice_('a', 'c', 'd'))
  })

  test('#except_', () => {
    assert.equal({ b: 2 }, { a: 1, b: 2, c: 3 }.except_('a', 'c'))
  })

  test('#compact_', () => {
    assert.equal({}, { null: null, undefined: undefined }.compact_())
    assert.equal({ a: 0, b: false, c: '' }, { a: 0, b: false, c: '', d: null, e: undefined }.compact_())
  })

  test('#first_, #last_', () => {
    const object = { a: 1, b: 2, c: 3 }
    assert.equal(['a', 1], object.first_())
    assert.equal({ a: 1, b: 2 }, object.first_(2))
    assert.equal(['c', 3], object.last_())
    assert.equal({ b: 2, c: 3 }, object.last_(2))
  })

  test('#deep_merge', () => {
    const object = { a: { b: 1 }, d: {} }
    assert.equal({ a: { b: 1, c: 2 }, d: null }, object.deep_merge({ a: { c: 2 }, d: null }))
    assert.equal({ a: { b: 1, c: 2 }, d: null }, object)
  })

  test('.deep_sort', () => {
    const object = { b: 1, a: [3, 2] }
    assert.equal({ a: [2, 3], b: 1 }, Object.deep_sort(object, true))
    assert.equal([2, 3], Object.deep_sort(object.a, true))
  })
})
