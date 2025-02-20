class Turbolinks.HttpRequest
  @NETWORK_FAILURE = 0
  @TIMEOUT_FAILURE = -1
  @CONTENT_TYPE_MISMATCH = -2

  @timeout = 60

  constructor: (@visit, location, referrer) ->
    @url = Turbolinks.Location.wrap(location).request_url
    @referrer = Turbolinks.Location.wrap(referrer).absolute_url
    @create_xhr()

  send: ->
    if @xhr and not @sent
      @dispatch_request_start()
      nonce = Rails.csp_nonce()
      @xhr.setRequestHeader('X-Xhr-Nonce', nonce) if nonce
      @xhr.send()
      @sent = true
      @visit.request_started()

  cancel: ->
    if @xhr and @sent
      @xhr.abort()

  # XMLHttpRequest events

  request_loaded: =>
    @end_request =>
      contentType = @xhr.getResponseHeader('Content-Type')
      if @is_html(contentType)
        if 200 <= @xhr.status < 300
          @visit.request_completed(@xhr.responseText, @xhr.getResponseHeader('X-Xhr-Redirect'))
        else
          @failed = true
          @visit.request_failed(@xhr.status, @xhr.responseText)
      else
        @failed = true
        @visit.request_failed(@constructor.CONTENT_TYPE_MISMATCH)

  request_failed: =>
    @end_request =>
      @failed = true
      @visit.request_failed(@constructor.NETWORK_FAILURE)

  request_timed_out: =>
    @end_request =>
      @failed = true
      @visit.request_failed(@constructor.TIMEOUT_FAILURE)

  request_canceled: =>
    @end_request()

  # Application events

  dispatch_request_start: ->
    Turbolinks.dispatch('turbolinks:request-start', data: { @url, @xhr })

  dispatch_request_end: ->
    Turbolinks.dispatch('turbolinks:request-end', data: { @url, @xhr })

  # Private

  create_xhr: ->
    @xhr = new XMLHttpRequest
    @xhr.open('GET', @url, true)
    @xhr.timeout = @constructor.timeout * 1000
    @xhr.setRequestHeader('Accept', 'text/html, application/xhtml+xml')
    @xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
    @xhr.setRequestHeader('X-Referrer', @referrer)
    @xhr.setRequestHeader('Referrer', @referrer)
    @xhr.onload = @request_loaded
    @xhr.onerror = @request_failed
    @xhr.ontimeout = @request_timed_out
    @xhr.onabort = @request_canceled

  end_request: (callback) ->
    if @xhr
      @dispatch_request_end()
      callback?.call(this)
      @destroy()

  destroy: ->
    @visit.request_finished()
    @visit = null
    @xhr = null

  is_html: (content_type = '') ->
    content_type.match(/^text\/html|^application\/xhtml\+xml/)
