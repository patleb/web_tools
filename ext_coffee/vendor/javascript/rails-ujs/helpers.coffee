# DOM helpers

m = Element.prototype.matches or
    Element.prototype.matchesSelector or
    Element.prototype.mozMatchesSelector or
    Element.prototype.msMatchesSelector or
    Element.prototype.oMatchesSelector or
    Element.prototype.webkitMatchesSelector

# Checks if the given native dom element matches the selector
# element::
#   native DOM element
# selector::
#   CSS selector string or
#   a JavaScript object with `selector` and `exclude` properties
#   Examples: "form", { selector: "form", exclude: "form[data-remote='true']"}
Rails.matches = (element, selector) ->
  if selector.exclude?
    m.call(element, selector.selector) and not m.call(element, selector.exclude)
  else
    m.call(element, selector)

# get and set data on a given element using "expando properties"
# See: https://developer.mozilla.org/en-US/docs/Glossary/Expando
expando = '_ujsData'

Rails.getData = (element, key) ->
  element[expando]?[key]

Rails.setData = (element, key, value) ->
  element[expando] ?= {}
  element[expando][key] = value

# a wrapper for document.querySelectorAll
# returns an Array
Rails.$ = (selector) ->
  Array.prototype.slice.call(document.querySelectorAll(selector))

Rails.focus = (element) ->
  if element instanceof HTMLElement
    if element.hasAttribute('tabindex')
      element.focus()
    else
      element.setAttribute('tabindex', '-1')
      element.focus()
      element.removeAttribute('tabindex')

# CSP helpers

csp_nonce = null

Rails.loadCSPNonce = ->
  csp_nonce = document.querySelector("meta[name=csp-nonce]")?.content

# Returns the Content-Security-Policy nonce for inline scripts.
Rails.cspNonce = ->
  csp_nonce ? Rails.loadCSPNonce()

# CSRF helpers

# Up-to-date Cross-Site Request Forgery token
Rails.csrfToken = ->
  meta = document.querySelector('meta[name=csrf-token]')
  meta and meta.content

# URL param that must contain the CSRF token
Rails.csrfParam = ->
  meta = document.querySelector('meta[name=csrf-param]')
  meta and meta.content

# Make sure that every Ajax request sends the CSRF token
Rails.CSRFProtection = (xhr) ->
  token = Rails.csrfToken()
  xhr.setRequestHeader('X-CSRF-Token', token) if token?

# Make sure that all forms have actual up-to-date tokens (cached forms contain old ones)
Rails.refreshCSRFTokens = ->
  token = Rails.csrfToken()
  param = Rails.csrfParam()
  if token? and param?
    Rails.$('form input[name="' + param + '"]').forEach (input) -> input.value = token

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
  event = new CustomEvent(
    name,
    bubbles: true,
    cancelable: true,
    detail: data,
  )
  obj.dispatchEvent(event)
  !event.defaultPrevented

# Helper function, needed to provide consistent behavior in IE
Rails.stopEverything = (e) ->
  Rails.fire(e.target, 'ujs:everythingStopped')
  e.preventDefault()
  e.stopPropagation()
  e.stopImmediatePropagation()

# Delegates events
# to a specified parent `element`, which fires event `handler`
# for the specified `selector` when an event of `eventType` is triggered
# element::
#   parent element that will listen for events e.g. document
# selector::
#   CSS selector; or an object that has `selector` and `exclude` properties (see: Rails.matches)
# eventType::
#   string representing the event e.g. 'submit', 'click'
# handler::
#   the event handler to be called
Rails.delegate = (element, selector, eventType, handler) ->
  element.addEventListener eventType, (e) ->
    target = e.target
    target = target.parentNode until not (target instanceof Element) or Rails.matches(target, selector)
    if target instanceof Element and handler.call(target, e) == false
      e.preventDefault()
      e.stopPropagation()

Rails.document_on = (eventType, selector, handler) ->
  Rails.delegate(document, selector, eventType, handler)

# Form helpers

toArray = (e) -> Array.prototype.slice.call(e)

Rails.serializeElement = (element, additionalParam) ->
  inputs = [element]
  inputs = toArray(element.elements) if Rails.matches(element, 'form')
  params = []

  inputs.forEach (input) ->
    return if !input.name || input.disabled
    return if Rails.matches(input, 'fieldset[disabled] *')
    if Rails.matches(input, 'select')
      toArray(input.options).forEach (option) ->
        params.push(name: input.name, value: option.value) if option.selected
    else if input.checked or ['radio', 'checkbox', 'submit'].indexOf(input.type) == -1
      params.push(name: input.name, value: input.value)

  params.push(additionalParam) if additionalParam

  params.map (param) ->
    if param.name?
      "#{encodeURIComponent(param.name)}=#{encodeURIComponent(param.value)}"
    else
      param
  .join('&')

# Helper function that returns form elements that match the specified CSS selector
# If form is actually a "form" element this will return associated elements outside the from that have
# the html form attribute set
Rails.formElements = (form, selector) ->
  if Rails.matches(form, 'form')
    toArray(form.elements).filter (el) -> Rails.matches(el, selector)
  else
    toArray(form.querySelectorAll(selector))

# AJAX helpers

AcceptHeaders =
  '*': '*/*'
  text: 'text/plain'
  html: 'text/html'
  xml: 'application/xml, text/xml'
  json: 'application/json, text/javascript'
  script: 'text/javascript, application/javascript, application/ecmascript, application/x-ecmascript'

Rails.ajax = (options) ->
  options = prepareOptions(options)
  xhr = createXHR options, ->
    response = processResponse(xhr.response ? xhr.responseText, xhr.getResponseHeader('Content-Type'))
    if xhr.status // 100 == 2
      options.success?(response, xhr.statusText, xhr)
    else
      options.error?(response, xhr.statusText, xhr)
    options.complete?(xhr, xhr.statusText)

  if options.beforeSend? && !options.beforeSend(xhr, options)
    return false

  if xhr.readyState is XMLHttpRequest.OPENED
    xhr.send(options.data)

prepareOptions = (options) ->
  options.url = options.url or location.href
  options.type = options.type.toUpperCase()
  # append data to url if it's a GET request
  if options.type is 'GET' and options.data
    if options.url.indexOf('?') < 0
      options.url += '?' + options.data
    else
      options.url += '&' + options.data
  # Use "*" as default dataType
  options.dataType = '*' unless AcceptHeaders[options.dataType]?
  options.accept = AcceptHeaders[options.dataType]
  options.accept += ', */*; q=0.01' if options.dataType isnt '*'
  options

createXHR = (options, done) ->
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
    Rails.CSRFProtection(xhr)
  xhr.withCredentials = !!options.withCredentials
  xhr.onreadystatechange = ->
    done(xhr) if xhr.readyState is XMLHttpRequest.DONE
  xhr

processResponse = (response, type) ->
  if typeof response is 'string' and typeof type is 'string'
    if type.match(/\bjson\b/)
      try response = JSON.parse(response)
    else if type.match(/\b(?:java|ecma)script\b/)
      nonce = Rails.cspNonce()
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
Rails.isCrossDomain = (url) ->
  originAnchor = document.createElement('a')
  originAnchor.href = location.href
  urlAnchor = document.createElement('a')
  try
    urlAnchor.href = url
    # If URL protocol is false or is a string containing a single colon
    # *and* host are false, assume it is not a cross-domain request
    # (should only be the case for IE7 and IE compatibility mode).
    # Otherwise, evaluate protocol and host of the URL against the origin
    # protocol and host.
    !(((!urlAnchor.protocol || urlAnchor.protocol == ':') && !urlAnchor.host) ||
      (originAnchor.protocol + '//' + originAnchor.host == urlAnchor.protocol + '//' + urlAnchor.host))
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
  num = Turbolinks.id++
  num = String(pad + num).slice(-pad.length)
  "#{time}#{num}"
