# TODO https://github.com/basecamp/local_time
# _.reduce($._data( $(document)[0], "events" ), function(sum, value, key) {return sum + value.length;}, 0);

class RailsAdmin.MainConcept
  global: true

  constants: ->
    MODEL: 'ID'
    ACTION: 'ID'
    SAVE_FORM: '#new_action > form, #edit_action > form, #clone_action > form'

  document_on: => [
    'keydown', @SAVE_FORM, (event) ->
      event.preventDefault() if $.is_submit_key(event)
  ]

  ready: =>
    @model_name = $(@MODEL).data('model')
    @action_name = $(@ACTION).data('action')
    @model_key = @model_name?.underscore()
    ['index', 'chart', 'export', 'trash', 'sort'].each (name) => @["#{name}_action"] = (@action_name == name)

  cookie_get: (key) =>
    Js.Cookie.get_json(@model_name)[key] ? {}

  cookie_set: (key, value) =>
    Js.Cookie.set_json(@model_name, key, value)

  cookie_remove: (keys...) =>
    Js.Cookie.remove_json(@model_name, keys...)
