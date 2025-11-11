class Sm.Hideable extends StateMachine
  config: ->
    state: =>
      if @visible(this) then 'visible' else 'hidden'
    initialize: =>
      @states[@initial].enter(this)
    events:
      toggle:
        visible: 'hidden'
        hidden: 'visible'
    states:
      visible: enter: noop
      hidden: enter: noop
    methods:
      visible: not_implemented
