class Js.Component.CardElement extends Js.Component.Element
  events: -> [
    'click', @constructor.selector('input'), (event) ->
      element = @constructor.element(event)
      event.element = element
  ]

  render: ->
    div_ [
      h2_ @banner
      ul_ @players.map (player) -> li_ player
      input_ type: 'text', value: @name, 'data-bind': 'name'
    ]
