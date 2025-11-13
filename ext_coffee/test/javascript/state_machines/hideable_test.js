import '@@lib/ext_coffee/jest/state_machines/spec_helper'

let sm
let visible

describe('Sm.Hideable', () => {
  beforeEach(() => {
    sm = new Sm.Hideable({ methods: { visible: () => visible } })
  })

  it('should stay idle when the state does not change', () => {
    assert.equal('hidden', sm.current)
    assert.equal(StateMachine.STATUS.IDLED, sm.trigger('toggle'))
    assert.equal('hidden', sm.current)
    visible = true
    assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('toggle'))
    assert.equal('visible', sm.current)
  })
})
