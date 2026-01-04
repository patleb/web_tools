EXPANDO = '_ujs_data'

csp_nonce = null

Rails.merge
  # get and set data on a given element using "expando properties"
  # See: https://developer.mozilla.org/en-US/docs/Glossary/Expando
  get: (element, key) ->
    element[EXPANDO]?[key]

  set: (element, key, value) ->
    if typeof key is 'object'
      for k, v of key
        Rails.set(element, k, v)
    else
      element[EXPANDO] ?= {}
      element[EXPANDO][key] = value

  # a wrapper for document.querySelectorAll
  # returns an Array
  $: (selector) ->
    Array.wrap(document.querySelectorAll(selector))

  once: (selector, callback) ->
    elements = Rails.$("#{selector}:not([data-once])")
    elements.each (element) ->
      callback(element)
      element.setAttribute('data-once', true)
    elements

  find: (selector) ->
    if (id = selector.id)
      document.getElementById(id)
    else if selector.starts_with '#'
      document.getElementById(selector.lchop())
    else
      document.querySelector(selector)

  load_csp_nonce: ->
    csp_nonce = document.querySelector('meta[name=csp-nonce]')?.content

  # Returns the Content-Security-Policy nonce for inline scripts.
  csp_nonce: ->
    csp_nonce ? Rails.load_csp_nonce()

  # Up-to-date Cross-Site Request Forgery token
  csrf_token: ->
    meta = document.querySelector('meta[name=csrf-token]')
    meta and meta.content

  # URL param that must contain the CSRF token
  csrf_param: ->
    meta = document.querySelector('meta[name=csrf-param]')
    meta and meta.content

  # Make sure that every Ajax request sends the CSRF token
  csrf_protection: (xhr) ->
    token = Rails.csrf_token()
    xhr.setRequestHeader('X-CSRF-Token', token) if token?

  # Make sure that all forms have actual up-to-date tokens (cached forms contain old ones)
  refresh_csrf_tokens: (root) ->
    token = Rails.csrf_token()
    param = Rails.csrf_param()
    if token? and param?
      root = Rails unless root.$?
      root.$("form input[name='#{param}']").forEach (input) -> input.value = token

  serialize_element: (element, additional_param, blanks = true) ->
    inputs = [element]
    inputs = Array.wrap(element.elements) if element.matches('form')
    params = []
    inputs.forEach (input) ->
      return if not input.name or input.disabled or input.hasAttribute('disabled')
      return if input.matches('fieldset[disabled] *')
      return if input.name is additional_param?.name
      if input.matches('select')
        Array.wrap(input.options).forEach (option) ->
          params.push(name: input.name, value: option.value) if option.selected
      else if input.checked or input.type not in ['radio', 'checkbox', 'submit']
        params.push(name: input.name, value: input.value)
    params.push(additional_param) if additional_param
    params.select_map (param) ->
      if param.name?.present() and (blanks or param.value?.present())
        "#{encodeURIComponent(param.name)}=#{encodeURIComponent(param.value)}"
      else if typeof param is 'string' and param.present()
        param
    .join('&')

  # Helper function that returns form elements that match the specified CSS selector
  # If form is actually a "form" element this will return associated elements outside the from that have
  # the html form attribute set
  form_elements: (form, selector) ->
    if form.matches('form')
      Array.wrap(form.elements).select (el) -> el.matches(selector)
    else
      Array.wrap(form.querySelectorAll(selector))

  # Triggers a custom event on an element and returns false if the event result is false
  # obj::
  #   a native DOM element
  # name::
  #   string that corresponds to the event you want to trigger
  #   e.g. 'click', 'submit'
  # data::
  #   data you want to pass when you dispatch an event
  fire: (obj, name, data) ->
    event = new CustomEvent(name, bubbles: true, cancelable: true, detail: data)
    obj.dispatchEvent(event)
    not event.defaultPrevented

  # Helper function, needed to provide consistent behavior in IE
  stop_everything: (e) ->
    e.target.fire 'ujs:everythingStopped'
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
  delegate: (element, selector, event_type, handler) ->
    element.addEventListener event_type, (e) ->
      target = e.target
      target = target.parentNode until not (target instanceof Element) or target.matches(selector)
      if target instanceof Element and handler.call(target, e) is false
        e.preventDefault()
        e.stopPropagation()

  document_on: (event_type, selector, handler) ->
    if typeof selector is 'string' or typeof selector.selector is 'string'
      Rails.delegate(document, selector, event_type, handler)
    else
      handler ?= selector
      document.addEventListener(event_type, handler)

  is_meta_click: (event, method, data) ->
    (event.button? and event.button isnt 0) or (
      event.target?.isContentEditable or
        event.which > 1 or
        event.altKey or
        event.ctrlKey or
        event.metaKey or
        event.shiftKey
    ) and (method or 'GET').toUpperCase() is 'GET' and not data

  # Default way to get an element's href. May be overridden at Rails.href.
  href: (element) ->
    element.href

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
        (not new_url.protocol or new_url.protocol is ':') and
          (not new_url.host or "#{old_url.protocol}//#{old_url.host}" is "#{new_url.protocol}//#{new_url.host}")
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
