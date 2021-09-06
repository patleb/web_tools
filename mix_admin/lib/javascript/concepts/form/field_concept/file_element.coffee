class RailsAdmin.Form.FieldConcept::FileElement
  constants: ->
    WRAPPER: 'CLASS'
    REMOVE: 'CLASS'
    TOGGLE: 'CLASS'
    THUMBNAIL: 'CLASS'

  document_on: => [
    'click', @REMOVE, (event, target) =>
      target.siblings('[type=checkbox]').click()
      target.siblings(@TOGGLE).toggle('slow')
      target.toggleClass('btn-danger btn-info')
  ]

  constructor: (@input) ->
    @wrapper = @input.closest(@WRAPPER)
    # TODO can't have 'accessors' if already used in parent concept?
    @thumbnail = @wrapper.find_first(@THUMBNAIL)
