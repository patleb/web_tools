XMLHttpRequest.define_methods
  abort_if_pending: ->
    return unless @readyState < XMLHttpRequest.DONE
    @onreadystatechange = noop
    @abort()

window.XHR = XMLHttpRequest
