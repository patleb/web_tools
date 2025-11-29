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

  constructor: (@node) ->
    static_data = JSON.safe_parse(@node.getAttribute('data-static')) or {}
    watch_data = JSON.safe_parse(@node.getAttribute('data-watch')) or []
    @permanent = @node.hasAttribute('data-turbolinks-permanent')
    @scope = @node.getAttribute('data-scope') or ''
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

  # NOTE: for usage in #on_storage_change
  render_or_update: (changes, render) ->
    changes = @storage_set changes, false
    if render
      @render_self changes
    else
      @update_self changes

  render_self: (changes) ->
    if changes is true
      @storage_get().each (name, value) => this[name] = value
    else if not (changes = @update_self changes)
      return false
    unless (html = @render() ? '').html_safe()
      html = html.safe_text()
    @node.innerHTML = html
    @rendered = true
    @stale = false
    if (input = @find_input @autofocus)
      input.focus()
      @autofocus = null
    changes

  update_self: (changes) ->
    changes = changes.slice(@watch_ivars...)
    changed = false
    changes = changes.select (name, [value]) =>
      if not eql this[name], value
        this[name] = value
        changed = true
    if @stale = changed
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
