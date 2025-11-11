class window.StateMachine
  @extend WithReaders

  CONFIG_IVARS = ['initial', 'terminal']
  CONFIG_HOOKS = ['state', 'initialize', 'before', 'after', 'delegate', 'on_deny', 'on_stop']
  EVENT_HOOKS = ['before', 'after']
  STATE_HOOKS = ['enter', 'exit']
  STATE_CONFIG = STATE_HOOKS.add ['data']
  CLONABLE_IVARS = CONFIG_IVARS.add ['states', 'methods', 'transitions']
  WILDCARD = '*'
  EXCEPT = ' - '
  LIST = ','
  FLAGS = '-'

  @STATUS: [
    'CANCELED'
    'STOPPED'
    'RESUMED'
    'DEFERRED'
    'REJECTED'
    'RESOLVED'
    'INITIALIZED'
    'HALTED'
    'DELEGATED'
    'DENIED'
    'CHANGED'
    'IDLED'
  ].map((v) -> [v, v]).to_h()

  @readers
    data: ->
      @states[@current].data

    paths: ->
      @_paths ||= @transitions.each_with_object {}, (event, transitions, memo) ->
        transitions.each (current, transition) ->
          next = transition.next
          next = transition.next_states if next.is_a Function
          (memo[current] ||= {})[event] = next

  @debug: (@_debug) ->

  constructor: (config) ->
    @build(config)

  build: (config) ->
    @STATUS = StateMachine.STATUS
    @id = Math.uid()
    if config instanceof @constructor
      config.methods?.each (name) => this[name] = config[name]
      CLONABLE_IVARS.each (name) => this[name] = config[name]
      CONFIG_HOOKS.each (name) => this[name] = config[name]
    else
      config = @config().deep_merge(config)
      if config.methods?
        config.methods.each (name, method) => this[name] = method
        @methods = config.methods.keys()
      CONFIG_HOOKS.each (name) => this[name] = config[name] ? noop
      @initial = config.initial
      @terminal = Array.wrap(config.terminal).to_set()
      @extract_states(config)
      @extract_flags() if config.flags
    @reset()

  dup: ->
    new @constructor this

  config: -> {}

  is: (state) ->
    if state.is_a RegExp
      !!@current.match(state)
    else
      @current is state

  cancel: ->
    return if @canceled
    @canceled = true
    @log @STATUS.CANCELED

  stop: (args...) ->
    return if @stopped
    @stopped = true
    @on_stop(this, @finished(), args...)
    @log @STATUS.STOPPED

  resume: ->
    return unless @stopped
    if @finished()
      throw "#resume can't be called once the @terminal state is reached"
    @stopped = false
    @reset_trigger()
    @log @STATUS.RESUMED

  defer: (args...) ->
    unless @deferrable
      throw '#defer must be called only once in before hooks'
    @deferred = [@event, args...]
    @deferrable = false
    @log @STATUS.DEFERRED

  reject: ->
    return unless @deferred
    @deferred = null
    @log @STATUS.REJECTED
    @reset_trigger()
    @canceled = false
    @status

  resolve: ->
    return unless @deferred
    [@event, args...] = @deferred
    @deferred = null
    @log @STATUS.RESOLVED
    @set_next_state(args...)
    @reset_trigger()
    @canceled = false
    @status

  reset: ->
    @deferred = null
    @canceled = @stopped = false
    @initial = @state(this) unless @state is noop
    @initialize(this)
    @previous = null
    @current = @initial
    @log @STATUS.INITIALIZED

  trigger: (event, args...) ->
    if @event_next
      throw 'events can be chained, but not queued'
    else if @event
      @event_next = [event, args...]
      return
    @event = event
    @run_event(args...)
    @reset_trigger()
    @canceled = false
    @status

  # Private

  run_event: (args...) ->
    return @log @STATUS.HALTED if @halted()
    unless @has_transition()
      if @delegate isnt noop
        @delegate(this, @event, args...)
        return @log @STATUS.DELEGATED
      else
        @on_deny(this, args...)
        return @log @STATUS.DENIED
    return @log @STATUS.IDLED if @state(this) is @current
    @set_transition()
    @deferrable = true
    @run_before_hooks(args...)
    @deferrable = false
    return @log @STATUS.HALTED if @halted()
    @set_next_state(args...)

  set_next_state: (args...) ->
    if (next = @transition.next).is_a Function
      next = next(this, args...)
      unless next of @transition.next_states
        @on_deny(this, args...)
        return @log @STATUS.DENIED
    @previous = @current
    @current = next
    @run_after_hooks(args...)
    @log @STATUS.CHANGED
    if (event_next = @event_next)
      @reset_trigger()
      @trigger(event_next...)

  reset_trigger: ->
    @event_next = null
    @event = null

  # config.before, event.before, state.exit
  run_before_hooks: (args...) ->
    @before(this, args...)
    @transition.before(this, args...) unless @halted()
    @states[@current].exit(this, args...) unless @halted()

  # state.enter, event.after, config.after
  run_after_hooks: (args...) ->
    @states[@current].enter(this, args...)
    @transition.after(this, args...) unless @halted()
    @after(this, args...) unless @halted()
    @stop(args...) if @finished()

  halted: ->
    @canceled or @stopped or @deferred

  finished: ->
    @current of @terminal

  has_transition: ->
    @get_transition(@event)?

  set_transition: ->
    @transition = @get_transition(@event)

  get_transition: (event) ->
    @transitions[event]?[@current]

  extract_states: (config) ->
    @states = {}
    @transitions = {}
    current_wildcards = {}
    next_wildcards = {}
    config.events?.each (event_name, event_config) =>
      event_hooks = event_config.slice(EVENT_HOOKS...)
      transitions = event_config.except(EVENT_HOOKS...)
      transitions.each (current, next) =>
        if next.is_a Object
          [next, transition_hooks] = next.first()
          if transition_hooks.next
            hooks = @merge_hooks(transition_hooks, event_hooks)
            if hooks.next_states = @add_wildcard_or_states(next_wildcards, event_name, next, transition_hooks.next)?.to_set()
              hooks.next_states.each (next) =>
                @add_wildcard_or_states(current_wildcards, event_name, current, next, hooks)?.each (state) =>
                  @add_transition(event_name, state, transition_hooks.next, hooks)
              return
            next = transition_hooks.next
        unless hooks
          hooks = @merge_hooks(transition_hooks, event_hooks)
          @add_state(next)
        @add_wildcard_or_states(current_wildcards, event_name, current, next, hooks)?.each (state) =>
          @add_transition(event_name, state, next, hooks)
    @configure_states(config)
    states = @states.keys()
    current_wildcards.each (event, { except_states, next, hooks }) =>
      states.except(except_states...).each (current) =>
        @add_transition(event, current, next, hooks)
    states = states.to_set()
    next_wildcards.each (event, { except_states, next }) =>
      next_states = if except_states.present() then states.except(except_states...) else states
      @transitions[event].each (current, transition) =>
        transition.next_states = next_states if transition.next is next

  configure_states: (config) ->
    @add_state(@initial) if @initial
    @terminal.each (terminal) =>
      @add_state(terminal)
    config.states?.each (state_name, state_config) =>
      @add_state(state_name)
      state_config.slice(STATE_CONFIG...).each (key, value) =>
        @states[state_name][key] = value

  merge_hooks: (transition_hooks, event_hooks) ->
    EVENT_HOOKS.each_with_object {}, (name, memo) ->
      if (transition_hook = transition_hooks?[name])
        memo[name] = transition_hook
        memo.event ||= {}
        memo.event[name] = event_hooks[name] ? noop
      else
        memo[name] = event_hooks[name] ? noop

  add_wildcard_or_states: (wildcards, event, states, next, hooks) ->
    if states.start_with WILDCARD
      except_states = @add_except_states(states)
      wildcards[event] = { except_states, next, hooks }
      null
    else
      @add_states(states)

  add_except_states: (states) ->
    if states.include EXCEPT
      @add_states(states.split(EXCEPT).last())
    else
      []

  add_states: (states) ->
    states.split(LIST).map (state) =>
      state = state.strip()
      @add_state(state)
      state

  # data is assumed to be static --> should assign functions or pointers for dynamic usage
  add_state: (state) ->
    @states[state] ?= { exit: noop, enter: noop, data: {} }

  add_transition: (event, current, next, hooks) ->
    @transitions[event] ?= {}
    @transitions[event][current] = { next }.merge(hooks)

  extract_flags: ->
    flags = @states.each_with_object {}, (state_name, _, memo) ->
      state_name.split(FLAGS).each (state_flag) ->
        memo[state_flag] = true
    @states.each (state_name, _) =>
      state_flags = state_name.split(FLAGS)
      flags.each (flag, _) =>
        @states[state_name].data[flag] = state_flags.any (state_flag) -> flag is state_flag

  log: (@status) ->
    pad = Array(@STATUS.INITIALIZED.length - @status.length + 1).join(' ')
    tag = "[#{@id}][SM_#{@status}]#{pad}"
    switch @status
      when @STATUS.HALTED
        return @log_debug "#{tag} #{@current} => [#{@event}] => #{@transition?.next}"
      when @STATUS.CHANGED
        return @log_debug "#{tag} #{@previous} => [#{@event}] => #{@current}"
    @log_debug "#{tag} #{@current}"

  log_debug: (msg) ->
    Logger.debug(msg) if @constructor._debug

window.Sm = {}
