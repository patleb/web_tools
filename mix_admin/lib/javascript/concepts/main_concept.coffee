# TODO https://github.com/basecamp/local_time
# _.reduce($._data( $(document)[0], "events" ), function(sum, value, key) {return sum + value.length;}, 0);

class RailsAdmin.MainConcept
  global: true

  constants: ->
    MODEL: 'ID'
    ACTION: 'ID'
    PANEL: 'CLASS'
    SAVE_FORM: '#new_action > form, #edit_action > form, #clone_action > form'

  document_on: => [
    'click.continue', @PANEL, @throttled_click_panel

    'keydown', @SAVE_FORM, (event) ->
      event.preventDefault() if $.is_submit_key(event)
  ]

  constructor: ->
    @throttled_click_panel = _.throttle(@on_click_panel, 800)

  ready: =>
    @model_name = $(@MODEL).data('model')
    @action_name = $(@ACTION).data('action')
    @model_key = @model_name?.underscore()
    ['index', 'chart', 'export', 'trash'].each (name) => @["#{name}_action"] = (@action_name == name)

    $(@PANEL).has('i.fa.fa-chevron-right').each$ (panel) ->
      panel.siblings('.control-group').hide()

  on_click_panel: (event, target) ->
    if target.has('i.fa.fa-chevron-down').length
      target.children('i').toggleClass('fa-chevron-down fa-chevron-right')
      target.siblings('.control-group:visible').hide('slow')
    else if target.has('i.fa.fa-chevron-right').length
      target.children('i').toggleClass('fa-chevron-down fa-chevron-right')
      target.siblings('.control-group:hidden').show('slow')

  cookie_get: (key) =>
    Js.Cookie.get_json(@model_name)[key] ? {}

  cookie_set: (key, value) =>
    Js.Cookie.set_json(@model_name, key, value)

  cookie_remove: (keys...) =>
    Js.Cookie.remove_json(@model_name, keys...)
