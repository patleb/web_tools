import concepts from '@@lib/ext_coffee/jest/concepts/spec_helper'

const storage = () => Rails.find(Js.Storage.ROOT)

describe('Js.StorageConcept', () => {
  concepts.with_page('storage', { root: 'ext_coffee' })

  it('should serialize values correctly', () => {
    assert.empty(Js.Storage.get('test[0]'))
    const inputs = {
      integer: 0,
      float: 1.2,
      boolean: false,
      date: new Date(),
      array: [1, 2.3, true],
      object: { a: [null] },
      null: null,
    }
    Js.Storage.set(inputs)
    assert.equal(inputs, Js.Storage.get(...inputs.keys()))
    Js.Storage.set({ undefined: undefined })
    assert.equal({ undefined: null }, Js.Storage.get('undefined'))
  })

  it('should create a storage tag if absent', () => {
    const element = storage()
    element.parentElement.removeChild(element)
    assert.nil(storage())
    assert.nil(Js.Storage.__storage)
    Js.Storage.get('name')
    assert.equal(storage(), Js.Storage.storage())
  })

  it('should fire changes', () => {
    assert.total(4)
    dom.on_event({ count: 2, [Js.Storage.CHANGE]: ({ detail: { changes: { name: [value, value_was] }}}, index) => {
      if (index === 0) {
        assert.undefined(value_was)
        assert.equal('value', value)
      } else {
        assert.equal('value', value_was)
        assert.equal('changed', value)
      }
    }})
    Js.Storage.set({ name: 'value' })
    Js.Storage.set({ name: 'changed' })
  })

  it('should scope key and event names', () => {
    assert.total(7)
    const scope = { scope: 'scoped' }
    dom.on_event({ count: 2, [Js.Storage.CHANGE]: ({ detail: { changes: { name: [value, value_was] }}}, index) => {
      if (index === 0) {
        assert.undefined(value_was)
        assert.equal('value', value)
      } else {
        assert.equal('value', value_was)
        assert.equal('changed', value)
      }
    }})
    Js.Storage.set({ name: 'value' }, scope)
    assert.equal({ name: 'value' }, Js.Storage.get('name', scope))
    Js.Storage.set({ name: 'changed' }, scope)
    const names = []
    assert.equal({ name: 'changed' }, Js.Storage.get(...names, scope))
    assert.equal({ name: 'changed' }, Js.Storage.get(scope))
  })

  it('should use the permanent storage', () => {
    let count = 0
    dom.on_event({ [Js.Storage.CHANGE]: (event, index) => {
      count++
    }})
    Js.Storage.set({ name: 'value'}, { permanent: true })
    assert.equal(1, count)
    assert.nil(Js.Storage.get_value('name'))
    assert.equal('value', Js.Storage.get_value('name', { permanent: true }))
  })
})
