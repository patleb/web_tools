import './spec_helper'

let sm
let visible

describe('Js.Hideable', () => {
  beforeEach(() => {
    sm = new Js.Hideable({ methods: { visible: () => visible } })
  })

  it('should stay idle when the state does not change', () => {
    assert.equal('hidden', sm.current)
    assert.equal(sm.STATUS.IDLED, sm.trigger('toggle'))
    assert.equal('hidden', sm.current)
    visible = true
    assert.equal(sm.STATUS.CHANGED, sm.trigger('toggle'))
    assert.equal('visible', sm.current)
  })
})
