class Js.StateMachine
  CONFIG_IVARS  = ['debug', 'initial', 'terminal']
  CONFIG_HOOKS  = ['state', 'initialize', 'before', 'after', 'on_deny', 'on_stop']
  TRIGGER_HOOKS = ['before', 'after']
  STATE_HOOKS   = ['enter', 'exit']
  STATE_CONFIG  = STATE_HOOKS.add ['data']
  CLONABLE_IVARS = CONFIG_IVARS.add ['triggers', 'states', 'methods', 'transitions', 'paths']
  WILDCARD = '*'
  WITHOUT = '-'
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
      @extract_transitions(config)
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

  can: (trigger) ->
    !!@get_transition(trigger)?

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

  defer: ->
    unless @deferrable
      throw new Error('#defer must be called only once in config.(before | triggers[name].before | states[name].exit)')
    @deferred = true
    @deferrable = false
    @log @STATUS.DEFERRED

  reject: ->
    return unless @deferred
    @deferred = false
    @reset_trigger()
    @log @STATUS.REJECTED
    @status

  resolve: (args...) ->
    return unless @deferred
    @deferred = false
    @log @STATUS.RESOLVED
    @set_next_state(args...)
    @status

  reset: ->
    @canceled = @stopped = @deferred = @deferrable = false
    @initial = @state(this) unless @state is noop
    @initialize(this)
    @current = @initial
    @log @STATUS.INITIALIZED

  trigger: (trigger, args...) ->
    if @trigger_next
      throw new Error('triggers can be chained, but not queued')
    else if @triggered
      @trigger_next = [trigger, args...]
      return
    @triggered = true
    @triggers[trigger](args...)
    @status

  inspect: ->
    @paths ||= @transitions.each_with_object {}, (trigger, transitions, memo) ->
      transitions.each (from, transition) ->
        (memo[from] ||= {})[trigger] = transition.to

  #### PRIVATE ####

  run_trigger: (trigger, args...) ->
    return @log @STATUS.HALTED if @halted()
    unless @can(trigger)
      @on_deny(this, trigger, args...)
      return @log @STATUS.DENIED
    return @log @STATUS.IDLED if @state(this) is @current
    @set_transition(trigger)
    @deferrable = true
    @run_before_hooks(args...)
    return @log @STATUS.HALTED if @halted()
    @set_next_state(args...)

  set_next_state: (args...) ->
    @current = @transition.to
    @run_after_hooks(args...)
    @log @STATUS.CHANGED
    next = @trigger_next
    @reset_trigger()
    @trigger(next...) if next

  reset_trigger: ->
    @trigger_next = null
    @triggered = false
    @canceled = false

  # config.before, trigger.before, state.exit
  run_before_hooks: (args...) ->
    @before(this, args...)
    @transition.before(this, args...) unless @halted()
    @states[@transition.from].exit(this, args...) unless @halted()

  # config.after, trigger.after, state.enter
  run_after_hooks: (args...) ->
    @after(this, args...)
    @transition.after(this, args...) unless @halted()
    @states[@transition.to].enter(this, args...) unless @halted()
    @stop(args...) if @finished()

  halted: ->
    @canceled or @stopped or @deferred

  finished: ->
    @current of @terminal

  get_transition: (trigger) ->
    @transitions[trigger][@current]

  set_transition: (trigger) ->
    @transition = @get_transition(trigger)

  extract_transitions: (config) ->
    @triggers = {}
    @states = {}
    @transitions = {}
    wildcards = {}
    config.triggers?.each (trigger_name, trigger_config) =>
      hooks = trigger_config.slice(TRIGGER_HOOKS...)
      transitions = trigger_config.except(TRIGGER_HOOKS...)
      transitions.each (from_state, next_state) =>
        @add_default_state(next_state)
        if from_state.start_with(WILDCARD)
          except_states =
            if from_state.include(WITHOUT)
              from_state.split(WITHOUT, 2).last().split(LIST).map (state) =>
                state = state.strip()
                @add_default_state(state)
                state
            else
              []
          wildcards[trigger_name] = { except_states, next_state, hooks }
        else
          from_state.split(LIST).each (state) =>
            state = state.strip()
            @add_default_state(state)
            @add_trigger_transition(trigger_name, state, next_state, hooks)
    @configure_states(config)
    @add_wildards(wildcards)

  configure_states: (config) ->
    @add_default_state(@initial) if @initial?
    @terminal.each (terminal) =>
      @add_default_state(terminal)
    config.states?.each (state_name, state_config) =>
      @add_default_state(state_name)
      state_config.slice(STATE_CONFIG...).each (key, value) =>
        @states[state_name][key] = value

  add_wildards: (wildcards) ->
    wildcards.each (trigger, { except_states, next_state, hooks }) =>
      @states.keys().except(except_states...).each (previous_state) =>
        @add_trigger_transition(trigger, previous_state, next_state, hooks)

  add_trigger_transition: (trigger, from, to, hooks) ->
    @triggers[trigger] = (args...) => @run_trigger(trigger, args...)
    @add_transition(trigger, from, to, hooks)

  # data is assumed to be static --> should assign functions or pointers for dynamic usage
  add_default_state: (state) ->
    @states[state] ?= { exit: noop, enter: noop, data: {} }

  add_transition: (trigger, from, to, { before = noop, after = noop } = {}) ->
    @transitions[trigger] ?= {}
    @transitions[trigger][from] = { trigger, from, to, before, after }

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
        return @log_debug "#{tag} #{@current} => [#{@transition.trigger}] => #{@transition.to}" if @transition
      when @STATUS.CHANGED
        return @log_debug "#{tag} #{@transition.from} => [#{@transition.trigger}] => #{@current}" if @transition
    @log_debug "#{tag} #{@current}"

  log_debug: (msg) ->
    Logger.debug(msg) if @debug
