# Checks "data-remote" if true to handle the request through a XHR request.
Rails.is_remote = (element) ->
  value = element.getAttribute('data-remote')
  value? and value isnt 'false'

# Submits "remote" forms and links with ajax
Rails.handle_remote = (e) ->
  element = this

  return true unless Rails.is_remote(element)
  unless Rails.fire(element, 'ajax:before')
    Rails.fire(element, 'ajax:stopped')
    return false

  with_credentials = element.getAttribute('data-with-credentials')
  data_type = element.getAttribute('data-type') or 'script'

  if element.matches(Rails.submitable_forms)
    # memoized value from clicked submit button
    button = Rails.get(element, 'ujs:submit-button')
    method = Rails.get(element, 'ujs:submit-button-formmethod') or element.getAttribute('method') or 'GET'
    url = Rails.get(element, 'ujs:submit-button-formaction') or element.getAttribute('action') or location.href
    url = url.replace(/\?[^#]*/, '') if method.toUpperCase() is 'GET'

    if element.enctype is 'multipart/form-data'
      data = new FormData(element)
      data.append(button.name, button.value) if button?
    else
      data = Rails.serialize_element(element, button)

    Rails.set(element, 'ujs:submit-button', null)
    Rails.set(element, 'ujs:submit-button-formmethod', null)
    Rails.set(element, 'ujs:submit-button-formaction', null)
  else if element.matches(Rails.clickable_buttons) or element.matches(Rails.changeable_inputs)
    method = element.getAttribute('data-method')
    url = element.getAttribute('data-url')
    data = Rails.serialize_element(element, element.getAttribute('data-params'))
  else
    method = element.getAttribute('data-method')
    url = Rails.href(element)
    data = element.getAttribute('data-params')

  Rails.ajax(
    type: method or 'GET'
    url: url
    data: data
    data_type: data_type
    # stopping the "ajax:beforeSend" event will cancel the ajax request
    beforeSend: (xhr, options) ->
      if Rails.fire(element, 'ajax:beforeSend', [xhr, options])
        Rails.fire(element, 'ajax:send', [xhr])
      else
        Rails.fire(element, 'ajax:stopped')
        return false
    success: (args...) -> Rails.fire(element, 'ajax:success', args)
    error: (args...) -> Rails.fire(element, 'ajax:error', args)
    complete: (args...) ->
      Rails.fire(element, 'ajax:complete', args)
      window.clear_event_submitter()
    crossDomain: Rails.is_cross_domain(url)
    withCredentials: with_credentials? and with_credentials isnt 'false'
  )
  Rails.stop_everything(e)

Rails.form_submit_button_click = (e) ->
  button = this
  form = button.form
  return unless form
  # Register the pressed submit button
  Rails.set(form, 'ujs:submit-button', name: button.name, value: button.value) if button.name
  # Save attributes from button
  Rails.set(form, 'ujs:formnovalidate-button', button.formNoValidate)
  Rails.set(form, 'ujs:submit-button-formaction', button.getAttribute('formaction'))
  Rails.set(form, 'ujs:submit-button-formmethod', button.getAttribute('formmethod'))

Rails.prevent_meta_click = (e) ->
  link = this
  method = link.getAttribute('data-method')
  data = link.getAttribute('data-params')
  if Rails.is_meta_click(e, method, data) and Rails.fire(e.target, 'ujs:meta-click')
    e.stopImmediatePropagation()
