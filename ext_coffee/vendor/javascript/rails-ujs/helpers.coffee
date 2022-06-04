# DOM helpers

# get and set data on a given element using "expando properties"
# See: https://developer.mozilla.org/en-US/docs/Glossary/Expando
expando = '_ujs_data'

Rails.get = (element, key) ->
  element[expando]?[key]

Rails.set = (element, key, value) ->
  element[expando] ?= {}
  element[expando][key] = value

# a wrapper for document.querySelectorAll
# returns an Array
Rails.$ = (selector) ->
  Array::slice.call(document.querySelectorAll(selector))

# CSP helpers

csp_nonce = null

Rails.load_csp_nonce = ->
  csp_nonce = document.querySelector('meta[name=csp-nonce]')?.content

# Returns the Content-Security-Policy nonce for inline scripts.
Rails.csp_nonce = ->
  csp_nonce ? Rails.load_csp_nonce()

# CSRF helpers

# Up-to-date Cross-Site Request Forgery token
Rails.csrf_token = ->
  meta = document.querySelector('meta[name=csrf-token]')
  meta and meta.content

# URL param that must contain the CSRF token
Rails.csrf_param = ->
  meta = document.querySelector('meta[name=csrf-param]')
  meta and meta.content

# Make sure that every Ajax request sends the CSRF token
Rails.csrf_protection = (xhr) ->
  token = Rails.csrf_token()
  xhr.setRequestHeader('X-CSRF-Token', token) if token?

# Make sure that all forms have actual up-to-date tokens (cached forms contain old ones)
Rails.refresh_csrf_tokens = ->
  token = Rails.csrf_token()
  param = Rails.csrf_param()
  if token? and param?
    Rails.$("form input[name='#{param}']").forEach (input) -> input.value = token

# Event helpers

# Triggers a custom event on an element and returns false if the event result is false
# obj::
#   a native DOM element
# name::
#   string that corresponds to the event you want to trigger
#   e.g. 'click', 'submit'
# data::
#   data you want to pass when you dispatch an event
Rails.fire = (obj, name, data) ->
  event = new CustomEvent(name, bubbles: true, cancelable: true, detail: data)
  obj.dispatchEvent(event)
  !event.defaultPrevented

# Helper function, needed to provide consistent behavior in IE
Rails.stop_everything = (e) ->
  Rails.fire(e.target, 'ujs:everythingStopped')
  e.preventDefault()
  e.stopPropagation()
  e.stopImmediatePropagation()

# Delegates events
# to a specified parent `element`, which fires event `handler`
# for the specified `selector` when an event of `event_type` is triggered
# element::
#   parent element that will listen for events e.g. document
# selector::
#   CSS selector; or an object that has `selector` and `exclude` properties (see: Rails.matches)
# event_type::
#   string representing the event e.g. 'submit', 'click'
# handler::
#   the event handler to be called
Rails.delegate = (element, selector, event_type, handler) ->
  element.addEventListener event_type, (e) ->
    target = e.target
    target = target.parentNode until not (target instanceof Element) or target.matches(selector)
    if target instanceof Element and handler.call(target, e) is false
      e.preventDefault()
      e.stopPropagation()

Rails.document_on = (event_type, selector, handler) ->
  Rails.delegate(document, selector, event_type, handler)

Rails.is_meta_click = (event, method, data) ->
  (event.button? and event.button isnt 0) or (
    event.target?.isContentEditable or
    event.which > 1 or
    event.altKey or
    event.ctrlKey or
    event.metaKey or
    event.shiftKey
  ) and (method or 'GET').toUpperCase() is 'GET' and not data

# Form helpers

to_array = (e) -> Array::slice.call(e)

Rails.serialize_element = (element, additional_param) ->
  inputs = [element]
  inputs = to_array(element.elements) if element.matches('form')
  params = []
  inputs.forEach (input) ->
    return if !input.name or input.disabled or input.hasAttribute('disabled')
    return if input.matches('fieldset[disabled] *')
    return if input.name is additional_param?.name
    if input.matches('select')
      to_array(input.options).forEach (option) ->
        params.push(name: input.name, value: option.value) if option.selected
    else if input.checked or input.type not in ['radio', 'checkbox', 'submit']
      params.push(name: input.name, value: input.value)
  params.push(additional_param) if additional_param
  params.map (param) ->
    if param.name?
      "#{encodeURIComponent(param.name)}=#{encodeURIComponent(param.value)}"
    else
      param
  .join('&')

# Helper function that returns form elements that match the specified CSS selector
# If form is actually a "form" element this will return associated elements outside the from that have
# the html form attribute set
Rails.form_elements = (form, selector) ->
  if form.matches('form')
    to_array(form.elements).filter (el) -> el.matches(selector)
  else
    to_array(form.querySelectorAll(selector))

# AJAX helpers

ACCEPT_HEADERS =
  '*': '*/*'
  text: 'text/plain'
  html: 'text/html'
  xml: 'application/xml, text/xml'
  json: 'application/json, text/javascript'
  script: 'text/javascript, application/javascript, application/ecmascript, application/x-ecmascript'

Rails.ajax = (options) ->
  options = prepare_options(options)
  xhr = create_xhr options, ->
    response = process_response(xhr.response ? xhr.responseText, xhr.getResponseHeader('Content-Type'))
    if 200 <= xhr.status < 300
      options.success?(response, xhr.status, xhr)
    else
      options.error?(response, xhr.status, xhr)
    options.complete?(xhr, xhr.status)

  if options.beforeSend? && !options.beforeSend(xhr, options)
    return false

  if xhr.readyState is XMLHttpRequest.OPENED
    xhr.send(options.data)

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
  unless options.crossDomain
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
    # Add X-CSRF-Token
    Rails.csrf_protection(xhr)
  xhr.setRequestHeader('X-Referrer', location.href)
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
      try response = parser.parseFromString(response, type)
  response

# Default way to get an element's href. May be overridden at Rails.href.
Rails.href = (element) -> element.href

# Determines if the request is a cross domain request.
Rails.is_cross_domain = (url) ->
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

# Misc helpers

Rails.id = 0

Rails.uid = ->
  pad = '0000000000000'
  time = (new Date().getTime()).toString()
  time = String(time + pad).substring(0, pad.length)
  pad = '000'
  num = Rails.id++
  num = String(pad + num).slice(-pad.length)
  "#{time}#{num}"

Rails.uuid = ->
  result = ''
  for i in [1..36]
    if i in [9, 14, 19, 24]
      result += '-'
    else if i is 15
      result += '4'
    else if i is 20
      result += (Math.floor(Math.random() * 4) + 8).toString(16)
    else
      result += Math.floor(Math.random() * 15).toString(16)
  result

Rails.split_at_anchor = (url) ->
  if hash = url.hash
    anchor = hash.slice(1)
  else if anchor_match = url.match(/#(.*)$/)
    anchor = anchor_match[1]
  if anchor?
    [url.slice(0, -(anchor.length + 1)), anchor]
  else
    [url, null]

Rails.push_query = (url, string) ->
  return url unless string
  [url, anchor] = Rails.split_at_anchor(url)
  if '?' in url
    url += "&#{string.replace(/^&/, '')}"
  else
    url += "?#{string.replace(/^\?/, '')}"
  if anchor?
    "#{url}##{anchor}"
  else
    url
