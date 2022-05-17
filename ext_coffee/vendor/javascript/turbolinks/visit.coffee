class Turbolinks.Visit
  constructor: (@controller, location, @action, @snapshot_html) ->
    @id = Turbolinks.uid()
    @location = Turbolinks.Location.wrap(location)
    @adapter = @controller.adapter
    @state = 'initialized'
    @timing = {}

  start: ->
    if @state is 'initialized'
      @record_timing('visitStart')
      @state = 'started'
      @adapter.visitStarted(this)

  cancel: ->
    if @state is 'started'
      @request?.cancel()
      @cancel_render()
      @state = 'canceled'

  complete: ->
    if @state is 'started'
      @record_timing('visitEnd')
      @state = 'completed'
      @adapter.visitCompleted?(this)
      @controller.visit_completed(this)

  fail: ->
    if @state is 'started'
      @state = 'failed'
      @adapter.visitFailed?(this)

  change_history: ->
    unless @history_changed
      action = if @location.is_equal_to(@referrer) then 'replace' else @action
      method = switch action
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
        if @action is 'restore' or snapshot.is_previewable()
          snapshot

  get_preloaded_snapshot: ->
    Turbolinks.Snapshot.from_string(@snapshot_html) if @snapshot_html

  has_cached_snapshot: ->
    @get_cached_snapshot()?

  load_cached_snapshot: ->
    if snapshot = @get_cached_snapshot()
      is_preview = @should_issue_request()
      @render ->
        @cache_snapshot()
        @controller.render({snapshot, is_preview}, @perform_scroll)
        @adapter.visitRendered?(this)
        @complete() unless is_preview

  load_response: ->
    if @response?
      @render ->
        @cache_snapshot()
        if @request.failed
          @controller.render(error: @response, @perform_scroll)
          @adapter.visitRendered?(this)
          @fail()
        else
          @controller.render(snapshot: @response, @perform_scroll)
          @adapter.visitRendered?(this)
          @complete()

  follow_redirect: ->
    if @redirected_to_location and not @followed_redirect
      @location = @redirected_to_location
      @controller.replace_history(@redirected_to_location, @restoration_id)
      @followed_redirect = true

  # HTTP Request delegate

  request_started: ->
    @record_timing('requestStart')
    @adapter.visitRequestStarted?(this)

  request_completed: (@response, redirected_to_location) ->
    @redirected_to_location = Turbolinks.Location.wrap(redirected_to_location) if redirected_to_location?
    @adapter.visitRequestCompleted(this)

  request_failed: (statusCode, @response) ->
    @adapter.visitRequestFailedWithStatusCode(this, statusCode)

  request_finished: ->
    @record_timing('requestEnd')
    @adapter.visitRequestFinished?(this)

  # Scrolling

  perform_scroll: =>
    unless @scrolled
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
    @timing[name] ?= new Date().getTime()

  get_timing: ->
    Turbolinks.copy(@timing)

  # Private

  should_issue_request: ->
    if @action is 'restore'
      not @has_cached_snapshot()
    else
      true

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
