import js from '@@lib/ext_coffee/jest/spec_helper'

let sm
let config
let toggle_base
let toggle_with_hooks
let arrow_base

describe('StateMachine', () => {
  beforeEach(() => {
    sm = new StateMachine(config)
  })

  describe('@initial, @terminal, @current', () => {
    beforeAll(() => {
      config = { initial: 'init_value', terminal: 'final_value' }
    })

    it('should set instance variables correctly', () => {
      assert.equal('init_value', sm.initial)
      assert.equal(['final_value'], sm.terminal.keys())
      assert.equal(sm.initial, sm.current)
    })
  })

  describe('as a toggle button', () => {
    beforeAll(() => {
      toggle_base = {
        initial: 'up',
        events: {
          toggle: { up: 'down', down: 'up' },
          void:   { nothing: 'nothing' }
        }
      }
    })

    describe('#trigger, #is, #stop, #resume', () => {
      beforeAll(() => {
        config = toggle_base
      })

      it('should return current state and follow the sequence: up, down, up, down, throws', () => {
        assert.equal('up', sm.current)
        assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('toggle'))
        assert.equal('down', sm.current)
        assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('toggle'))
        assert.equal('up', sm.current)
        assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('toggle'))
        assert.equal('down', sm.current)
        assert.equal(StateMachine.STATUS.DENIED, sm.trigger('unknown_event'))
      })

      it('should check the state and the transition', () => {
        assert.true(sm.is('up'))
        assert.true(sm.is(/^up$/))
        assert.false(sm.is('down'))
        assert.false(sm.is(/^down$/))
        assert.false(sm.is('unknown_state'))
      })

      it('should halt the transition and resume', () => {
        sm.stop()
        assert.equal(StateMachine.STATUS.HALTED, sm.trigger('toggle'))
        assert.equal('up', sm.current)
        sm.resume()
        assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('toggle'))
        assert.equal('down', sm.current)
      })
    })

    describe('config', () => {
      beforeAll(() => {
        config = toggle_with_hooks = {}.deep_merge(toggle_base, {
          initialize: (sm) => { sm.initial = 'down' },
          terminal: 'up',
          before: noop,
          after: noop,
          on_deny: noop,
          on_stop: noop,
          events: { toggle: { before: noop, after: noop } },
          states: { down: { exit: noop }, up: { enter: noop } },
          methods: { test: sm => sm.current },
        })
        js.spy_on(config)
      })

      it('should set #test correctly', () => {
        assert.equal('down', sm.test(sm))
      })

      it('should make a copy of the state machine structure with #dup', () => {
        const copy = sm.dup()
        sm.trigger('toggle')
        assert.true(copy instanceof sm.constructor)
        assert.not.same(sm, copy)
        assert.not.equal(sm.id, copy.id)
        assert.not.equal(sm.current, copy.current)
        const ivars = ['initial', 'terminal', 'states', 'methods', 'transitions']
        ivars.each((ivar) => {
          assert.same(sm[ivar], copy[ivar])
        })
        const methods = ['state', 'initialize', 'before', 'after', 'delegate', 'on_deny', 'on_stop']
        methods.each((method) => {
          assert.same(sm[method], copy[method])
        })
        assert.equal('down', copy.test(copy))
      })

      it('should call the hooks', () => {
        assert.equal('down', sm.current)
        assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('toggle', 'trigger_arg'))
        assert.equal('up', sm.current)
        sm.reset()
        assert.equal(StateMachine.STATUS.INITIALIZED, sm.status)
        assert.equal('down', sm.current)
        assert.equal(StateMachine.STATUS.DENIED, sm.trigger('void', 'trigger_arg'))
        const hooks = [
          'initialize',
          'before',
          'after',
          'on_deny',
          'on_stop',
          'events.toggle.before',
          'events.toggle.after',
          'states.down.exit',
          'states.up.enter'
        ]
        hooks.each((hook) => {
          assert.deep_equal(sm, config.dig(hook).mock.calls[0][0])
        })
      })

      it('should stop the state machine when @terminal state is reached', () => {
        assert.equal('down', sm.current)
        assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('toggle'))
        assert.equal('up', sm.current)
        assert.equal(StateMachine.STATUS.HALTED, sm.trigger('toggle'))
        assert.equal('up', sm.current)
        assert.raise(sm.resume)
      })

      describe('with #cancel called in #before hook', () => {
        beforeAll(() => {
          config = {}.deep_merge(toggle_with_hooks, {
            before: (sm) => { sm.cancel() },
          })
          js.spy_on(config)
        })

        it('should call #before hook, but not any other hooks after', () => {
          assert.equal(StateMachine.STATUS.HALTED, sm.trigger('toggle'))
          assert.true(sm.is('down'))
          assert.called(config.before)
          assert.not.called(config.events.toggle.before)
          assert.not.called(config.states.down.exit)
          assert.not.called(config.states.up.enter)
          assert.not.called(config.events.toggle.after)
          assert.not.called(config.after)
        })
      })

      describe('with #cancel called in event #before hook', () => {
        beforeAll(() => {
          config = {}.deep_merge(toggle_with_hooks, {
            events: { toggle: { before: (sm) => { sm.cancel() } } },
          })
          js.spy_on(config)
        })

        it('should call event #before hook, but not any other hooks after', () => {
          assert.equal(StateMachine.STATUS.HALTED, sm.trigger('toggle'))
          assert.true(sm.is('down'))
          assert.called(config.before)
          assert.called(config.events.toggle.before)
          assert.not.called(config.states.down.exit)
          assert.not.called(config.states.up.enter)
          assert.not.called(config.events.toggle.after)
          assert.not.called(config.after)
        })
      })

      describe('with #cancel called in state #exit hook', () => {
        beforeAll(() => {
          config = {}.deep_merge(toggle_with_hooks, {
            states: { down: { exit: (sm) => { sm.cancel() } } },
          })
          js.spy_on(config)
        })

        it('should call state #exit hook, but not any other hooks after', () => {
          assert.equal(StateMachine.STATUS.HALTED, sm.trigger('toggle'))
          assert.true(sm.is('down'))
          assert.called(config.before)
          assert.called(config.events.toggle.before)
          assert.called(config.states.down.exit)
          assert.not.called(config.states.up.enter)
          assert.not.called(config.events.toggle.after)
          assert.not.called(config.after)
        })
      })

      describe('with #cancel called in state #enter hook', () => {
        beforeAll(() => {
          config = {}.deep_merge(toggle_with_hooks, {
            states: { up: { enter: (sm) => { sm.cancel() } } },
          })
          js.spy_on(config)
        })

        it('should call state #enter hook, but not any other hooks after', () => {
          assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('toggle'))
          assert.true(sm.is('up'))
          assert.called(config.before)
          assert.called(config.events.toggle.before)
          assert.called(config.states.down.exit)
          assert.called(config.states.up.enter)
          assert.not.called(config.events.toggle.after)
          assert.not.called(config.after)
        })
      })

      describe('with #cancel called in event #after hook', () => {
        beforeAll(() => {
          config = {}.deep_merge(toggle_with_hooks, {
            events: { toggle: { after: (sm) => { sm.cancel() } } },
          })
          js.spy_on(config)
        })

        it('should event #after hook, but not any other hooks after', () => {
          assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('toggle'))
          assert.true(sm.is('up'))
          assert.called(config.before)
          assert.called(config.events.toggle.before)
          assert.called(config.states.down.exit)
          assert.called(config.states.up.enter)
          assert.called(config.events.toggle.after)
          assert.not.called(config.after)
        })
      })

      describe('with #stop called in #before hook', () => {
        beforeAll(() => {
          config = {}.deep_merge(toggle_with_hooks, {
            before: (sm) => { sm.stop() },
          })
          js.spy_on(config)
        })

        it('should event #before hook, but not any other hooks after', () => {
          assert.equal(StateMachine.STATUS.HALTED, sm.trigger('toggle'))
          assert.true(sm.is('down'))
          assert.called(config.before)
          assert.called(config.on_stop)
          assert.not.called(config.events.toggle.before)
          assert.not.called(config.states.down.exit)
          assert.not.called(config.states.up.enter)
          assert.not.called(config.events.toggle.after)
          assert.not.called(config.after)
        })
      })

      describe('with #defer called in #before hook', () => {
        beforeAll(() => {
          config = {}.deep_merge(toggle_with_hooks, {
            before: (sm) => { sm.defer() },
          })
          js.spy_on(config)
        })

        it('should event #before hook, but not any other hooks after', () => {
          assert.raise(sm.defer)
          assert.equal(StateMachine.STATUS.HALTED, sm.trigger('toggle'))
          assert.true(sm.is('down'))
          assert.called(config.before)
          assert.not.called(config.events.toggle.before)
          assert.not.called(config.states.down.exit)
          assert.not.called(config.states.up.enter)
          assert.not.called(config.events.toggle.after)
          assert.not.called(config.after)
        })

        it('should event #before hook on #reject, but not any other hooks after', () => {
          sm.trigger('toggle')
          assert.equal(StateMachine.STATUS.REJECTED, sm.reject())
          assert.true(sm.is('down'))
          assert.called(config.before)
          assert.not.called(config.events.toggle.before)
          assert.not.called(config.states.down.exit)
          assert.not.called(config.after)
          assert.not.called(config.events.toggle.after)
          assert.not.called(config.states.up.enter)
        })

        it('should event #before hook on #resolve, but not any other before hooks', () => {
          sm.trigger('toggle')
          assert.equal(StateMachine.STATUS.CHANGED, sm.resolve())
          assert.true(sm.is('up'))
          assert.called(config.before)
          assert.not.called(config.events.toggle.before)
          assert.not.called(config.states.down.exit)
          assert.called(config.states.up.enter)
          assert.called(config.events.toggle.after)
          assert.called(config.after)
        })
      })
    })
  })

  describe('as an arrow pointing vertices of a square', () => {
    const arrow_flags = {
      'up-right':   { data: { up: true,  down: false, left: false, right: true }},
      'up-left':    { data: { up: true,  down: false, left: true,  right: false }},
      'down-right': { data: { up: false, down: true,  left: false, right: true }},
      'down-left':  { data: { up: false, down: true,  left: true,  right: false }},
    }

    beforeAll(() => {
      arrow_base = {
        initial: 'up-right',
        events: {
          left:  { 'up-right':  'up-left',   'down-right': 'down-left' },
          right: { 'up-left':   'up-right',  'down-left':  'down-right' },
          down:  { 'up-left':   'down-left', 'up-right':   'down-right' },
          up:    { 'down-left': 'up-left',   'down-right': 'up-right' },
      }}
    })

    describe('#paths', () => {
      beforeAll(() => {
        config = arrow_base
      })

      it('should show all the transitions a state could take', () => {
        const expected = {
          'up-right':   { left:  'up-left',    down: 'down-right' },
          'up-left':    { right: 'up-right',   down: 'down-left' },
          'down-right': { left:  'down-left',  up:   'up-right' },
          'down-left':  { right: 'down-right', up:   'up-left' },
        }
        assert.equal(expected, sm.paths)
      })
    })

    describe('with :states data', () => {
      beforeAll(() => {
        config = { states: arrow_flags }.merge(arrow_base)
      })

      it('should assign data to @states', () => {
        assert.equal(arrow_flags['up-right'].data, sm.data)
        assert.equal(arrow_flags, sm.states.each_with_object({}, (k, v, h) => { h[k] = v.slice('data') }))
      })
    })

    describe('with :flags at true', () => {
      beforeAll(() => {
        config = { flags: true }.merge(arrow_base)
      })

      it('should assign deduced data to @states', () => {
        assert.equal(arrow_flags, sm.states.each_with_object({}, (k, v, h) => { h[k] = v.slice('data') }))
      })
    })
  })

  describe('with wildcard and list syntax', () => {
    //  states:
    //    'slower_speed, slow_speed': { park: 'parked' }
    //    '* - parked, stopped':      { break: 'stopped' }
    //    '*':                        { move: 'slow_speed' }
    //    slow_speed:                 { accelerate: 'normal_speed', slow_down: 'slower_speed' }
    //    slower_speed:               { accelerate: 'slow_speed' }
    //    normal_speed:               { slow_down: 'slow_speed' }
    beforeAll(() => {
      config = {
        initial: 'parked',
        events: {
          park:  { 'slower_speed, slow_speed': 'parked' },
          break: { '* - parked, stopped': 'stopped' },
          move:  { '*': 'slow_speed' },
          slow_down: {
            normal_speed: 'slow_speed',
            slow_speed: 'slower_speed'
          },
          accelerate: {
            slower_speed: 'slow_speed',
            slow_speed: 'normal_speed'
          }
        }
      }
    })

    it('should define @states and @transitions correctly', () => {
      const expected_states = ['parked', 'slower_speed', 'slow_speed', 'stopped', 'normal_speed']
      assert.equal(expected_states, sm.states.keys())
      const expected_transitions = {
        park: {
          slow_speed: 'parked',
          slower_speed: 'parked'
        },
        break: {
          slow_speed: 'stopped',
          slower_speed: 'stopped',
          normal_speed: 'stopped'
        },
        move: {
          parked: 'slow_speed',
          stopped: 'slow_speed',
          slow_speed: 'slow_speed',
          slower_speed: 'slow_speed',
          normal_speed: 'slow_speed'
        },
        slow_down: {
          normal_speed: 'slow_speed',
          slow_speed: 'slower_speed'
        },
        accelerate: {
          slower_speed: 'slow_speed',
          slow_speed: 'normal_speed'
        }
      }
      const actual_transitions = sm.transitions.each_with_object({}, (event, transitions, all) => {
        all[event] = transitions.each_with_object({}, (k, v, h) => h[k] = v.next)
      })
      assert.equal(expected_transitions, actual_transitions)
    })

    it('should transpose @transitions correctly with #paths', () => {
      const expected = {
        parked:       { move: 'slow_speed' },
        stopped:      { move: 'slow_speed' },
        slow_speed:   { move: 'slow_speed', break: 'stopped', park: 'parked', accelerate: 'normal_speed', slow_down: 'slower_speed' },
        slower_speed: { move: 'slow_speed', break: 'stopped', park: 'parked', accelerate: 'slow_speed' },
        normal_speed: { move: 'slow_speed', break: 'stopped', slow_down: 'slow_speed' },
      }
      assert.equal(expected, sm.paths)
    })
  })

  describe('with nested arguments through #trigger', () => {
    beforeAll(() => {
      const shared_var = 'shared'
      config = {
        initial: 'init',
        events: {
          run: {
            init: 'next',
            before: (sm, arg, { key }) => {
              assert.equal('arg', arg)
              assert.equal('key', key)
              assert.equal('shared', shared_var)
            }
          }
        }
      }
    })

    it('should pass correctly nested arguments', () => {
      sm.trigger('run', 'arg', { key: 'key' })
    })
  })

  describe('with chained events', () => {
    beforeAll(() => {
      config = {
        initial: 'init',
        events: {
          run: {
            init: 'next',
            next: 'next_2',
            next_2: 'next_3'
          }
        },
        states: {
          next: { enter: (sm) => { sm.trigger('run') } },
          next_2: { enter: (sm) => { sm.trigger('run') } },
        }
      }
    })

    it('should chain and execute triggers', () => {
      assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('run'))
      assert.equal('next_3', sm.current)
    })
  })

  describe('with transition hook', () => {
    beforeAll(() => {
      config = {
        initial: 'init',
        events: {
          run: {
            init: { 'next': {
              before: (sm) => { sm.transition.event.before(sm) }
            }},
            before: noop
          },
        }
      }
      js.spy_on(config)
    })

    it('should call both hooks', () => {
      assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('run'))
      assert.called(config.events.run.before, 1)
      assert.called(config.events.run.init.next.before, 1)
    })
  })

  describe('with several next states', () => {
    beforeAll(() => {
      config = {
        initial: 'init',
        events: {
          run: { '* - next, other': { '* - init': {
            next: (sm) => 'other'
          }}},
          execute: { other: { 'running, neutral': {
            next: (sm) => 'neutral'
          }}},
          stop: { 'running, neutral': { 'other, stopped': {
            next: (sm) => 'stopped'
          }}}
        }
      }
    })

    it('should use the #next method to set the state', () => {
      assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('run'))
      assert.equal('other', sm.current)
      assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('execute'))
      assert.equal('neutral', sm.current)
      assert.equal(StateMachine.STATUS.CHANGED, sm.trigger('stop'))
      assert.equal('stopped', sm.current)
    })
  })

  describe('with #delegate', () => {
    beforeAll(() => {
      config = {
        initialize: (sm) => {
          sm.child = new StateMachine({
            initial: 'init',
            events: {
              execute: { init: 'other' },
              run: { other: 'next' },
            }
          })
        },
        initial: 'init',
        events: {
          run: { other: 'next' }
        },
        delegate: (sm, event) => {
          sm.child.trigger(event)
        }
      }
    })

    it('should delegate the event triggered to the child if no trigger or no transition', () => {
      assert.equal(StateMachine.STATUS.DELEGATED, sm.trigger('execute'))
      assert.equal(StateMachine.STATUS.CHANGED, sm.child.status)
      assert.equal('other', sm.child.current)
      assert.equal('init', sm.current)
      assert.equal(StateMachine.STATUS.DELEGATED, sm.trigger('run'))
      assert.equal('next', sm.child.current)
      assert.equal('init', sm.current)
    })
  })
})
