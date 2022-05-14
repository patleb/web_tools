class Turbolinks.Controller
  @cache_size = 10

  constructor: ->
    @html = document.documentElement
    @on_scroll = Turbolinks.throttle(@on_scroll)
    @restoration_data = {}
    @clear_cache()
    @set_progress_bar_delay(500)

  start: ->
    if Turbolinks.supported and not @started
      addEventListener('click', @click_captured, true)
      addEventListener('DOMContentLoaded', @dom_loaded, false)
      addEventListener('scroll', @on_scroll, false)
      @on_scroll()
      @start_history()
      @started = true
      @enabled = true

  disable: ->
    @enabled = false

  stop: ->
    if @started
      removeEventListener('click', @click_captured, true)
      removeEventListener('DOMContentLoaded', @dom_loaded, false)
      removeEventListener('scroll', @on_scroll, false)
      @stop_history()
      @started = false

  clear_cache: ->
    @cache = new Turbolinks.SnapshotCache(@constructor.cache_size)

  visit: (location, options = {}) ->
    location = Turbolinks.Location.wrap(location)
    unless @dispatch_before_visit(location).defaultPrevented
      if @location_is_visitable(location)
        action = options.action ? 'advance'
        @adapter.visitProposedToLocationWithAction(location, action)
      else
        window.location = location

  startVisitToLocationWithAction: (location, action, restoration_id) ->
    if Turbolinks.supported
      restoration_data = @get_restoration_data(restoration_id)
      @start_visit(location, action, { restoration_id, restoration_data })
    else
      window.location = location

  set_progress_bar_delay: (delay) ->
    @progress_bar_delay = delay

  # History

  start_history: ->
    @location = Turbolinks.Location.current_location()
    @restorationIdentifier = Turbolinks.uuid()
    @initial_location = @location
    @initial_restoration_id = @restorationIdentifier
    addEventListener('popstate', @on_popstate, false)
    addEventListener('load', @on_load, false)
    @update_history('replace')

  stop_history: ->
    removeEventListener('popstate', @on_popstate, false)
    removeEventListener('load', @on_load, false)
    delete @initial_location
    delete @initial_restoration_id

  push_history: (location, @restorationIdentifier) ->
    @location = Turbolinks.Location.wrap(location)
    @update_history('push')

  replace_history: (location, @restorationIdentifier) ->
    @location = Turbolinks.Location.wrap(location)
    @update_history('replace')

  update_history: (method) ->
    state = turbolinks: { @restorationIdentifier }
    history["#{method}State"](state, null, @location)

  on_history_popped: (location, @restorationIdentifier) ->
    if @enabled
      restoration_data = @get_restoration_data(@restorationIdentifier)
      @start_visit(location, 'restore', { restoration_id: @restorationIdentifier, restoration_data, history_changed: true })
      @location = Turbolinks.Location.wrap(location)
    else
      @adapter.pageInvalidated()

  # Snapshot cache

  get_cached_snapshot: (location) ->
    @cache.get(location)?.clone()

  should_cache_snapshot: ->
    @get_snapshot().is_cacheable()

  cache_snapshot: ->
    if @should_cache_snapshot()
      @dispatch_before_cache()
      snapshot = @get_snapshot()
      location = @last_rendered_location || Turbolinks.Location.current_location()
      Turbolinks.defer =>
        @cache.put(location, snapshot.clone())

  # Scrolling

  scroll_to_anchor: (name) ->
    if element = @get_anchor(name)
      element.scrollIntoView()
    else
      @scroll_to_position(x: 0, y: 0)

  scroll_to_position: ({ x, y }) ->
    window.scrollTo(x, y)

  # View

  get_root_location: ->
    @get_snapshot().get_root_location()

  get_anchor: (name) ->
    @get_snapshot().get_anchor(name)

  get_snapshot: ->
    Turbolinks.Snapshot.from_element(@html)

  render: ({ snapshot, error, is_preview }, callback) ->
    @mark_as_preview(is_preview)
    if snapshot?
      Turbolinks.SnapshotRenderer.render(this, callback, @get_snapshot(), Turbolinks.Snapshot.wrap(snapshot), is_preview)
    else
      Turbolinks.ErrorRenderer.render(this, callback, error)

  invalidate_view: ->
    @adapter.pageInvalidated()

  view_will_render: (new_body) ->
    @dispatch_before_render(new_body)

  view_rendered: ->
    @last_rendered_location = @current_visit.location
    @dispatch_render()

  # Event handlers

  dom_loaded: =>
    @last_rendered_location = @location
    @dispatch_load()

  click_captured: =>
    removeEventListener('click', @click_bubbled, false)
    addEventListener('click', @click_bubbled, false)

  click_bubbled: (event) =>
    if @enabled and @click_event_is_significant(event)
      if link = @get_visitable_link_for_node(event.target)
        if location = @get_visitable_location_for_link(link)
          unless @dispatch_click(link, location).defaultPrevented
            event.preventDefault()
            action = @get_action_for_link(link)
            @visit(location, {action})

  on_popstate: (event) =>
    if @should_handle_popstate()
      if restoration_id = @get_restoration_id(event)
        @location = Turbolinks.Location.current_location()
        @restorationIdentifier = restoration_id
        @on_history_popped(@location, restoration_id)

  on_load: (event) =>
    Turbolinks.defer =>
      @page_loaded = true

  on_scroll: (event) =>
    @update_position(x: window.pageXOffset, y: window.pageYOffset)

  # Application events

  dispatch_click: (link, location) ->
    Turbolinks.dispatch('turbolinks:click', target: link, data: { url: location.absolute_url }, cancelable: true)

  dispatch_before_visit: (location) ->
    Turbolinks.dispatch('turbolinks:before-visit', data: { url: location.absolute_url }, cancelable: true)

  dispatch_visit: (location, action) ->
    Turbolinks.dispatch('turbolinks:visit', data: { url: location.absolute_url, action })

  dispatch_before_cache: ->
    Turbolinks.dispatch('turbolinks:before-cache')

  dispatch_before_render: (new_body) ->
    Turbolinks.dispatch('turbolinks:before-render', data: { new_body })

  dispatch_render: ->
    Turbolinks.dispatch('turbolinks:render')

  dispatch_load: (timing = {}) ->
    Turbolinks.dispatch('turbolinks:load', data: { url: @location.absolute_url, timing })

  # Private

  start_visit: (location, action, properties) ->
    @current_visit?.cancel()
    @current_visit = @create_visit(location, action, properties)
    @current_visit.start()
    @dispatch_visit(location, action)

  create_visit: (location, action, { restoration_id, restoration_data, history_changed } = {}) ->
    visit = new Turbolinks.Visit(this, location, action)
    visit.restoration_id = restoration_id ? Turbolinks.uuid()
    visit.restoration_data = Turbolinks.copy(restoration_data)
    visit.history_changed = history_changed
    visit.referrer = @location
    visit

  visit_completed: (visit) ->
    @dispatch_load(visit.get_timing())

  click_event_is_significant: (event) ->
    not (
      event.defaultPrevented or
      event.target.isContentEditable or
      event.which > 1 or
      event.altKey or
      event.ctrlKey or
      event.metaKey or
      event.shiftKey
    )

  get_visitable_link_for_node: (node) ->
    if @is_visitable(node)
      Turbolinks.closest(node, 'a[href]:not([target]):not([download])')

  get_visitable_location_for_link: (link) ->
    location = new Turbolinks.Location(link.getAttribute('href'))
    location if @location_is_visitable(location)

  get_action_for_link: (link) ->
    link.getAttribute('data-turbolinks-action') ? 'advance'

  is_visitable: (node) ->
    if container = Turbolinks.closest(node, '[data-turbolinks]')
      container.getAttribute('data-turbolinks') isnt 'false'
    else
      true

  location_is_visitable: (location) ->
    location.is_prefixed_by(@get_root_location()) and location.is_html()

  get_restoration_data: (identifier) ->
    @restoration_data[identifier] ?= {}

  should_handle_popstate: ->
    # Safari dispatches a popstate event after window's load event, ignore it
    @page_loaded or document.readyState is 'complete'

  get_restoration_id: (event) ->
    if event.state
      (event.state.turbolinks || {}).restorationIdentifier
    else if Turbolinks.Location.current_location().is_equal_to(@initial_location)
      @initial_restoration_id

  mark_as_preview: (is_preview) ->
    if is_preview
      @html.setAttribute('data-turbolinks-preview', '')
    else
      @html.removeAttribute('data-turbolinks-preview')

  update_position: (@position) ->
    restoration_data = @get_restoration_data(@restorationIdentifier)
    restoration_data.position = @position
