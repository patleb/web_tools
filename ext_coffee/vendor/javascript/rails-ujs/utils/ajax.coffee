ACCEPT_HEADERS =
  '*': '*/*'
  text: 'text/plain'
  html: 'text/html'
  xml: 'application/xml, text/xml'
  json: 'application/json, text/javascript'
  script: 'text/javascript, application/javascript, application/ecmascript, application/x-ecmascript'

Rails.merge
  ajax: (options) ->
    options = prepare_options(options)
    xhr = create_xhr options, ->
      response = process_response(xhr.response ? xhr.responseText, xhr.getResponseHeader('Content-Type'))
      if 200 <= xhr.status < 300
        options.success?(response, xhr.status, xhr)
      else
        options.error?(response, xhr.status, xhr)
      options.complete?(xhr, xhr.status)

    if options.before_send? and not options.before_send(xhr, options)
      return false

    if xhr.readyState is XMLHttpRequest.OPENED
      xhr.send(options.data)

  # Default way to get an element's href. May be overridden at Rails.href.
  href: (element) -> element.href

  # Determines if the request is a cross domain request.
  is_cross_domain: (url) ->
    old_url = document.createElement('a')
    old_url.href = location.href
    new_url = document.createElement('a')
    try
      new_url.href = url
      # If URL protocol is false or is a string containing a single colon
      # *and* host are false, assume it is not a cross-domain request
      # (should only be the case for IE7 and IE compatibility mode).
      # Otherwise, evaluate protocol and host of the URL against the origin
      # protocol and host.
      not (
        (not new_url.protocol or new_url.protocol is ':') and not new_url.host or
        "#{old_url.protocol}//#{old_url.host}" is "#{new_url.protocol}//#{new_url.host}"
      )
    catch e
      # If there is an error parsing the URL, assume it is crossDomain.
      true

  split_at_anchor: (url) ->
    if hash = url.hash
      anchor = hash.slice(1)
    else if anchor_match = url.match(/#(.*)$/)
      anchor = anchor_match[1]
    if anchor?
      [url.slice(0, -(anchor.length + 1)), anchor]
    else
      [url, null]

  push_query: (url, string) ->
    return url unless string
    [url, anchor] = Rails.split_at_anchor(url)
    if url.indexOf('?') isnt -1
      url += "&#{string.replace(/^&/, '')}"
    else
      url += "?#{string.replace(/^\?/, '')}"
    if anchor?
      "#{url}##{anchor}"
    else
      url

prepare_options = (options) ->
  options.url ||= location.href
  options.type = options.type.toUpperCase()
  # append data to url if it's a GET request
  if options.type is 'GET' and options.data
    options.url = Rails.push_query(options.url, options.data)
  # Use "*" as default data_type
  options.data_type = '*' unless ACCEPT_HEADERS[options.data_type]?
  options.accept = ACCEPT_HEADERS[options.data_type]
  options.accept += ', */*; q=0.01' if options.data_type isnt '*'
  options

create_xhr = (options, done) ->
  xhr = new XMLHttpRequest()
  # Open and set up xhr
  xhr.open(options.type, options.url, true)
  xhr.setRequestHeader('Accept', options.accept)
  # Set Content-Type only when sending a string
  # Sending FormData will automatically set Content-Type to multipart/form-data
  if typeof options.data is 'string'
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
  else if options.data?.is_a Object
      xhr.setRequestHeader('Content-Type', 'application/json')
      options.data = JSON.stringify(options.data)
  unless options.crossDomain
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
    # Add X-CSRF-Token
    Rails.csrf_protection(xhr)
  xhr.setRequestHeader('X-Referrer', location.href)
  xhr.setRequestHeader('Referrer', location.href)
  for name, value of options.headers ? {}
    xhr.setRequestHeader(name, value)
  xhr.withCredentials = !!options.withCredentials
  xhr.onreadystatechange = ->
    done(xhr) if xhr.readyState is XMLHttpRequest.DONE
  xhr

process_response = (response, type) ->
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
