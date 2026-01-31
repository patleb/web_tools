class Js.Component.Element
  @extend WithReaders

  @readers
    storage_options: ->
      if @_scope is 'uid'
        { submitter: this, permanent: @_permanent, scope: @_uid }
      else if @_scope
        { submitter: this, permanent: @_permanent, scope: @_scope }
      else
        { submitter: this, permanent: @_permanent }

  @first: ->
    Js.Component.elements.find (uid, e) => e.constructor is this

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

  @handler: (method_name) ->
    (event) =>
      element = @element(event)
      element[method_name](arguments...)

  constructor: (@_node, @_uid, index) ->
    static_data = @json_or_function_or_value 'static', {}
    watch_data = @json_or_function_or_value 'watch', []
    @_permanent = @_node.hasAttribute('data-turbolinks-permanent')
    @_refresh = @_node.getAttribute('data-refresh')?.to_b() ? @constructor.refresh
    @_index = @_node.getAttribute('data-index')?.to_i() ? @constructor.index ? index
    @_scope = @_node.getAttribute('data-scope') or @constructor.scope or ''
    @_watch_scopes = {}
    @_watch_ivars = []
    @_watch = if watch_data.empty()
      false
    else
      if (initialize = watch_data.is_a Object)
        @storage_set watch_data, event: false
      watch_data.select_map (name, value) =>
        [scope, ivar] = [Js.Storage.unnamed(@_scope, name), Js.Storage.unscoped(name)]
        @_watch_scopes[scope] = true
        return unless ivar
        @_watch_ivars.push ivar
        this[ivar] = value if initialize
        name
    static_data.each (name, value) => this[name] = value
    @_node.add_class 'no-transition' unless @_refresh is false

  ready: ->
    @render_self true

  $: (selector) ->
    @_node.$(selector)

  once: (selector, callback) ->
    @_node.once(selector, callback)

  fire: (name, data) ->
    @_node.fire(name, data)

  find: (selector) ->
    @_node.find(selector)

  find_input: (name, value = null) ->
    return unless name?.present()
    selector = "[data-bind='#{name}']"
    selector += "[value='#{value}']" if value?
    @find selector

  render: not_implemented

  # NOTE: for usage in #on_update
  update: (changes, { render, stale, autofocus } = {}) ->
    changes = @storage_set changes, { event: false, autofocus }
    if render
      @render_self changes, true
    else
      @update_self changes, true
    @_stale = stale if stale?
    @storage_fire changes

  render_self: (changes, skip_callbacks = false) ->
    if changes is true
      @storage_get().each (name, value) => this[name] = value
    else if not (changes = @update_self changes, skip_callbacks)
      return false
    else if @_rendered and @_refresh is false
      return changes
    @before_render?(changes)
    unless (html = @render() ? '').html_safe()
      html = html.safe_text()
    @_node.innerHTML = html
    @_rendered = true
    @_stale = false
    if (input = @find_input @_autofocus...)
      input.focus()
      input.cursor_end(true)
      @_autofocus_was = @_autofocus if @_refresh
      @_autofocus = null
    @after_render?(changes)
    changes

  update_self: (changes, skip_callbacks = false) ->
    scopes = changes.except(@_watch_ivars...)
    changes = changes.slice(@_watch_ivars...).each_select (name, [value]) =>
      if not eql this[name], value
        this[name] = value
        true
    changes = if @_stale = changes.present()
      if not skip_callbacks
        updates = changes.each_map (name, [change...]) =>
          [name, [change..., this["on_update_#{name}"]?(change...)]]
        @on_update?(updates.to_h())
      changes
    else if skip_callbacks
      {}
    else
      false
    if not skip_callbacks and scopes.present()
      updates = scopes.each_map (name, [change...]) =>
        [name, [change..., this["on_watch_#{name}"]?(change...)]]
      @on_watch?(updates.to_h())
    changes

  storage_changes: (name, options = {}) ->
    Js.Storage.get_changes(name, @storage_options.merge options)

  storage_change: (name, options = {}) ->
    Js.Storage.get_change(name, @storage_options.merge options)

  storage_value: (name, options = {}) ->
    Js.Storage.get_value(name, @storage_options.merge options)

  storage_has: (name, options = {}) ->
    Js.Storage.has_value(name, @storage_options.merge options)

  storage_get: (names...) ->
    return {} unless @_watch
    options = names.extract_options()
    Js.Storage.get(@storage_names(names)..., @storage_options.merge options)

  storage_set: (inputs, options = {}) ->
    [@_autofocus, @_autofocus_was] = [@_autofocus_was, null] if options.autofocus
    Js.Storage.set(inputs, @storage_options.merge options)

  storage_fire: (changes, options = {}) ->
    Js.Storage.fire(changes, @storage_options.merge options)
    changes

  storage_names: (names) ->
    return @_watch if @_watch and names.empty()
    names

  # Private

  json_or_function_or_value: (name, fallback) ->
    return value if value = JSON.safe_parse(@_node.getAttribute("data-#{name}"))
    value = value(this) if (value = @constructor[name])?.is_a Function
    value or fallback
