class Js.PageConcept
  global: true

  constants: ->
    UUID: 'ID'

  ready_once: =>
    @uuid = $(@UUID).data('uuid')

  ready: =>
    @uuid = $(@UUID).data('uuid')
