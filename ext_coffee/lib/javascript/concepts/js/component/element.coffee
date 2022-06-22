class Js.ComponentConcept::Element
  getters: ->
    data_permanent: -> @element.hasAttribute('data-turbolinks-permanent')
    data_scoped: -> @element.hasAttribute('data-scoped')
    data_watch: -> JSON.parse(@element.getAttribute('data-watch'))
    watch: ->
      names = []
      @data_watch().each (name) -> names.push name
      names

  constructor: (@element) ->

  ready: ->
    return if @storage_get().present()
    return unless (inputs = @data_watch()).is_a Object
    @storage_set(inputs)

  render: not_implemented

  render_element: (changes) ->
    changes.each (name, [value]) => this[name] = value
    unless (html = @render() ? '').html_safe()
      html = html.safe_text()
    @element.innerHTML = html

  storage_value: (name) ->
    @storage_get(name)[name]

  storage_get: (names...) ->
    Js.Storage.get(@storage_names(names)..., @storage_options())

  storage_set: (inputs) ->
    Js.Storage.set(inputs, @storage_options())

  storage_names: (names) ->
    if not @data_scoped() and names.empty()
      @watch()
    else
      names

  storage_options: ->
    if @data_scoped()
      { scope: @uid, permanent: @data_permanent() }
    else
      { permanent: @data_permanent() }
