import concepts from './spec_helper'

const storage = () => Rails.$0(Js.Storage.ROOT)

describe('Js.StorageConcept', () => {
  beforeAll(async () => {
    concepts.load_document('storage')
    await tick()
  })

  beforeEach(() => {
    concepts.enter_page('storage')
  })

  afterEach(() => {
    concepts.exit_page()
  })

  it('should serialize values correctly', () => {
    assert.undefined(Js.Storage.get('test[0]'))
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
    assert.equal(inputs.values(), Js.Storage.get(...inputs.keys()))
    Js.Storage.set({ undefined: undefined })
    assert.null(Js.Storage.get('undefined'))
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
    assert.total(5)
    dom.on_event({ count: 2, [`${Js.Storage.CHANGE}::name`]: ({ detail: { value, value_was} }, index) => {
      if (index === 0) {
        assert.undefined(value_was)
        assert.equal('value', value)
      } else {
        assert.equal('value', value_was)
        assert.equal('changed', value)
      }
    }})
    let count = 0
    dom.on_event({ count: 2, [Js.Storage.CHANGE]: (event, index) => {
      count++
    }})
    Js.Storage.set({ name: 'value' })
    Js.Storage.set({ name: 'changed' })
    assert.equal(2, count)
  })

  it('should scope key and event names', () => {
    assert.total(6)
    const scope = { scope: 'scoped' }
    dom.on_event({ count: 2, [`${Js.Storage.CHANGE}:scoped:name`]: ({ detail: { value, value_was} }, index) => {
      if (index === 0) {
        assert.undefined(value_was)
        assert.equal('value', value)
      } else {
        assert.equal('value', value_was)
        assert.equal('changed', value)
      }
    }})
    let count = 0
    dom.on_event({ count: 2, [`${Js.Storage.CHANGE}:scoped`]: (event, index) => {
      count++
    }})
    Js.Storage.set({ name: 'value' }, scope)
    assert.equal('value', Js.Storage.get('name', scope))
    Js.Storage.set({ name: 'changed' }, scope)
    assert.equal(2, count)
  })
})
