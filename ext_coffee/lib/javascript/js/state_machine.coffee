class Js.StateMachine
  CONFIG_IVARS  = ['debug', 'initial', 'terminal']
  CONFIG_HOOKS  = ['state', 'initialize', 'before', 'after', 'on_deny', 'on_stop']
  TRIGGER_HOOKS = ['before', 'after']
  STATE_HOOKS   = ['enter', 'exit']
  STATE_CONFIG  = STATE_HOOKS.add ['data']
  CLONABLE_IVARS = CONFIG_IVARS.add ['states', 'methods', 'transitions', 'paths']
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
    @get_transition(trigger)?

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
      throw new Error('#defer must be called only once in config.(before | triggers[name].before | states[name].exit)')
    @deferred = [@trigger_name, args...]
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
    [@trigger_name, args...] = @deferred
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

  trigger: (trigger, args...) ->
    if @trigger_next
      throw new Error('triggers can be chained, but not queued')
    else if @trigger_name
      @trigger_next = [trigger, args...]
      return
    @trigger_name = trigger
    @run_trigger(args...)
    @reset_trigger()
    @canceled = false
    @status

  inspect: ->
    @paths ||= @transitions.each_with_object {}, (trigger, transitions, memo) ->
      transitions.each (current, transition) ->
        (memo[current] ||= {})[trigger] = transition.next

  #### PRIVATE ####

  run_trigger: (args...) ->
    return @log @STATUS.HALTED if @halted()
    unless @can(@trigger_name)
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
    if (next = @trigger_next)
      @reset_trigger()
      @trigger(next...)

  reset_trigger: ->
    @trigger_next = null
    @trigger_name = null

  # config.before, trigger.before, state.exit
  run_before_hooks: (args...) ->
    @before(this, args...)
    @transition.before(this, args...) unless @halted()
    @states[@current].exit(this, args...) unless @halted()

  # config.after, trigger.after, state.enter
  run_after_hooks: (args...) ->
    @after(this, args...)
    @transition.after(this, args...) unless @halted()
    @states[@current].enter(this, args...) unless @halted()
    @stop(args...) if @finished()

  halted: ->
    @canceled or @stopped or @deferred

  finished: ->
    @current of @terminal

  get_transition: (trigger) ->
    @transitions[trigger][@current]

  set_transition: ->
    @transition = @get_transition(@trigger_name)

  extract_transitions: (config) ->
    @states = {}
    @transitions = {}
    wildcards = {}
    config.triggers?.each (trigger_name, trigger_config) =>
      trigger_hooks = trigger_config.slice(TRIGGER_HOOKS...)
      transitions = trigger_config.except(TRIGGER_HOOKS...)
      transitions.each (current, next) =>
        if next.is_a Object
          [next, transition_hooks] = next.first()
          transition_hooks.each (name, hook) -> hook.super = trigger_hooks[name] ? noop
        hooks = TRIGGER_HOOKS.each_with_object {}, (name, memo) ->
          memo[name] = transition_hooks?[name] ? trigger_hooks[name] ? noop
        @add_default_state(next)
        if current.start_with(WILDCARD)
          except_states =
            if current.include(WITHOUT)
              current.split(WITHOUT, 2).last().split(LIST).map (state) =>
                state = state.strip()
                @add_default_state(state)
                state
            else
              []
          wildcards[trigger_name] = { except_states, next, hooks }
        else
          current.split(LIST).each (state) =>
            state = state.strip()
            @add_default_state(state)
            @add_transition(trigger_name, state, next, hooks)
    @configure_states(config)
    wildcards.each (trigger, { except_states, next, hooks }) =>
      @states.keys().except(except_states...).each (previous_state) =>
        @add_transition(trigger, previous_state, next, hooks)

  configure_states: (config) ->
    @add_default_state(@initial) if @initial?
    @terminal.each (terminal) =>
      @add_default_state(terminal)
    config.states?.each (state_name, state_config) =>
      @add_default_state(state_name)
      state_config.slice(STATE_CONFIG...).each (key, value) =>
        @states[state_name][key] = value

  # data is assumed to be static --> should assign functions or pointers for dynamic usage
  add_default_state: (state) ->
    @states[state] ?= { exit: noop, enter: noop, data: {} }

  add_transition: (trigger, current, next, hooks) ->
    @transitions[trigger] ?= {}
    @transitions[trigger][current] = { next }.merge(hooks)

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
        return @log_debug "#{tag} #{@current} => [#{@trigger_name}] => #{@transition?.next}"
      when @STATUS.CHANGED
        return @log_debug "#{tag} #{@previous} => [#{@trigger_name}] => #{@current}"
    @log_debug "#{tag} #{@current}"

  log_debug: (msg) ->
    Logger.debug(msg) if @debug
