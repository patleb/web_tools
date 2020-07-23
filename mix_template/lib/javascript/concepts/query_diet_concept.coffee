class Js.QueryDietConcept
  constants: ->
    QUERY_DIET: '#query_diet'

  document_on: => [
    'click', @QUERY_DIET, (event) =>
      $(@QUERY_DIET).remove()
  ]
