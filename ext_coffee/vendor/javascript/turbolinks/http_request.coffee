class Turbolinks.HttpRequest
  @NETWORK_FAILURE = 0
  @TIMEOUT_FAILURE = -1
  @CONTENT_TYPE_MISMATCH = -2

  @timeout = 60

  constructor: (@delegate, location, referrer) ->
    @url = Turbolinks.Location.wrap(location).requestURL
    @referrer = Turbolinks.Location.wrap(referrer).absoluteURL
    @createXHR()

  send: ->
    if @xhr and not @sent
      @notifyApplicationBeforeRequestStart()
      nonce = Rails.cspNonce()
      @xhr.setRequestHeader('X-Turbolinks-Nonce', nonce) if nonce
      @setProgress(0)
      @xhr.send()
      @sent = true
      @delegate.requestStarted?()

  cancel: ->
    if @xhr and @sent
      @xhr.abort()

  # XMLHttpRequest events

  requestProgressed: (event) =>
    if event.lengthComputable
      @setProgress(event.loaded / event.total)

  requestLoaded: =>
    @endRequest =>
      contentType = @xhr.getResponseHeader("Content-Type")
      if @contentTypeIsHTML(contentType)
        if 200 <= @xhr.status < 300
          @delegate.requestCompletedWithResponse(@xhr.responseText, @xhr.getResponseHeader("Turbolinks-Location"))
        else
          @failed = true
          @delegate.requestFailedWithStatusCode(@xhr.status, @xhr.responseText)
      else
        @failed = true
        @delegate.requestFailedWithStatusCode(@constructor.CONTENT_TYPE_MISMATCH)

  requestFailed: =>
    @endRequest =>
      @failed = true
      @delegate.requestFailedWithStatusCode(@constructor.NETWORK_FAILURE)

  requestTimedOut: =>
    @endRequest =>
      @failed = true
      @delegate.requestFailedWithStatusCode(@constructor.TIMEOUT_FAILURE)

  requestCanceled: =>
    @endRequest()


  # Application events

  notifyApplicationBeforeRequestStart: ->
    Turbolinks.dispatch("turbolinks:request-start", data: { url: @url, xhr: @xhr })

  notifyApplicationAfterRequestEnd: ->
    Turbolinks.dispatch("turbolinks:request-end", data: { url: @url, xhr: @xhr })

  # Private

  createXHR: ->
    @xhr = new XMLHttpRequest
    @xhr.open("GET", @url, true)
    @xhr.timeout = @constructor.timeout * 1000
    @xhr.setRequestHeader("Accept", "text/html, application/xhtml+xml")
    @xhr.setRequestHeader("Turbolinks-Referrer", @referrer)
    @xhr.onprogress = @requestProgressed
    @xhr.onload = @requestLoaded
    @xhr.onerror = @requestFailed
    @xhr.ontimeout = @requestTimedOut
    @xhr.onabort = @requestCanceled

  endRequest: (callback) ->
    if @xhr
      @notifyApplicationAfterRequestEnd()
      callback?.call(this)
      @destroy()

  setProgress: (progress) ->
    @progress = progress
    @delegate.requestProgressed?(@progress)

  destroy: ->
    @setProgress(1)
    @delegate.requestFinished?()
    @delegate = null
    @xhr = null

  contentTypeIsHTML: (contentType) ->
    (contentType || "").match(/^text\/html|^application\/xhtml\+xml/)
