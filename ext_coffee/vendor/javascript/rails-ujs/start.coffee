Rails.start = ->
  # Cut down on the number of issues from people inadvertently including
  # rails-ujs twice by detecting and raising an error when it happens.
  throw new Error('rails-ujs has already been loaded!') if window._rails_loaded

  # This event works the same as the load event, except that it fires every
  # time the page is loaded.
  # See https://github.com/rails/jquery-ujs/issues/357
  # See https://developer.mozilla.org/en-US/docs/Using_Firefox_1.5_caching
  window.addEventListener 'pageshow', ->
    Rails.$(Rails.formEnableSelector).forEach (el) ->
      Rails.enableElement(el) if Rails.getData(el, 'ujs:disabled')
    Rails.$(Rails.linkDisableSelector).forEach (el) ->
      Rails.enableElement(el) if Rails.getData(el, 'ujs:disabled')

  Rails.delegate document, Rails.linkDisableSelector, 'ajax:complete', Rails.enableElement
  Rails.delegate document, Rails.linkDisableSelector, 'ajax:stopped', Rails.enableElement
  Rails.delegate document, Rails.buttonDisableSelector, 'ajax:complete', Rails.enableElement
  Rails.delegate document, Rails.buttonDisableSelector, 'ajax:stopped', Rails.enableElement

  Rails.delegate document, Rails.linkClickSelector, 'click', Rails.preventInsignificantClick
  Rails.delegate document, Rails.linkClickSelector, 'click', Rails.handleDisabledElement
  Rails.delegate document, Rails.linkClickSelector, 'click', Rails.handleConfirm
  Rails.delegate document, Rails.linkClickSelector, 'click', Rails.disableElement
  Rails.delegate document, Rails.linkClickSelector, 'click', Rails.handleRemote
  Rails.delegate document, Rails.linkClickSelector, 'click', Rails.handleMethod

  Rails.delegate document, Rails.buttonClickSelector, 'click', Rails.preventInsignificantClick
  Rails.delegate document, Rails.buttonClickSelector, 'click', Rails.handleDisabledElement
  Rails.delegate document, Rails.buttonClickSelector, 'click', Rails.handleConfirm
  Rails.delegate document, Rails.buttonClickSelector, 'click', Rails.disableElement
  Rails.delegate document, Rails.buttonClickSelector, 'click', Rails.handleRemote

  Rails.delegate document, Rails.inputChangeSelector, 'change', Rails.handleDisabledElement
  Rails.delegate document, Rails.inputChangeSelector, 'change', Rails.handleConfirm
  Rails.delegate document, Rails.inputChangeSelector, 'change', Rails.handleRemote

  Rails.delegate document, Rails.formSubmitSelector, 'submit', Rails.handleDisabledElement
  Rails.delegate document, Rails.formSubmitSelector, 'submit', Rails.handleConfirm
  Rails.delegate document, Rails.formSubmitSelector, 'submit', Rails.handleRemote
  # Normal mode submit
  # Slight timeout so that the submit button gets properly serialized
  Rails.delegate document, Rails.formSubmitSelector, 'submit', (e) -> setTimeout((-> Rails.disableElement(e)), 13)
  Rails.delegate document, Rails.formSubmitSelector, 'ajax:send', Rails.disableElement
  Rails.delegate document, Rails.formSubmitSelector, 'ajax:complete', Rails.enableElement

  Rails.delegate document, Rails.formInputClickSelector, 'click', Rails.preventInsignificantClick
  Rails.delegate document, Rails.formInputClickSelector, 'click', Rails.handleDisabledElement
  Rails.delegate document, Rails.formInputClickSelector, 'click', Rails.handleConfirm
  Rails.delegate document, Rails.formInputClickSelector, 'click', Rails.formSubmitButtonClick

  document.addEventListener('DOMContentLoaded', Rails.refreshCSRFTokens)
  document.addEventListener('DOMContentLoaded', Rails.loadCSPNonce)
  window._rails_loaded = true

if window.Rails is Rails and Rails.fire(document, 'rails:attachBindings')
  Rails.start()
