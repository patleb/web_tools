class Js.StateMachine.Hideable extends Js.StateMachine
  VISIBLE_STATES = { true: 'visible', false: 'hidden' }

  config: =>
    is_visible: not_implemented
    initialize: =>
      @initial = @visible_state()
      @states[@initial].enter(this)
    before: =>
      @cancel() if @visible_state() is @current
    triggers:
      toggle:
        visible: 'hidden'
        hidden: 'visible'
    states:
      visible: enter: noop
      hidden: enter: noop

  constructor: (config) ->
    super(@config().deep_merge(config))

  visible_state: =>
    VISIBLE_STATES[@config.is_visible()]
