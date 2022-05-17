### Turbo 7 iOS/Android adapters
  Turbo.registerAdapter(this)
  Turbo.navigator.restorationIdentifier
  Turbo.navigator.locationWithActionIsSamePage
  Turbo.navigator.startVisit(location, restorationIdentifier, options)
  Turbo.navigator.view.scrollToAnchorFromLocation
###
### Turbolinks 5 iOS/Android adapters
  Turbolinks.controller.adapter = this
  Turbolinks.controller.startVisitToLocationWithAction
  Turbolinks.controller.restorationIdentifier
###
class Turbolinks.BrowserAdapter
  { NETWORK_FAILURE, TIMEOUT_FAILURE, CONTENT_TYPE_MISMATCH } = Turbolinks.HttpRequest

  constructor: (@controller) ->
    @progress_bar = new Turbolinks.ProgressBar

  visitProposedToLocationWithAction: (location, action) ->
    @controller.startVisitToLocationWithAction(location, action)

  visitStarted: (visit) ->
    visit.load_cached_snapshot()
    visit.issue_request()
    visit.change_history()

  visitRequestStarted: (visit) ->
    @progress_bar.set_value(0)
    if visit.has_cached_snapshot() or visit.action isnt 'restore'
      @progress_bar_timeout = setTimeout(@show_progress_bar, @controller.progress_bar_delay)
    else
      @show_progress_bar()

  visitRequestCompleted: (visit) ->
    visit.load_response()

  visitRequestFailedWithStatusCode: (visit, status_code) ->
    switch status_code
      when NETWORK_FAILURE, TIMEOUT_FAILURE, CONTENT_TYPE_MISMATCH
        @reload("request_failed[#{status_code}]")
      else
        visit.load_response()

  visitRequestFinished: (visit) ->
    @progress_bar.set_value(1)
    @hide_progress_bar()

  visitCompleted: (visit) ->
    visit.follow_redirect()

  pageInvalidated: (reason) ->
    @reload(reason)

  # Private

  show_progress_bar: =>
    @progress_bar.show()

  hide_progress_bar: ->
    @progress_bar.hide()
    clearTimeout(@progress_bar_timeout)

  reload: (reason) ->
    @dispatch_reload(reason)
    window.location.reload()

  dispatch_reload: (reason) ->
    Turbolinks.dispatch('turbolinks:reload', data: { reason })
