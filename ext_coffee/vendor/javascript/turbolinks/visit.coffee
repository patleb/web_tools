class Turbolinks.Visit
  { NETWORK_FAILURE, TIMEOUT_FAILURE, CONTENT_TYPE_MISMATCH } = Turbolinks.HttpRequest

  constructor: (@referrer, location, @action, { restoration_id, restoration_data, @same_page, @history_changed, @html, @error }) ->
    @controller = Turbolinks.controller
    @id = Math.uid()
    @restoration_id = restoration_id ? Math.uid()
    @restoration_data = restoration_data.dup()
    @location = Turbolinks.Location.wrap(location)
    @state = 'initialized'
    @timing = {}

  start: ->
    if @state is 'initialized'
      @record_timing('visit_start')
      @state = 'started'
      if @same_page
        @load_anchor()
        @change_history()
        @scroll_to_anchor()
        @controller.dispatch_hashchange(@referrer, @location) if @action isnt 'restore'
      else
        @load_cached_snapshot()
        @issue_request()
        @change_history()

  cancel: ->
    if @state is 'started'
      @request?.cancel()
      @cancel_render()
      @state = 'canceled'

  complete: ->
    if @state is 'started'
      @record_timing('visit_end')
      @state = 'completed'
      @follow_redirect()
      @controller.dispatch_load(@timing.dup())

  fail: ->
    if @state is 'started'
      @state = 'failed'

  change_history: ->
    unless @history_changed
      @action = 'replace' if @location.is_equal_to(@referrer)
      method = switch @action
        when 'replace'            then 'replace_history'
        when 'advance', 'restore' then 'push_history'
      @controller[method](@location, @restoration_id)
      @history_changed = true

  issue_request: ->
    if @should_issue_request() and not @request?
      @request = new Turbolinks.HttpRequest(this, @location, @referrer)
      @request.send()

  get_cached_snapshot: ->
    if snapshot = @controller.get_cached_snapshot(@location) or @get_preloaded_snapshot()
      if not @location.anchor? or snapshot.has_anchor(@location.anchor)
        refresh = @action is 'replace' and @location.is_same_page()
        if @action is 'restore' or not refresh and snapshot.is_previewable()
          snapshot

  get_preloaded_snapshot: ->
    Turbolinks.Snapshot.from_string(@html) if @html

  has_cached_snapshot: ->
    @get_cached_snapshot()?

  load_cached_snapshot: ->
    if snapshot = @get_cached_snapshot()
      preview = @should_issue_request()
      @render ->
        @cache_snapshot()
        @controller.render({ snapshot, @error, preview }, @perform_scroll)
        @complete() unless preview

  load_anchor: ->
    @render ->
      @cache_snapshot()

  load_response: ->
    if @response?
      @render ->
        @cache_snapshot()
        if @request.failed
          @controller.render({ snapshot: @response, error: true }, @perform_scroll)
          @fail()
        else
          @controller.render({ snapshot: @response }, @perform_scroll)
          @complete()

  follow_redirect: ->
    if @redirected_to_location and not @followed_redirect
      @location = @redirected_to_location
      @controller.replace_history(@redirected_to_location, @restoration_id)
      @followed_redirect = true

  # HTTP Request delegate

  request_started: ->
    @record_timing('request_start')
    @controller.request_started(@should_issue_request())

  request_completed: (@response, redirected_to_location) ->
    @redirected_to_location = Turbolinks.Location.wrap(redirected_to_location) if redirected_to_location?
    @load_response()

  request_failed: (status_code, @response) ->
    switch status_code
      when NETWORK_FAILURE, TIMEOUT_FAILURE, CONTENT_TYPE_MISMATCH
        @controller.reload("request_failed[#{status_code}]")
      else
        @load_response()

  request_finished: ->
    @record_timing('request_end')
    @controller.request_finished()

  should_issue_request: ->
    if @action is 'restore'
      not @has_cached_snapshot()
    else
      true

  # Scrolling

  perform_scroll: (snapshot) =>
    if not @scrolled and (not snapshot? or snapshot.is_scrollable())
      if @action is 'restore'
        @scroll_to_restored_position() or @scroll_to_anchor() or @scroll_to_top()
      else
        @scroll_to_anchor() or @scroll_to_top()
      @scrolled = true

  scroll_to_restored_position: ->
    position = @restoration_data?.position
    if position?
      @controller.scroll_to_position(position)
      true

  scroll_to_anchor: ->
    if @location.anchor?
      @controller.scroll_to_anchor(@location.anchor)
      true

  scroll_to_top: ->
    @controller.scroll_to_position(x: 0, y: 0)

  # Instrumentation

  record_timing: (name) ->
    @timing[name] ?= Date.now()

  # Private

  cache_snapshot: ->
    unless @snapshot_cached
      @controller.cache_snapshot()
      @snapshot_cached = true

  render: (callback) ->
    @cancel_render()
    @frame = requestAnimationFrame =>
      @frame = null
      callback.call(this)

  cancel_render: ->
    cancelAnimationFrame(@frame) if @frame
