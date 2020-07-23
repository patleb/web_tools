class Js.StateMachine.Hideable extends Js.StateMachine
  constructor: (name, settings) ->
    @visible_states = { true: 'visible', false: 'hidden' }
    settings = settings.deep_merge(
      initialize: =>
        @initial = "as_#{@visible_state()}"
      triggers:
        ready:
          as_visible: 'visible'
          as_hidden: 'hidden'
        toggle:
          visible: 'hidden'
          hidden: 'visible'
    )
    super(name, settings)
    @trigger('ready') if settings.ready

  visible_state: =>
    @visible_states[@settings.visible_on()]

  run_trigger: (trigger, args...) =>
    if @visible_state() == @current
      return @STATUS.DENIED
    super(trigger, args...)
