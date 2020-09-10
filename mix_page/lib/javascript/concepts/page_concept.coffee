class Js.PageConcept
  global: true

  constants: ->
    UUID: 'ID'

  ready: =>
    @uuid = $(@UUID).data('uuid')
