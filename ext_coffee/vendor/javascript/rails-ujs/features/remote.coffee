Rails.merge
  is_remote: (element) ->
    value = element.getAttribute('data-remote')
    value? and value isnt 'false'

  handle_remote: (e) ->
    element = this

    return true unless Rails.is_remote(element)
    if Rails.fire(element, 'ajax:before') is false
      Rails.fire(element, 'ajax:stopped')
      return false

    with_credentials = element.getAttribute('data-with-credentials')
    data_type = element.getAttribute('data-type')
    if element.matches(Rails.submitable_forms)
      # memoized value from clicked submit button
      button = Rails.get(element, 'ujs:submit-button')
      method = Rails.get(element, 'ujs:submit-button-formmethod') or element.getAttribute('method')
      method = method?.toUpperCase() or 'GET'
      url = Rails.get(element, 'ujs:submit-button-formaction') ? element.getAttribute('action') ? ''
      url = url.replace(/\?[^#]*/, '') if method is 'GET'
      if element.enctype is 'multipart/form-data'
        data = new FormData(element)
        data.append(button.name, button.value) if button?
      else
        data = Rails.serialize_element(element, button)
      action = turbolinks_action(element, data_type, true)
      Rails.set(element, 'ujs:submit-button', null)
      Rails.set(element, 'ujs:submit-button-formmethod', null)
      Rails.set(element, 'ujs:submit-button-formaction', null)
    else if element.matches(Rails.clickable_buttons) or element.matches(Rails.changeable_inputs)
      method = element.getAttribute('data-method')?.toUpperCase() or 'GET'
      url = element.getAttribute('data-url')
      data = Rails.serialize_element(element, element.getAttribute('data-params'))
      action = turbolinks_action(element, data_type)
    else
      method = element.getAttribute('data-method')?.toUpperCase() or 'GET'
      url = Rails.href(element)
      data = element.getAttribute('data-params')
      action = turbolinks_action(element, data_type)
    data_type = 'html' if action
    data_type ||= 'script'

    new XHR({
      type: method
      url
      data
      data_type
      before_send: (xhr, options) ->
        if Rails.fire(element, 'ajax:before_send', [xhr, options, action])
          Rails.fire(element, 'ajax:send', [xhr, action])
          turbolinks_started() if action
          true
        else
          Rails.fire(element, 'ajax:stopped')
          false
      success: (response, status, xhr) ->
        Rails.fire(element, 'ajax:success', [response, status, xhr, action])
        turbolinks_visit(response, xhr, url, action) if action
      error: (response, status, xhr) ->
        Rails.fire(element, 'ajax:error', [response, status, xhr, action])
        turbolinks_visit(response, xhr, url, action, true) if action
      complete: (xhr, status) ->
        Rails.fire(element, 'ajax:complete', [xhr, status, action])
      crossDomain: Rails.is_cross_domain(url)
      withCredentials: with_credentials? and with_credentials isnt 'false'
    })
    Rails.stop_everything(e)

  form_submit_button_click: (e) ->
    button = this
    form = button.form
    return unless form
    # Register the pressed submit button
    Rails.set(form, 'ujs:submit-button', name: button.name, value: button.value) if button.name
    # Save attributes from button
    Rails.set(form, 'ujs:formnovalidate-button', button.formNoValidate)
    Rails.set(form, 'ujs:submit-button-formaction', button.getAttribute('formaction'))
    Rails.set(form, 'ujs:submit-button-formmethod', button.getAttribute('formmethod'))

  prevent_meta_click: (e) ->
    link = this
    method = link.getAttribute('data-method')
    data = link.getAttribute('data-params')
    if Rails.is_meta_click(e, method, data) and Rails.fire(e.target, 'ujs:meta-click')
      e.stopImmediatePropagation()

turbolinks_action = (element, data_type, submitable_form = false) ->
  if submitable_form
    switch (action = element.getAttribute('data-visit') or 'restore')
      when 'false' then return false
      when 'true'  then action = 'advance'
  else
    switch (action = element.getAttribute('data-visit'))
      when 'false', null then return false
      when 'true'        then action = 'advance'
  window.Turbolinks and Turbolinks.is_visitable(element) and (not data_type or data_type is 'html') and action

turbolinks_started = ->
  Turbolinks.request_started()

turbolinks_visit = (response, xhr, url, action, error = false) ->
  Turbolinks.request_finished()
  Turbolinks.clear_cache(true)
  Turbolinks.visit(xhr.getResponseHeader('X-Xhr-Redirect') or url, action: action, html: response, error: error)
