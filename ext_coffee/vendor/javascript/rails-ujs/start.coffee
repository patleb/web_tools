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

  Rails.document_on 'ajax:complete', Rails.linkDisableSelector, Rails.enableElement
  Rails.document_on 'ajax:stopped', Rails.linkDisableSelector, Rails.enableElement
  Rails.document_on 'ajax:complete', Rails.buttonDisableSelector, Rails.enableElement
  Rails.document_on 'ajax:stopped', Rails.buttonDisableSelector, Rails.enableElement

  Rails.document_on 'click', Rails.linkClickSelector, Rails.preventInsignificantClick
  Rails.document_on 'click', Rails.linkClickSelector, Rails.handleDisabledElement
  Rails.document_on 'click', Rails.linkClickSelector, Rails.handleConfirm
  Rails.document_on 'click', Rails.linkClickSelector, Rails.disableElement
  Rails.document_on 'click', Rails.linkClickSelector, Rails.handleRemote
  Rails.document_on 'click', Rails.linkClickSelector, Rails.handleMethod

  Rails.document_on 'click', Rails.buttonClickSelector, Rails.preventInsignificantClick
  Rails.document_on 'click', Rails.buttonClickSelector, Rails.handleDisabledElement
  Rails.document_on 'click', Rails.buttonClickSelector, Rails.handleConfirm
  Rails.document_on 'click', Rails.buttonClickSelector, Rails.disableElement
  Rails.document_on 'click', Rails.buttonClickSelector, Rails.handleRemote

  Rails.document_on 'change', Rails.inputChangeSelector, Rails.handleDisabledElement
  Rails.document_on 'change', Rails.inputChangeSelector, Rails.handleConfirm
  Rails.document_on 'change', Rails.inputChangeSelector, Rails.handleRemote

  Rails.document_on 'submit', Rails.formSubmitSelector, Rails.handleDisabledElement
  Rails.document_on 'submit', Rails.formSubmitSelector, Rails.handleConfirm
  Rails.document_on 'submit', Rails.formSubmitSelector, Rails.handleRemote
  # Normal mode submit
  # Slight timeout so that the submit button gets properly serialized
  Rails.document_on 'submit', Rails.formSubmitSelector, (e) ->
    setTimeout(->
      Rails.disableElement(e)
    , 13)
  Rails.document_on 'ajax:send', Rails.formSubmitSelector, Rails.disableElement
  Rails.document_on 'ajax:complete', Rails.formSubmitSelector, Rails.enableElement

  Rails.document_on 'click', Rails.formInputClickSelector, Rails.preventInsignificantClick
  Rails.document_on 'click', Rails.formInputClickSelector, Rails.handleDisabledElement
  Rails.document_on 'click', Rails.formInputClickSelector, Rails.handleConfirm
  Rails.document_on 'click', Rails.formInputClickSelector, Rails.formSubmitButtonClick

  document.addEventListener('DOMContentLoaded', Rails.refreshCSRFTokens)
  document.addEventListener('DOMContentLoaded', Rails.loadCSPNonce)
  window._rails_loaded = true

if window.Rails is Rails and Rails.fire(document, 'rails:attachBindings')
  Rails.start()
