class Js.Component.Element
  @extend WithReaders

  @readers
    storage_options: ->
      if @scope is 'uid'
        { submitter: this, @permanent, scope: @uid }
      else if @scope
        { submitter: this, @permanent, @scope }
      else
        { submitter: this, @permanent }

  @element: (event_or_target) ->
    Js.Component.elements[@uid(event_or_target)]

  @uid: (event_or_target) ->
    @node(event_or_target).getAttribute('data-uid')

  @node: (event_or_target) ->
    if event_or_target
      target = event_or_target.target ? event_or_target
      target.closest(@selector())
    else
      Rails.find(@selector())

  @selector: (selector) ->
    root = "#{Js.Component.ELEMENTS}[data-element='#{@::element_name}']"
    if selector? then "#{root} #{selector}" else root

  @event: (method_name) ->
    (event) =>
      element = @element(event)
      element[method_name](arguments...)

  constructor: (@node, @uid, index) ->
    static_data = @json_or_function_or_value 'static', {}
    watch_data = @json_or_function_or_value 'watch', []
    @permanent = @node.hasAttribute('data-turbolinks-permanent')
    @refresh = @node.getAttribute('data-refresh')?.to_b() ? @constructor.refresh
    @index = @node.getAttribute('data-index')?.to_i() ? @constructor.index ? index
    @scope = @node.getAttribute('data-scope') or @constructor.scope or ''
    @watch_scopes = {}
    @watch_ivars = []
    @watch = if watch_data.empty()
      false
    else
      if (initialize = watch_data.is_a Object)
        @storage_set watch_data, false
      watch_data.map (name, value) =>
        [scope, ivar] = [Js.Storage.unnamed(@scope, name), Js.Storage.unscoped(name)]
        @watch_scopes[scope] = true
        @watch_ivars.push ivar
        this[ivar] = value if initialize
        name
    static_data.each (name, value) => this[name] = value

  ready: ->
    @render_self true

  $: (selector) ->
    @node.$(selector)

  once: (selector, callback) ->
    @node.once(selector, callback)

  find: (selector) ->
    @node.find(selector)

  find_input: (name) ->
    return unless name?.present()
    @find "[data-bind='#{name}']"

  render: not_implemented

  # NOTE: for usage in #on_update
  render_or_update: (changes, render) ->
    changes = @storage_set changes, false
    if render
      @render_self changes, true
    else
      @update_self changes, true

  render_self: (changes, skip_callbacks = false) ->
    if changes is true
      @storage_get().each (name, value) => this[name] = value
    else if not (changes = @update_self changes, skip_callbacks)
      return false
    else if @rendered and @refresh is false
      return changes
    unless (html = @render() ? '').html_safe()
      html = html.safe_text()
    @node.innerHTML = html
    @rendered = true
    @stale = false
    if (input = @find_input @autofocus)
      input.focus()
      @autofocus = null
    changes

  update_self: (changes, skip_callbacks = false) ->
    changes = changes.slice(@watch_ivars...)
    changed = false
    changes = changes.select (name, [value]) =>
      if not eql this[name], value
        this[name] = value
        changed = true
    @changes = changes.keys()
    if @stale = changed
      if not skip_callbacks
        updates = changes.map (name, [change...]) =>
          [name, [change..., this["on_#{name}_update"]?(change...)]]
        @on_update?(updates.to_h())
      changes
    else
      false

  storage_value: (name) ->
    @storage_get(name)[Js.Storage.unscoped name]

  storage_get: (names...) ->
    return {} unless @watch
    Js.Storage.get(@storage_names(names)..., @storage_options)

  storage_set: (inputs, event = true) ->
    Js.Storage.set(inputs, { event }.merge @storage_options )

  storage_names: (names) ->
    return @watch if @watch and names.empty()
    names

  # Private

  json_or_function_or_value: (name, fallback) ->
    return value if value = JSON.safe_parse(@node.getAttribute("data-#{name}"))
    value = value(this) if (value = @constructor[name])?.is_a Function
    value or fallback
