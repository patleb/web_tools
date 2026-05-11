import '@@lib/ext_coffee/jest/core_ext/spec_helper'

describe('Array', () => {
  test('#is_a', () => {
    assert.true([].is_a(Array))
    assert.false([].is_a(Object))
  })

  test('#to_h', () => {
    assert.equal({}, [].to_h())
    assert.equal({ a: 1, b: 2 }, [['a', 1], ['b', 2]].to_h())
    assert.raise([['a', 1, 2], ['b', 2, 3]].to_h)
  })

  test('#blank_', () => {
    assert.true([].blank_())
    assert.false([1].blank_())
    assert.false([null].blank_())
  })

  test('#presence_', () => {
    assert.nil([].presence_())
    assert.equal([1], [1].presence_())
    assert.equal([null], [null].presence_())
  })

  test('#empty_', () => {
    assert.true([].empty_())
    assert.false([1].empty_())
    assert.false([null].empty_())
  })

  test('#eql_', () => {
    assert.true([].eql_([]))
    assert.true([1].eql_([1.0]))
    assert.true([null].eql_([undefined]))
    assert.true([/a/ig].eql_([/a/ig]))
    assert.false([1].eql_([1, 2]))
    assert.false([].eql_({}))
  })

  test('#merge_', () => {
    let array = []
    assert.equal([1], array.merge_([1]))
    assert.equal([1], array)
    assert.equal([1, 2, 3, 4], array.merge_([2], [3, 4]))
    assert.equal([1, 2, 3, 4], array)
  })

  test('#has_index', () => {
    assert.true([1, 2, 3].has_index(0))
    assert.true([1, 2, 3].has_index(2))
    assert.false([1, 2, 3].has_index(-1))
    assert.false([1, 2, 3].has_index(3))
  })

  test('#clear', () => {
    let array = [1, 2]
    array.clear()
    assert.empty(array)
  })

  test('#index', () => {
    assert.equal(0, [1, 2].index(1))
    assert.equal(1, [1, 2].index(2))
    assert.nil([1, 2].index(3))
  })

  test('#any', () => {
    assert.false([].any())
    assert.true([1].any())
    assert.true([1, 2, 3].any((v) => v === 3))
    assert.false([1, 2, 3].any((v) => v === 4))
  })

  test('#all', () => {
    assert.true([1, 1].all((v) => v === 1))
    assert.false([1, 2].all((v) => v === 1))
  })

  test('#none', () => {
    assert.true([1, 1].none((v) => v === 2))
    assert.false([1, 2].none((v) => v === 1))
  })

  test('#include', () => {
    assert.true([1, 2].include(1))
    assert.false([1, 2].include(3))
  })

  test('#each_while', () => {
    const array = [1, 2, 3]
    let count = 0
    array.each_while((v) => ++count && v < 2)
    assert.equal(2, count)
  })

  test('#each_with_object', () => {
    assert.equal({ 1: 1, 2: 2 }, [1, 2].each_with_object({}, (v, memo) => memo[v] = v))
  })

  test('#each_slice', () => {
    assert.equal([], [].each_slice(2))
    assert.equal([[1, 2], [3, 4]], [1, 2, 3, 4].each_slice(2))
    assert.equal([[1, 2], [3, 4], [5]], [1, 2, 3, 4, 5].each_slice(2))
  })

  test('#partition', () => {
    assert.equal([[1,2],[3,4,5]], [1,2,3,4,5].partition((v) => v < 3))
  })

  test('#pluck', () => {
    assert.equal([1, 2], [{ a: 1 }, { a: 2 }].pluck('a'))
    assert.equal([[1, undefined], [2, 3]], [{ a: 1 }, { a: 2, b: 3 }].pluck('a', 'b'))
  })

  test('#sort_by', () => {
    assert.equal([3, 2, 1], [3, 1, 2].sort_by((v) => -v))
    assert.equal([3, 2, 1, null, undefined, null], [null, 3, undefined, 1, null, 2].sort_by((v) => v == null ? 0 : -v))
    assert.equal(['a', 'b', 'c'], ['c', 'b', 'a'].sort_by((v) => v))
  })

  test('#select_', () => {
    assert.equal([2], [1, 2, 3].select_((v) => v === 2))
  })

  test('#select_map', () => {
    assert.equal(['b'], [1, 2, 3].select_map((v) => v === 2 ? 'b' : false))
  })

  test('#reject_', () => {
    assert.equal([1, 3], [1, 2, 3].reject_((v) => v === 2))
  })

  test('#except_', () => {
    assert.equal([1, 3], [1, 2, 3].except_(2))
    assert.equal([1], [1, 2, 3].except_(2, 3))
    assert.equal([], [1].except_(1))
  })

  test('#compact_', () => {
    assert.equal([], [null, undefined].compact_())
    assert.equal([0, false, ''], [0, false, '', null, undefined].compact_())
  })

  test('#first_, #last_', () => {
    const array = [1, 2, 3]
    assert.equal(1, array.first_())
    assert.equal([1, 2], array.first_(2))
    assert.equal(3, array.last_())
    assert.equal([2, 3], array.last_(2))
  })

  test('#dup_', () => {
    const array = [1, 2]
    const other = array.dup_()
    assert.not.same(array, other)
    assert.equal(array, other)
  })

  test('#find_index', () => {
    assert.equal(1, [1, 2, 3].find_index((v) => v === 2))
    assert.nil([1, 2, 3].find_index((v) => v === 4))
  })

  test('#flatten', () => {
    assert.equal([1, 2, 3], [[1], [2, [3]]].flatten())
  })

  test('#add', () => {
    assert.equal([1, 2, 3], [1].add([2, 3]))
  })

  test('#union', () => {
    assert.equal([1, 2, 3], [1, 1, 2].union([2, 2, 3], [3, 3]))
  })

  test('#zip', () => {
    assert.equal([[1, 4], [2, 5], [3, 6]], [1, 2, 3].zip([4, 5, 6]))
    assert.equal([[1, 4, 7], [2, 5, 8], [3, 6, 9]], [1, 2, 3].zip([4, 5, 6], [7, 8, 9]))
  })

  test('#uniq', () => {
    assert.equal([1, 2, 3], [1, 1, 2, 3, 3, 3].uniq())
    assert.equal([{ a: 1 }], [{ a: 1 }, { a: 1 }].uniq())
  })

  test('#extract_options', () => {
    let args = [1, 2, { a: 1, b: 2 }]
    assert.equal({ a: 1, b: 2 }, args.extract_options())
    assert.equal([1, 2], args)
    assert.equal({}, args.extract_options())
    assert.equal([1, 2], args)
  })
})
