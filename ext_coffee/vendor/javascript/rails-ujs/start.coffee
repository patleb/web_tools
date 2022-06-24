Rails.start = ->
  # Cut down on the number of issues from people inadvertently including
  # rails-ujs twice by detecting and raising an error when it happens.
  throw new Error('rails-ujs has already been loaded!') if window._rails_loaded

  # This event works the same as the load event, except that it fires every
  # time the page is loaded.
  # See https://github.com/rails/jquery-ujs/issues/357
  # See https://developer.mozilla.org/en-US/docs/Using_Firefox_1.5_caching
  window.addEventListener 'pageshow', ->
    Rails.$(Rails.enableable_inputs).forEach (el) ->
      Rails.enable_element(el) if Rails.get(el, 'ujs:disabled')
    Rails.$(Rails.disableable_links).forEach (el) ->
      Rails.enable_element(el) if Rails.get(el, 'ujs:disabled')

  Rails.document_on 'ajax:complete', Rails.disableable_links, Rails.enable_element
  Rails.document_on 'ajax:stopped', Rails.disableable_links, Rails.enable_element
  Rails.document_on 'ajax:complete', Rails.disableable_buttons, Rails.enable_element
  Rails.document_on 'ajax:stopped', Rails.disableable_buttons, Rails.enable_element

  Rails.document_on 'click', Rails.clickable_links, Rails.prevent_meta_click
  Rails.document_on 'click', Rails.clickable_links, Rails.handle_disabled_element
  Rails.document_on 'click', Rails.clickable_links, Rails.handle_confirm
  Rails.document_on 'click', Rails.clickable_links, Rails.disable_element
  Rails.document_on 'click', Rails.clickable_links, Rails.handle_remote

  Rails.document_on 'click', Rails.clickable_buttons, Rails.prevent_meta_click
  Rails.document_on 'click', Rails.clickable_buttons, Rails.handle_disabled_element
  Rails.document_on 'click', Rails.clickable_buttons, Rails.handle_confirm
  Rails.document_on 'click', Rails.clickable_buttons, Rails.disable_element
  Rails.document_on 'click', Rails.clickable_buttons, Rails.handle_remote

  Rails.document_on 'change', Rails.changeable_inputs, Rails.handle_disabled_element
  Rails.document_on 'change', Rails.changeable_inputs, Rails.handle_confirm
  Rails.document_on 'change', Rails.changeable_inputs, Rails.handle_remote

  Rails.document_on 'submit', Rails.submitable_forms, Rails.handle_disabled_element
  Rails.document_on 'submit', Rails.submitable_forms, Rails.handle_confirm
  Rails.document_on 'submit', Rails.submitable_forms, Rails.handle_remote
  # Normal mode submit
  # Slight timeout so that the submit button gets properly serialized
  Rails.document_on 'submit', Rails.submitable_forms, (e) ->
    setTimeout(->
      Rails.disable_element(e)
    , 13)
  Rails.document_on 'ajax:send', Rails.submitable_forms, Rails.disable_element
  Rails.document_on 'ajax:complete', Rails.submitable_forms, Rails.enable_element

  Rails.document_on 'click', Rails.clickable_inputs, Rails.prevent_meta_click
  Rails.document_on 'click', Rails.clickable_inputs, Rails.handle_disabled_element
  Rails.document_on 'click', Rails.clickable_inputs, Rails.handle_confirm
  Rails.document_on 'click', Rails.clickable_inputs, Rails.form_submit_button_click

  Rails.document_on 'DOMContentLoaded', Rails.refresh_csrf_tokens
  Rails.document_on 'DOMContentLoaded', Rails.load_csp_nonce
  window._rails_loaded = true

if window.Rails is Rails and Rails.fire(document, 'rails:attachBindings')
  Rails.start()
