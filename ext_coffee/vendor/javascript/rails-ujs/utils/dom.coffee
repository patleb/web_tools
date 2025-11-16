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
    else if selector.start_with '#'
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
    params.map (param) ->
      if Rails.is_present(param.name) and (blanks or Rails.is_present(param.value))
        "#{encodeURIComponent(param.name)}=#{encodeURIComponent(param.value)}"
      else if typeof param is 'string' and Rails.is_present(param)
        param
    .filter((item) -> item?).join('&')

  is_present: (object) ->
    return false unless object?
    return false if typeof object is 'string' and object.trim().length is 0
    return false if typeof object is 'object' and Object.keys(object).length is 0
    true

  # Helper function that returns form elements that match the specified CSS selector
  # If form is actually a "form" element this will return associated elements outside the from that have
  # the html form attribute set
  form_elements: (form, selector) ->
    if form.matches('form')
      Array.wrap(form.elements).filter (el) -> el.matches(selector)
    else
      Array.wrap(form.querySelectorAll(selector))
