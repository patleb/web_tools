class Js.StateMachine
  TRIGGER_HOOKS = ['skip_before', 'skip_after', 'before', 'after']
  STATE_HOOKS = ['skip_before', 'skip_after', 'exit', 'enter']
  WILDCARD = '*'
  WITHOUT = '-'
  LIST = ','
  FLAGS = '-'

  @STATUS: {
    INITIALIZED: 'INITIALIZED'
    HALTED: 'HALTED'
    DENIED: 'DENIED'
    CHANGED: 'CHANGED'
  }

  constructor: (@name, @settings) ->
    @STATUS = @constructor.STATUS
    @CANCEL = @STATUS.HALTED
    @trace = @settings.trace ? false
    @initial = @settings.initial
    @terminal = @settings.terminal
    ['initialize', 'before', 'after', 'denied'].each (hook) =>
      @[hook] = @settings[hook] || ->
    @extract_transitions() if @settings.triggers
    @extract_flags() if @settings.flags
    @reset()

  data: =>
    @states[@current].data

  is: (state) =>
    if state.is_a(RegExp)
      !!@current.match(state)
    else
      @current == state

  can: (trigger) =>
    !!@get_transition(trigger)?

  stop: =>
    @stopped = true

  resume: =>
    @stopped = false

  defer: =>
    @deferred = true

  reject: =>
    @deferred = false

  resolve: (args...) =>
    return unless @deferred
    @reject()
    @set_next_state(args...)
    @STATUS.CHANGED

  reset: (args...) =>
    @resume()
    @reject()
    @initialize(this, args...)
    @current = @initial
    @log_initialized()
    @STATUS.INITIALIZED

  trigger: (trigger, args...) =>
    @triggers[trigger](args...)

  inspect: =>
    @transposition ||= @transitions.each_with_object {}, (trigger, transitions, h) ->
      transitions.each (from, transition) ->
        (h[from] ||= {})[trigger] = transition.to

  #### PRIVATE ####

  run_trigger: (trigger, args...) =>
    if @halted()
      return @STATUS.HALTED

    unless @can(trigger)
      @denied(this, args...)
      @log_denied(trigger)
      return @STATUS.DENIED

    @set_transition(trigger)

    unless @run_before_hooks(args...)
      @log_halted()
      return @STATUS.HALTED

    @set_next_state(args...)
    @STATUS.CHANGED

  run_before_hooks: (args...) =>
    from_state = @states[@transition.from].hooks
    return false if @before(this, args...) == @CANCEL unless @transition.skip_before || from_state.skip_before
    return false if @halted()
    return false if @transition.before(this, args...) == @CANCEL
    return false if @halted()
    return false if from_state.exit(this, args...) == @CANCEL
    return false if @halted()
    true

  run_after_hooks: (args...) =>
    to_state = @states[@transition.to].hooks
    to_state.enter(this, args...)
    @transition.after(this, args...)
    @after(this, args...) unless @transition.skip_after || to_state.skip_after
    @stop() if @terminal == @current

  halted: =>
    @stopped || @deferred

  get_transition: (trigger) =>
    @transitions[trigger][@current]

  set_transition: (trigger) =>
    @transition = @get_transition(trigger)

  set_next_state: (args...) =>
    @current = @transition.to
    @log_changed()
    @run_after_hooks(args...)

  extract_transitions: =>
    @triggers = {}
    @states = {}
    @transitions = {}
    wildcards = {}
    @settings.triggers.each (trigger_name, trigger_settings) =>
      hooks = trigger_settings.slice(TRIGGER_HOOKS)
      transitions = trigger_settings.except(TRIGGER_HOOKS)
      transitions.each (from_state, next_state) =>
        @add_default_state(next_state)
        if from_state.start_with(WILDCARD)
          except_states =
            if from_state.includes(WITHOUT)
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
    @configure_states()
    @add_wildards(wildcards)

  configure_states: =>
    @add_default_state(@initial) if @initial?
    @add_default_state(@terminal) if @terminal?
    @settings.states?.each (state_name, state_settings) =>
      @add_default_state(state_name)
      state_settings.slice(STATE_HOOKS).each (hook_name, hook) =>
        @states[state_name].hooks[hook_name] = hook
      @states[state_name].data = state_settings.data || {}

  add_wildards: (wildcards) =>
    wildcards.each (trigger, { except_states, next_state, hooks }) =>
      @states.keys().except(except_states).each (previous_state) =>
        @add_trigger_transition(trigger, previous_state, next_state, hooks)

  add_trigger_transition: (trigger, from, to, hooks) =>
    @triggers[trigger] = (args...) => @run_trigger(trigger, args...)
    @add_transition(trigger, from, to, hooks)

  add_default_state: (state) =>
    @states[state] ?= {
      hooks: {
        skip_before: false
        skip_after: false
        exit: ->
        enter: ->
      }
      data: {}
    }

  add_transition: (trigger, from, to, hooks) =>
    @transitions[trigger] ?= {}
    @transitions[trigger][from] = {
      trigger: trigger
      from: from
      to: to
      skip_before: hooks.skip_before || false
      skip_after: hooks.skip_after || false
      before: hooks.before || ->
      after: hooks.after || ->
    }

  extract_flags: =>
    flags = @states.each_with_object {}, (state_name, _, h) ->
      state_name.split(FLAGS).each (state_flag) ->
        h[state_flag] = true
    @states.each (state_name, _) =>
      state_flags = state_name.split(FLAGS)
      flags.each (flag, _) =>
        @states[state_name].data[flag] = state_flags.any (state_flag) -> flag == state_flag

  log_initialized: =>
    @debug_state_machine "[SM_INITIALIZED][#{@name}] #{@current}"
  log_denied: (trigger) =>
    @debug_state_machine "[SM_DENIED]     [#{@name}][#{trigger}] #{@current}"
  log_halted: =>
    @debug_state_machine "[SM_HALTED]     [#{@name}][#{@transition.trigger}] #{@current} => #{@transition.to}"
  log_changed: =>
    @debug_state_machine "[SM_CHANGED]    [#{@name}][#{@transition.trigger}] #{@transition.from} => #{@current}"

  debug_state_machine: (msg) ->
    Logger.debug(msg) if @trace
