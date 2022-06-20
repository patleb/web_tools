class Js.ComponentConcept::Element
  getters: ->
    data_scoped: -> @element.hasAttribute('data-scoped')
    data_watch: -> JSON.parse(@element.getAttribute('data-watch'))
    watch: ->
      names = []
      @data_watch().each (name) -> names.push name
      names

  constructor: (@element) ->

  ready: ->
    return if @get_data().present()
    return unless (inputs = @data_watch()).is_a Object
    @set_data(inputs)

  render: not_implemented

  render_element: (changes) ->
    changes.each (name, [value]) => this[name] = value
    unless (html = @render() ? '').html_safe()
      html = html.safe_text()
    @element.innerHTML = html

  get_value: (name) ->
    @get_data(name)[name]

  get_data: (names...) ->
    if @data_scoped()
      return Js.Storage.get({ scope: @uid }) if names.empty()
      Js.Storage.get(names..., { scope: @uid })
    else
      names = @watch() if names.empty()
      Js.Storage.get(names...)

  set_data: (inputs) ->
    if @data_scoped()
      Js.Storage.set(inputs, { scope: @uid })
    else
      Js.Storage.set(inputs)
