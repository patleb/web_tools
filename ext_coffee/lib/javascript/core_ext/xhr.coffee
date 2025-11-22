ACCEPT_HEADERS =
  '*': '*/*'
  text: 'text/plain'
  html: 'text/html'
  xml: 'application/xml, text/xml'
  json: 'application/json, text/javascript'
  script: 'text/javascript, application/javascript, application/ecmascript, application/x-ecmascript'

class window.XHR
  constructor: (options) ->
    @xhr = new XMLHttpRequest()
    @build options, =>
      response = @process_response()
      if 200 <= @xhr.status < 300
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
    if options.before_send? and options.before_send(this, options) is false
      return false
    else if options.spinner
      Js.load_spinner()
    if @xhr.readyState is XMLHttpRequest.OPENED
      @xhr.send(options.data)

  abort_if_pending: ->
    return unless @xhr.readyState < XMLHttpRequest.DONE
    @xhr.onreadystatechange = noop
    @xhr.abort()

  # Private

  build: (options, done) ->
    options.url ||= location.href
    options.type = options.type.toUpperCase()
    # append data to url if it's a GET request
    if options.type is 'GET' and options.data
      options.url = Rails.push_query(options.url, options.data)
    options.data_type = '*' unless ACCEPT_HEADERS[options.data_type]?
    options.accept = ACCEPT_HEADERS[options.data_type]
    options.accept += ', */*; q=0.01' if options.data_type isnt '*'
    @xhr.open(options.type, options.url, true)
    @xhr.setRequestHeader('Accept', options.accept)
    # Sending FormData will automatically set Content-Type to multipart/form-data
    if typeof options.data is 'string'
      @xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
    else if options.data?.is_a Object
      @xhr.setRequestHeader('Content-Type', 'application/json')
      options.data = JSON.stringify(options.data)
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
      done(@xhr) if @xhr.readyState is XMLHttpRequest.DONE

  process_response: (response, type) ->
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
