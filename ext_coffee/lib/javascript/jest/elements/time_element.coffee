class Js.Component.TimeElement extends Js.Component.Element
  render: ->
    div_ [
      time_ @time, datetime: @time, 'data-strftime': '%Y-%m-%d %H:%M:%S %Z'
    ]
