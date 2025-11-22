class Js.Component.Element
  @extend WithReaders

  @readers
    storage_options: ->
      if @scope
        { submitter: this, @permanent, @scope }
      else
        { submitter: this, @permanent }

  @$: (selector) ->
    scope = "#{Js.Component.ELEMENTS}[data-element='#{@::element_name}']"
    if selector? then "#{scope} #{selector}" else scope

  @element: (target) ->
    element = target.closest(@$())
    Js.Component.elements[element.getAttribute('data-uid')]

  constructor: (@node) ->
    @static_data = JSON.safe_parse(@node.getAttribute('data-static')) or {}
    @watch_data = JSON.safe_parse(@node.getAttribute('data-watch')) or []
    @permanent = @node.hasAttribute('data-turbolinks-permanent')
    @scope = @node.getAttribute('data-scope') or ''
    @static = @watch_data.empty()
    @watch = @watch_data.map (name) -> name

  ready: ->
    @static_data.each (name, value) => this[name] = value
    storage_data = @storage_get()
    if @static or storage_data.present() or @watch_data.is_a Array
      storage_data.each (name, value) => this[name] = value
      @render_self()
    else
      @storage_set(@watch_data)

  $: (selector) ->
    @node.$(selector)

  once: (selector, callback) ->
    @node.once(selector, callback)

  find: (selector) ->
    @node.find(selector)

  find_input: (name) ->
    return unless name?.present()
    if @scope
      @find "[data-bind='#{name}'][data-scope='#{@scope}']"
    else
      @find "[data-bind='#{name}']"

  render: not_implemented

  render_or_update: (changes, render) ->
    changes = @storage_set changes, false
    if render
      @render_self changes
    else
      @update_self changes
    @stale = false
    changes

  render_self: (changes = {}) ->
    changes.each (name, [value]) => this[name] = value
    unless (html = @render() ? '').html_safe()
      html = html.safe_text()
    @node.innerHTML = html
    @rendered = true
    @stale = false
    return unless (input = @find_input @autofocus)
    input.focus()
    @autofocus = null

  update_self: (changes)->
    changed = false
    changes.each (name, [value]) =>
      changed ||= not eql this[name], value
      this[name] = value
    @stale = changed

  storage_value: (name) ->
    @storage_get(name)[name]

  storage_get: (names...) ->
    if @static
      {}
    else
      Js.Storage.get(@storage_names(names)..., @storage_options)

  storage_set: (inputs, event = true) ->
    Js.Storage.set(inputs, { event }.merge @storage_options )

  storage_names: (names) ->
    if @scope is '' and names.empty()
      @watch
    else
      names
