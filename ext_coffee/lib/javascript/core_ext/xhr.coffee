ACCEPT_HEADERS =
  '*': '*/*'
  text: 'text/plain'
  html: 'text/html'
  xml: 'application/xml, text/xml'
  json: 'application/json, text/javascript'
  script: 'text/javascript, application/javascript, application/ecmascript, application/x-ecmascript'

class window.XHR
  @cache_size: (@_cache_size) ->

  @cache_add: (type, url, data, response) ->
    @cache ?= lru(@_cache_size or 500)
    type = type.upcase()
    if type is 'GET' and data
      if data.is_a Object
        data = Object.deep_sort(data)
        data = data.to_query()
      url = Rails.push_query(url, data)
      data = undefined
    else if data?.is_a Object
      data = Object.deep_sort(data)
      data = data.to_json()
    cache_key = [type, url, data].join(',')
    if (cache = @cache.get cache_key) is undefined
      if @cache.size is @cache.max
        @cache.evict()
      @cache.set cache_key, response

  @send: (options) ->
    new this(options)

  constructor: (options) ->
    @constructor.cache ?= lru(@constructor._cache_size or 500)
    @xhr = new XMLHttpRequest()
    @send(options)

  abort_if_pending: ->
    return unless @xhr.readyState < XMLHttpRequest.DONE
    @xhr.onreadystatechange = noop
    @xhr.abort()

  status: ->
    if @cache
      200
    else
      @xhr.status

  # Private

  send: (options) ->
    options.url ||= location.href
    options.type = options.type.upcase()
    # append data to url if it's a GET request
    if options.type is 'GET' and options.data
      if options.data.is_a Object
        options.data = Object.deep_sort(options.data) if options.cache
        options.data = options.data.to_query()
      options.url = Rails.push_query(options.url, options.data)
      delete options.data
    options.data_type = '*' unless ACCEPT_HEADERS[options.data_type]?
    options.accept = ACCEPT_HEADERS[options.data_type]
    options.accept += ', */*; q=0.01' if options.data_type isnt '*'
    @xhr.open(options.type, options.url, true)
    @xhr.setRequestHeader('Accept', options.accept)
    # Sending FormData will automatically set Content-Type to multipart/form-data
    if options.data?.is_a String
      @xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
    else if options.data?.is_a Object
      @xhr.setRequestHeader('Content-Type', 'application/json')
      options.data = Object.deep_sort(options.data) if options.cache
      options.data = options.data.to_json()
    unless options.crossDomain
      @xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
      # Add X-CSRF-Token
      Rails.csrf_protection(@xhr)
    @xhr.setRequestHeader('X-Referrer', location.href)
    @xhr.setRequestHeader('Referrer', location.href)
    for name, value of options.headers ? {}
      @xhr.setRequestHeader(name, value)
    @xhr.withCredentials = !!options.withCredentials
    @xhr.onreadystatechange = =>
      @done(options) if @xhr.readyState is XMLHttpRequest.DONE
    if options.before_send? and options.before_send(this, options) is false
      return
    else if options.spinner
      Js.load_spinner()
    if options.cache and (@cache = @constructor.cache.get(@cache_key(options))) isnt undefined # value can be null
      @done(options)
    else if @xhr.readyState is XMLHttpRequest.OPENED
      @xhr.send(options.data)

  done: (options) ->
    response = if @cache isnt undefined then @cache else @process_response()
    if @cache isnt undefined or 200 <= @xhr.status < 300
      if options.cache and @cache is undefined
        if @constructor.cache.size is @constructor.cache.max
          @constructor.cache.evict()
        @constructor.cache.set(@cache_key(options), response)
      options.success?(response, this)
    else
      options.error?(response, this)
      if (alert = options.alert)?.present()
        message = if alert is true
          'Server Error'
        else if alert.is_a Function
          alert(response, this)
        else
          alert
        Flash.alert message
    options.complete?(this)
    Js.clear_spinner() if options.spinner

  process_response: ->
    response = @xhr.response ? @xhr.responseText
    type = @xhr.getResponseHeader('Content-Type')
    if typeof response is 'string' and typeof type is 'string'
      if type.match(/\bjson\b/)
        try response = JSON.parse(response)
      else if type.match(/\b(?:java|ecma)script\b/)
        nonce = Rails.csp_nonce()
        script = document.createElement('script')
        script.setAttribute('nonce', nonce) if nonce
        script.text = response
        document.head.appendChild(script).parentNode.removeChild(script)
      else if type.match(/\b(xml|html|svg)\b/)
        parser = new DOMParser()
        type = type.replace(/;.+/, '') # remove something like ';charset=utf-8'
        head = response.indexOf('<head>') isnt -1
        unless not (try response = parser.parseFromString(response, type)) or head
          response = response.body
    response

  cache_key: (options) ->
    @_cache_key ||= [options.type, options.url, options.data].join(',')
