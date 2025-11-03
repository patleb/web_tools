class Js.Component::Element
  @$: (selector) ->
    scope = "#{@::concept.ELEMENTS}[data-element=#{@::element_name}]"
    if selector? then "#{scope} #{selector}" else scope

  @element: (target) ->
    element = target.closest(@$())
    @::concept.elements[element.getAttribute('data-uid')]

  constructor: (@node) ->
    @static_data = JSON.safe_parse(@node.getAttribute('data-static')) or {}
    @watch_data = JSON.safe_parse(@node.getAttribute('data-watch')) or []
    @permanent = @node.hasAttribute('data-turbolinks-permanent')
    @scoped = @node.hasAttribute('data-scoped')
    @static = @watch_data.empty()
    @watch = @watch_data.map (name) -> name

  ready: ->
    @static_data.each (name, value) => this[name] = value
    if @static or @storage_get().present() or @watch_data.is_a Array
      @render_element()
    else
      @storage_set(@watch_data)

  $: (selector) ->
    @node.$(selector)

  once: (selector, callback) ->
    @node.once(selector, callback)

  find: (selector) ->
    @node.find(selector)

  render: not_implemented

  render_element: (changes = {}) ->
    changes.each (name, [value]) => this[name] = value
    unless (html = @render() ? '').html_safe()
      html = html.safe_text()
    @node.innerHTML = html

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
      { submitter: this, @permanent, scope: @uid }
    else
      { submitter: this, @permanent }
