class Js.ComponentConcept::TimeElement extends Js.ComponentConcept::Element
  render: ->
    div_ [
      time_ @time, datetime: @time, 'data-format': '%Y-%m-%d %H:%M:%S %Z'
    ]
