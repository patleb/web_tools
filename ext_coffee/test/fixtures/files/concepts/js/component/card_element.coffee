class Js.ComponentConcept::CardElement extends Js.ComponentConcept::Element
  document_on: -> [
    'click', @constructor.$('input'), (event) ->
      element = @constructor.element(event.target)
      event.element = element
  ]

  render: ->
    div_ [
      h2_ @banner
      ul_ @players.map (player) -> li_ player
      input_ type: 'text', value: @name, 'data-bind': 'name'
    ]
