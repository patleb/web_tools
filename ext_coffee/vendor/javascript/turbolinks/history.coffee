class Turbolinks.History
  constructor: (@delegate) ->

  start: ->
    unless @started
      @location = Turbolinks.Location.currentLocation()
      @initialLocation = @location
      @initialRestorationIdentifier = @restorationIdentifier
      addEventListener("popstate", @onPopState, false)
      addEventListener("load", @onPageLoad, false)
      @started = true

  stop: ->
    if @started
      removeEventListener("popstate", @onPopState, false)
      removeEventListener("load", @onPageLoad, false)
      delete @initialLocation
      delete @initialRestorationIdentifier
      @started = false

  push: (location, restorationIdentifier) ->
    location = Turbolinks.Location.wrap(location)
    @update("push", location, restorationIdentifier)

  replace: (location, restorationIdentifier) ->
    location = Turbolinks.Location.wrap(location)
    @update("replace", location, restorationIdentifier)

  # Event handlers

  onPopState: (event) =>
    if @shouldHandlePopState()
      if restorationIdentifier = @restorationIdentifierForPopState(event)
        @location = Turbolinks.Location.currentLocation()
        @restorationIdentifier = restorationIdentifier
        @delegate.historyPoppedToLocationWithRestorationIdentifier(@location, restorationIdentifier)

  onPageLoad: (event) =>
    Turbolinks.defer =>
      @pageLoaded = true

  # Private

  shouldHandlePopState: ->
    # Safari dispatches a popstate event after window's load event, ignore it
    @pageIsLoaded()

  pageIsLoaded: ->
    @pageLoaded or document.readyState is "complete"

  restorationIdentifierForPopState: (event) =>
    if event.state
      return (event.state.turbolinks || {}).restorationIdentifier
    if @poppedToInitialEntry(event)
      @initialRestorationIdentifier

  poppedToInitialEntry: (event) ->
    !event.state && Turbolinks.Location.currentLocation().isEqualTo(@initialLocation)

  update: (method, location, restorationIdentifier) ->
    state = turbolinks: {restorationIdentifier}
    history[method + "State"](state, null, location)
    @location = location
    @restorationIdentifier = restorationIdentifier
