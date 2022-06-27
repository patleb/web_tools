class Js.ComponentConcept::Element
  constructor: (@element) ->
    @static_data = JSON.safe_parse(@element.getAttribute('data-static')) or {}
    @watch_data = JSON.safe_parse(@element.getAttribute('data-watch')) or []
    @permanent = @element.hasAttribute('data-turbolinks-permanent')
    @scoped = @element.hasAttribute('data-scoped')
    @static = @watch_data.empty()
    @watch = @watch_data.map (name) -> name

  ready: ->
    @static_data.each (name, value) => this[name] = value
    if @static
      @render_element()
    else if @storage_get().empty() and @watch_data.is_a Object
      @storage_set(@watch_data)

  selector: (selector) ->
    scope = "#{@concept.ELEMENTS}[data-element=#{@element_name}]"
    if selector? then "#{scope} #{selector}" else scope

  $: (selector) ->
    @element.$(selector)

  once: (selector, callback) ->
    @element.once(selector, callback)

  find: (selector) ->
    @element.find(selector)

  render: not_implemented

  render_element: (changes = {}) ->
    changes.each (name, [value]) => this[name] = value
    unless (html = @render() ? '').html_safe()
      html = html.safe_text()
    @element.innerHTML = html

  storage_value: (name) ->
    @storage_get(name)[name]

  storage_get: (names...) ->
    if @static
      {}
    else
      Js.Storage.get(@storage_names(names)..., @storage_options())

  storage_set: (inputs) ->
    Js.Storage.set(inputs, @storage_options())

  storage_names: (names) ->
    if not @scoped and names.empty()
      @watch
    else
      names

  storage_options: ->
    if @scoped
      { scope: @uid, @permanent }
    else
      { @permanent }
