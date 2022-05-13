class Turbolinks.Controller
  constructor: ->
    @view = new Turbolinks.View this
    @scrollManager = new Turbolinks.ScrollManager this
    @restorationData = {}
    @clearCache()
    @setProgressBarDelay(500)

  start: ->
    if Turbolinks.supported and not @started
      addEventListener("click", @clickCaptured, true)
      addEventListener("DOMContentLoaded", @domLoaded, false)
      @scrollManager.start()
      @startHistory()
      @started = true
      @enabled = true

  disable: ->
    @enabled = false

  stop: ->
    if @started
      removeEventListener("click", @clickCaptured, true)
      removeEventListener("DOMContentLoaded", @domLoaded, false)
      @scrollManager.stop()
      @stopHistory()
      @started = false

  clearCache: ->
    @cache = new Turbolinks.SnapshotCache 10

  visit: (location, options = {}) ->
    location = Turbolinks.Location.wrap(location)
    if @applicationAllowsVisitingLocation(location)
      if @locationIsVisitable(location)
        action = options.action ? "advance"
        @adapter.visitProposedToLocationWithAction(location, action)
      else
        window.location = location

  startVisitToLocationWithAction: (location, action, restorationIdentifier) ->
    if Turbolinks.supported
      restorationData = @getRestorationDataForIdentifier(restorationIdentifier)
      @startVisit(location, action, {restorationIdentifier, restorationData})
    else
      window.location = location

  setProgressBarDelay: (delay) ->
    @progressBarDelay = delay

  # History

  startHistory: ->
    @location = Turbolinks.Location.currentLocation()
    @restorationIdentifier = Turbolinks.uuid()
    @initialLocation = @location
    @initialRestorationIdentifier = @restorationIdentifier
    addEventListener("popstate", @onPopState, false)
    addEventListener("load", @onPageLoad, false)
    @updateHistory('replace')

  stopHistory: ->
    removeEventListener("popstate", @onPopState, false)
    removeEventListener("load", @onPageLoad, false)
    delete @initialLocation
    delete @initialRestorationIdentifier

  pushHistoryWithLocationAndRestorationIdentifier: (location, @restorationIdentifier) ->
    @location = Turbolinks.Location.wrap(location)
    @updateHistory('push')

  replaceHistoryWithLocationAndRestorationIdentifier: (location, @restorationIdentifier) ->
    @location = Turbolinks.Location.wrap(location)
    @updateHistory('replace')

  updateHistory: (method) ->
    state = turbolinks: { restorationIdentifier: @restorationIdentifier }
    history[method + "State"](state, null, @location)

  # History delegate

  historyPoppedToLocationWithRestorationIdentifier: (location, @restorationIdentifier) ->
    if @enabled
      restorationData = @getRestorationDataForIdentifier(@restorationIdentifier)
      @startVisit(location, "restore", {@restorationIdentifier, restorationData, historyChanged: true})
      @location = Turbolinks.Location.wrap(location)
    else
      @adapter.pageInvalidated()

  # Snapshot cache

  getCachedSnapshotForLocation: (location) ->
    @cache.get(location)?.clone()

  shouldCacheSnapshot: ->
    @view.getSnapshot().isCacheable()

  cacheSnapshot: ->
    if @shouldCacheSnapshot()
      @notifyApplicationBeforeCachingSnapshot()
      snapshot = @view.getSnapshot()
      location = @lastRenderedLocation || Turbolinks.Location.currentLocation()
      Turbolinks.defer =>
        @cache.put(location, snapshot.clone())

  # Scrolling

  scrollToAnchor: (anchor) ->
    if element = @view.getElementForAnchor(anchor)
      @scrollToElement(element)
    else
      @scrollToPosition(x: 0, y: 0)

  scrollToElement: (element) ->
    @scrollManager.scrollToElement(element)

  scrollToPosition: (position) ->
    @scrollManager.scrollToPosition(position)

  # Scroll manager delegate

  scrollPositionChanged: (scrollPosition) ->
    restorationData = @getRestorationDataForIdentifier(@restorationIdentifier)
    restorationData.scrollPosition = scrollPosition

  # View

  render: (options, callback) ->
    @view.render(options, callback)

  viewInvalidated: ->
    @adapter.pageInvalidated()

  viewWillRender: (newBody) ->
    @notifyApplicationBeforeRender(newBody)

  viewRendered: ->
    @lastRenderedLocation = @currentVisit.location
    @notifyApplicationAfterRender()

  # Event handlers

  domLoaded: =>
    @lastRenderedLocation = @location
    @notifyApplicationAfterPageLoad()

  clickCaptured: =>
    removeEventListener("click", @clickBubbled, false)
    addEventListener("click", @clickBubbled, false)

  clickBubbled: (event) =>
    if @enabled and @clickEventIsSignificant(event)
      if link = @getVisitableLinkForNode(event.target)
        if location = @getVisitableLocationForLink(link)
          if @applicationAllowsFollowingLinkToLocation(link, location)
            event.preventDefault()
            action = @getActionForLink(link)
            @visit(location, {action})

  onPopState: (event) =>
    if @shouldHandlePopState()
      if restorationIdentifier = @restorationIdentifierForPopState(event)
        @location = Turbolinks.Location.currentLocation()
        @restorationIdentifier = restorationIdentifier
        @historyPoppedToLocationWithRestorationIdentifier(@location, restorationIdentifier)

  onPageLoad: (event) =>
    Turbolinks.defer =>
      @pageLoaded = true

  # Application events

  applicationAllowsFollowingLinkToLocation: (link, location) ->
    event = @notifyApplicationAfterClickingLinkToLocation(link, location)
    not event.defaultPrevented

  applicationAllowsVisitingLocation: (location) ->
    event = @notifyApplicationBeforeVisitingLocation(location)
    not event.defaultPrevented

  notifyApplicationAfterClickingLinkToLocation: (link, location) ->
    Turbolinks.dispatch("turbolinks:click", target: link, data: { url: location.absoluteURL }, cancelable: true)

  notifyApplicationBeforeVisitingLocation: (location) ->
    Turbolinks.dispatch("turbolinks:before-visit", data: { url: location.absoluteURL }, cancelable: true)

  notifyApplicationAfterVisitingLocation: (location, action) ->
    Turbolinks.dispatch("turbolinks:visit", data: { url: location.absoluteURL, action })

  notifyApplicationBeforeCachingSnapshot: ->
    Turbolinks.dispatch("turbolinks:before-cache")

  notifyApplicationBeforeRender: (newBody) ->
    Turbolinks.dispatch("turbolinks:before-render", data: {newBody})

  notifyApplicationAfterRender: ->
    Turbolinks.dispatch("turbolinks:render")

  notifyApplicationAfterPageLoad: (timing = {}) ->
    Turbolinks.dispatch("turbolinks:load", data: { url: @location.absoluteURL, timing })

  # Private

  startVisit: (location, action, properties) ->
    @currentVisit?.cancel()
    @currentVisit = @createVisit(location, action, properties)
    @currentVisit.start()
    @notifyApplicationAfterVisitingLocation(location, action)

  createVisit: (location, action, {restorationIdentifier, restorationData, historyChanged} = {}) ->
    visit = new Turbolinks.Visit this, location, action
    visit.restorationIdentifier = restorationIdentifier ? Turbolinks.uuid()
    visit.restorationData = Turbolinks.copyObject(restorationData)
    visit.historyChanged = historyChanged
    visit.referrer = @location
    visit

  visitCompleted: (visit) ->
    @notifyApplicationAfterPageLoad(visit.getTimingMetrics())

  clickEventIsSignificant: (event) ->
    not (
      event.defaultPrevented or
      event.target.isContentEditable or
      event.which > 1 or
      event.altKey or
      event.ctrlKey or
      event.metaKey or
      event.shiftKey
    )

  getVisitableLinkForNode: (node) ->
    if @nodeIsVisitable(node)
      Turbolinks.closest(node, "a[href]:not([target]):not([download])")

  getVisitableLocationForLink: (link) ->
    location = new Turbolinks.Location link.getAttribute("href")
    location if @locationIsVisitable(location)

  getActionForLink: (link) ->
    link.getAttribute("data-turbolinks-action") ? "advance"

  nodeIsVisitable: (node) ->
    if container = Turbolinks.closest(node, "[data-turbolinks]")
      container.getAttribute("data-turbolinks") isnt "false"
    else
      true

  locationIsVisitable: (location) ->
    location.isPrefixedBy(@view.getRootLocation()) and location.isHTML()

  getRestorationDataForIdentifier: (identifier) ->
    @restorationData[identifier] ?= {}

  shouldHandlePopState: ->
    # Safari dispatches a popstate event after window's load event, ignore it
    @pageLoaded or document.readyState is "complete"

  restorationIdentifierForPopState: (event) ->
    if event.state
      (event.state.turbolinks || {}).restorationIdentifier
    else if Turbolinks.Location.currentLocation().isEqualTo(@initialLocation)
      @initialRestorationIdentifier
