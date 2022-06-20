class Js.ComponentConcept::CardElement extends Js.ComponentConcept::Element
  render: ->
    div_ [
      h2_ @banner
      ul_ @players.map (player) -> li_ player
      input_ type: 'text', value: @name, data: { watch: 'name' }
    ]
