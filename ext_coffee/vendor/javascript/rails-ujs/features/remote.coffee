# Checks "data-remote" if true to handle the request through a XHR request.
isRemote = (element) ->
  value = element.getAttribute('data-remote')
  value? and value isnt 'false'

# Submits "remote" forms and links with ajax
Rails.handleRemote = (e) ->
  element = this

  return true unless isRemote(element)
  unless Rails.fire(element, 'ajax:before')
    Rails.fire(element, 'ajax:stopped')
    return false

  withCredentials = element.getAttribute('data-with-credentials')
  dataType = element.getAttribute('data-type') or 'script'

  if element.matches(Rails.formSubmitSelector)
    # memoized value from clicked submit button
    button = Rails.getData(element, 'ujs:submit-button')
    method = Rails.getData(element, 'ujs:submit-button-formmethod') or element.method
    url = Rails.getData(element, 'ujs:submit-button-formaction') or element.getAttribute('action') or location.href

    # strip query string if it's a GET request
    url = url.replace(/\?.*$/, '') if method.toUpperCase() is 'GET'

    if element.enctype is 'multipart/form-data'
      data = new FormData(element)
      data.append(button.name, button.value) if button?
    else
      data = Rails.serializeElement(element, button)

    Rails.setData(element, 'ujs:submit-button', null)
    Rails.setData(element, 'ujs:submit-button-formmethod', null)
    Rails.setData(element, 'ujs:submit-button-formaction', null)
  else if element.matches(Rails.buttonClickSelector) or element.matches(Rails.inputChangeSelector)
    method = element.getAttribute('data-method')
    url = element.getAttribute('data-url')
    data = Rails.serializeElement(element, element.getAttribute('data-params'))
  else
    method = element.getAttribute('data-method')
    url = Rails.href(element)
    data = element.getAttribute('data-params')

  Rails.ajax(
    type: method or 'GET'
    url: url
    data: data
    dataType: dataType
    # stopping the "ajax:beforeSend" event will cancel the ajax request
    beforeSend: (xhr, options) ->
      if Rails.fire(element, 'ajax:beforeSend', [xhr, options])
        Rails.fire(element, 'ajax:send', [xhr])
      else
        Rails.fire(element, 'ajax:stopped')
        return false
    success: (args...) -> Rails.fire(element, 'ajax:success', args)
    error: (args...) -> Rails.fire(element, 'ajax:error', args)
    complete: (args...) -> Rails.fire(element, 'ajax:complete', args)
    crossDomain: Rails.isCrossDomain(url)
    withCredentials: withCredentials? and withCredentials isnt 'false'
  )
  Rails.stopEverything(e)

Rails.formSubmitButtonClick = (e) ->
  button = this
  form = button.form
  return unless form
  # Register the pressed submit button
  Rails.setData(form, 'ujs:submit-button', name: button.name, value: button.value) if button.name
  # Save attributes from button
  Rails.setData(form, 'ujs:formnovalidate-button', button.formNoValidate)
  Rails.setData(form, 'ujs:submit-button-formaction', button.getAttribute('formaction'))
  Rails.setData(form, 'ujs:submit-button-formmethod', button.getAttribute('formmethod'))

Rails.preventInsignificantClick = (e) ->
  link = this
  method = (link.getAttribute('data-method') or 'GET').toUpperCase()
  data = link.getAttribute('data-params')
  metaClick = e.metaKey or e.ctrlKey
  insignificantMetaClick = metaClick and method is 'GET' and not data
  nonPrimaryMouseClick = e.button? and e.button isnt 0
  e.stopImmediatePropagation() if nonPrimaryMouseClick or insignificantMetaClick

