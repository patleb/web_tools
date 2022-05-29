SUBMITABLE_BUTTON = 'button, input[type="button"], input[type="submit"], input[type="image"]'
window.last_button = null

do ->
  if 'submitter' of Event::
    return
  else if 'SubmitEvent' of window
    if /Apple Computer/.test(navigator.vendor)
      # See https://bugs.webkit.org/show_bug.cgi?id=229660
      prototype = window.SubmitEvent::
    else
      return
  prototype ?= window.Event::

  document.addEventListener 'click', (event) ->
    window.last_button = event.target.closest(SUBMITABLE_BUTTON)
  , true

  Object.defineProperty prototype, 'submitter',
    configurable: true,
    enumerable: true,
    get: ->
      return @_submitter if @_submitter
      candidates = [document.activeElement, window.last_button]
      window.last_button = null
      for candidate in candidates
        if candidate?.matches(SUBMITABLE_BUTTON) and @target is candidate.form
          return @_submitter = candidate
