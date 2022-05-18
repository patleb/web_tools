class Turbolinks.Controller
  @cache_size = 10

  constructor: ->
    @html = document.documentElement
    @on_scroll = Turbolinks.throttle(@on_scroll)
    @restoration_data = {}
    @clear_cache()
    @set_progress_bar_delay(500)

  start: ->
    unless Turbolinks.supported
      return addEventListener('DOMContentLoaded', @dispatch_load, false)
    unless @started
      addEventListener('submit', @search_captured, true)
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
      removeEventListener('submit', @search_captured, true)
      removeEventListener('click', @click_captured, true)
      removeEventListener('DOMContentLoaded', @dom_loaded, false)
      removeEventListener('scroll', @on_scroll, false)
      @stop_history()
      @started = false

  clear_cache: ->
    @cache = new Turbolinks.SnapshotCache(@constructor.cache_size)

  visit: (location, { action = 'advance', html } = {}) ->
    if @is_reloadable(location)
      return window.location = location
    location = Turbolinks.Location.wrap(location)
    unless @dispatch_before_visit(location, action).defaultPrevented
      if @location_is_visitable(location, action)
        @adapter.visitProposedToLocationWithAction(location, action, html)
      else
        window.location = location

  startVisitToLocationWithAction: (location, action, restoration_id, html) ->
    if Turbolinks.supported
      restoration_data = @get_restoration_data(restoration_id)
      @start_visit(location, action, { restoration_id, restoration_data, html })
    else
      window.location = location

  set_progress_bar_delay: (delay) ->
    @progress_bar_delay = delay

  # History

  start_history: ->
    @location = Turbolinks.Location.current_location()
    @restorationIdentifier = Turbolinks.uid()
    @initial_location = @location
    @initial_restoration_id = @restorationIdentifier
    addEventListener('beforeunload', @on_beforeunload, false)
    addEventListener('popstate', @on_popstate, false)
    addEventListener('load', @on_load, false)
    @update_history('replace')

  stop_history: ->
    removeEventListener('beforeunload', @on_beforeunload, false)
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
    history["#{method}State"](state, '', @location.toString())

  on_history_popped: (location, @restorationIdentifier) ->
    if @enabled
      restoration_data = @get_restoration_data(@restorationIdentifier)
      @start_visit(location, 'restore', { restoration_id: @restorationIdentifier, restoration_data, history_changed: true })
      @location = Turbolinks.Location.wrap(location)
    else
      @adapter.pageInvalidated('turbolinks_disabled')

  # Snapshot cache

  get_cached_snapshot: (location) ->
    @cache.get(location)?.clone()

  should_cache_snapshot: ->
    @get_snapshot().is_cacheable()

  cache_snapshot: ->
    if @should_cache_snapshot()
      unless @dispatch_before_cache().defaultPrevented
        snapshot = @get_snapshot()
        location = @last_rendered_location or Turbolinks.Location.current_location()
        Turbolinks.defer =>
          @cache.put(location, snapshot.clone())
        @dispatch_cache()

  # Scrolling

  scroll_to_anchor: (name) ->
    if element = @get_anchor(name)
      element.scrollIntoView()
      @focus(element)
    else
      @scroll_to_position(x: 0, y: 0)

  scroll_to_position: ({ x, y }) ->
    window.scrollTo(x, y)

  focus: (element) ->
    if element instanceof HTMLElement
      if element.hasAttribute('tabindex')
        element.focus()
      else
        element.setAttribute('tabindex', '-1')
        element.focus()
        element.removeAttribute('tabindex')

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

  render_view: (new_body, callback) ->
    unless @dispatch_before_render(new_body).defaultPrevented
      callback()
      @last_rendered_location = @current_visit.location
      @dispatch_render(new_body)

  page_invalidated: (reason) ->
    @adapter.pageInvalidated(reason)

  # Event handlers

  dom_loaded: =>
    unless @scroll_restoration_was
      @scroll_restoration_was = history.scrollRestoration ? 'auto'
      history.scrollRestoration = 'manual'
    @last_rendered_location = @location
    @dispatch_load()

  search_captured: =>
    removeEventListener('submit', @search_bubbled, false)
    addEventListener('submit', @search_bubbled, false)

  search_bubbled: (event) =>
    form = event.target
    if @enabled and Rails.matches(form, 'form[method=get]:not([data-remote=true])')
      if @is_visitable(document.activeElement)
        location = Turbolinks.Location.wrap(form.action)
        params = Rails.serializeElement(form, document.activeElement)
        location.push_query(params)
        unless @dispatch_search(form, location).defaultPrevented
          event.preventDefault()
          event.stopPropagation()
          @visit(location)

  click_captured: =>
    removeEventListener('click', @click_bubbled, false)
    addEventListener('click', @click_bubbled, false)

  click_bubbled: (event) =>
    if @enabled and @click_event_is_significant(event)
      target = event.composedPath?()[0] or event.target
      if link = @get_visitable_link(target)
        if location = @get_visitable_location(link)
          unless @dispatch_click(link, location).defaultPrevented
            event.preventDefault()
            action = @get_action(link)
            @visit(location, { action })

  on_beforeunload: =>
    if @scroll_restoration_was
      history.scrollRestoration = @scroll_restoration_was
      delete @scroll_restoration_was

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

  dispatch_search: (form, location) ->
    Turbolinks.dispatch('turbolinks:search', target: form, data: { url: location.absolute_url }, cancelable: true)

  dispatch_click: (link, location) ->
    Turbolinks.dispatch('turbolinks:click', target: link, data: { url: location.absolute_url }, cancelable: true)

  dispatch_before_visit: (location, action) ->
    Turbolinks.dispatch('turbolinks:before-visit', data: { url: location.absolute_url, action }, cancelable: true)

  dispatch_visit: (location, action) ->
    Turbolinks.dispatch('turbolinks:visit', data: { url: location.absolute_url, action })

  dispatch_before_cache: ->
    Turbolinks.dispatch('turbolinks:before-cache', cancelable: true)

  dispatch_cache: ->
    Turbolinks.dispatch('turbolinks:cache')

  dispatch_before_render: (new_body) ->
    Turbolinks.dispatch('turbolinks:before-render', data: { new_body }, cancelable: true)

  dispatch_render: (new_body) ->
    Turbolinks.dispatch('turbolinks:render', data: { new_body })

  dispatch_load: (timing = {}) ->
    Turbolinks.dispatch('turbolinks:load', data: { url: @location?.absolute_url, timing })

  # Private

  start_visit: (location, action, properties) ->
    @current_visit?.cancel()
    @current_visit = @create_visit(location, action, properties)
    @current_visit.start()
    @dispatch_visit(location, action)

  create_visit: (location, action, { restoration_id, restoration_data, history_changed, html } = {}) ->
    visit = new Turbolinks.Visit(this, location, action, html)
    visit.restoration_id = restoration_id ? Turbolinks.uid()
    visit.restoration_data = Turbolinks.copy(restoration_data)
    visit.history_changed = history_changed
    visit.referrer = @location
    visit

  visit_completed: (visit) ->
    @dispatch_load(visit.get_timing())

  click_event_is_significant: (event) ->
    not (
      event.defaultPrevented or
      event.target?.isContentEditable or
      event.which > 1 or
      event.altKey or
      event.ctrlKey or
      event.metaKey or
      event.shiftKey
    )

  get_visitable_link: (node) ->
    if @is_visitable(node)
      Turbolinks.closest(node, 'a[href]:not([target^=_]):not([download])')

  get_visitable_location: (link) ->
    url = link.getAttribute('href')
    return if @is_reloadable(url)
    location = new Turbolinks.Location(url)
    location if @location_is_visitable(location, @get_action(link))

  get_action: (link) ->
    link.getAttribute('data-turbolinks-action') ? 'advance'

  is_visitable: (node) ->
    if container = Turbolinks.closest(node, '[data-turbolinks]')
      container.getAttribute('data-turbolinks') isnt 'false'
    else
      true

  is_reloadable: (url) ->
    not (url instanceof Turbolinks.Location) and url?.charAt(0) is '?'

  location_is_visitable: (location, action) ->
    location.is_prefixed_by(@get_root_location()) and location.is_html() and
      (not location.is_same_page_anchor() or action is 'replace')

  get_restoration_data: (restoration_id) ->
    @restoration_data[restoration_id] ?= {}

  should_handle_popstate: ->
    # Safari dispatches a popstate event after window's load event, ignore it
    (@page_loaded or document.readyState is 'complete') and
      @restorationIdentifier isnt event.state?.turbolinks?.restorationIdentifier

  get_restoration_id: (event) ->
    if event.state
      (event.state.turbolinks ? {}).restorationIdentifier
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
