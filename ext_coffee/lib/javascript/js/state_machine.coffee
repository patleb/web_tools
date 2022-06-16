class Js.StateMachine
  CONFIG_IVARS = ['debug', 'initial', 'terminal']
  CONFIG_HOOKS = ['state', 'initialize', 'before', 'after', 'on_deny', 'on_stop']
  EVENT_HOOKS  = ['before', 'after']
  STATE_HOOKS  = ['enter', 'exit']
  STATE_CONFIG = STATE_HOOKS.add ['data']
  CLONABLE_IVARS = CONFIG_IVARS.add ['states', 'methods', 'transitions', 'paths']
  WILDCARD = '*'
  WITHOUT = ' - '
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
    'DENIED'
    'CHANGED'
    'IDLED'
  ].map((v) -> [v, v]).to_h()

  constructor: (config) ->
    @new(config)

  new: (config) ->
    @STATUS = Js.StateMachine.STATUS
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
      @debug = config.debug ? false
      @initial = config.initial
      @terminal = Array.wrap(config.terminal).to_set()
      @extract_states(config)
      @extract_flags() if config.flags
    @reset()

  dup: ->
    new @constructor this

  config: -> {}

  data: ->
    @states[@current].data

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
      throw new Error("#resume can't be called once the @terminal state is reached")
    @stopped = false
    @reset_trigger()
    @log @STATUS.RESUMED

  defer: (args...) ->
    unless @deferrable
      throw new Error('#defer must be called only once in config.(before | events[name].before | states[name].exit)')
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
    @deferrable = @canceled = @stopped = false
    @initial = @state(this) unless @state is noop
    @initialize(this)
    @previous = null
    @current = @initial
    @log @STATUS.INITIALIZED

  trigger: (event, args...) ->
    if @event_next
      throw new Error('events can be chained, but not queued')
    else if @event
      @event_next = [event, args...]
      return
    @event = event
    @run_event(args...)
    @reset_trigger()
    @canceled = false
    @status

  inspect: ->
    @paths ||= @transitions.each_with_object {}, (event, transitions, memo) ->
      transitions.each (current, transition) ->
        (memo[current] ||= {})[event] = transition.next

  #### PRIVATE ####

  run_event: (args...) ->
    return @log @STATUS.HALTED if @halted()
    unless @has_transition(@event)
      @on_deny(this, args...)
      return @log @STATUS.DENIED
    return @log @STATUS.IDLED if @state(this) is @current
    @set_transition()
    @deferrable = true
    @run_before_hooks(args...)
    return @log @STATUS.HALTED if @halted()
    @set_next_state(args...)

  set_next_state: (args...) ->
    @previous = @current
    @current = @transition.next
    @run_after_hooks(args...)
    @log @STATUS.CHANGED
    if (next = @event_next)
      @reset_trigger()
      @trigger(next...)

  reset_trigger: ->
    @event_next = null
    @event = null

  # config.before, event.before, state.exit
  run_before_hooks: (args...) ->
    @before(this, args...)
    @transition.before(this, args...) unless @halted()
    @states[@current].exit(this, args...) unless @halted()

  # config.after, event.after, state.enter
  run_after_hooks: (args...) ->
    @states[@current].enter(this, args...)
    @transition.after(this, args...) unless @halted()
    @after(this, args...) unless @halted()
    @stop(args...) if @finished()

  halted: ->
    @canceled or @stopped or @deferred

  finished: ->
    @current of @terminal

  has_transition: (event) ->
    @get_transition(event)?

  get_transition: (event) ->
    @transitions[event][@current]

  set_transition: ->
    @transition = @get_transition(@event)

  extract_states: (config) ->
    @states = {}
    @transitions = {}
    wildcards = {}
    config.events?.each (event_name, event_config) =>
      event_hooks = event_config.slice(EVENT_HOOKS...)
      transitions = event_config.except(EVENT_HOOKS...)
      transitions.each (current, next) =>
        if next.is_a Object
          [next, transition_hooks] = next.first()
          transition_hooks.each (name, hook) -> hook.super = event_hooks[name] ? noop
        hooks = EVENT_HOOKS.each_with_object {}, (name, memo) ->
          memo[name] = transition_hooks?[name] ? event_hooks[name] ? noop
        @add_default_state(next)
        if current.start_with WILDCARD
          except_states =
            if current.include WITHOUT
              current.split(WITHOUT, 2).last().split(LIST).map (state) =>
                state = state.strip()
                @add_default_state(state)
                state
            else
              []
          wildcards[event_name] = { except_states, next, hooks }
        else
          current.split(LIST).each (state) =>
            state = state.strip()
            @add_default_state(state)
            @add_transition(event_name, state, next, hooks)
    @add_default_state(@initial) if @initial?
    @terminal.each (terminal) =>
      @add_default_state(terminal)
    config.states?.each (state_name, state_config) =>
      @add_default_state(state_name)
      state_config.slice(STATE_CONFIG...).each (key, value) =>
        @states[state_name][key] = value
    wildcards.each (event, { except_states, next, hooks }) =>
      @states.keys().except(except_states...).each (previous_state) =>
        @add_transition(event, previous_state, next, hooks)

  # data is assumed to be static --> should assign functions or pointers for dynamic usage
  add_default_state: (state) ->
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
    Logger.debug(msg) if @debug
