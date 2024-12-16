Rails.merge
  handle_disabled_element: (e) ->
    element = this
    Rails.stop_everything(e) if element.disabled or element.hasAttribute('disabled')

  enable_elements: (es...) ->
    es.each (e) -> Rails.enable_element(e)

  disable_elements: (es...) ->
    es.each (e) -> Rails.disable_element(e)

  # Unified function to enable an element (link, button and form)
  enable_element: (e) ->
    element = if e instanceof Event then e.target else e
    if element.matches(Rails.disableable_links)
      enable_link(element)
    else if element.matches(Rails.disableable_buttons) or element.matches(Rails.enableable_inputs)
      enable_input(element)
    else if element.matches(Rails.submitable_forms)
      enable_inputs(element)

  # Unified function to disable an element (link, button and form)
  disable_element: (e) ->
    element = if e instanceof Event then e.target else e
    if element.matches(Rails.disableable_links)
      disable_link(element)
    else if element.matches(Rails.disableable_buttons) or element.matches(Rails.disableable_inputs)
      disable_input(element)
    else if element.matches(Rails.submitable_forms)
      disable_inputs(element)

#  Replace element's html with the 'data-disable_with' after storing original html
#  and prevent clicking on it
disable_link = (element) ->
  return if Rails.get(element, 'ujs:disabled') or element.hasAttribute('disabled')
  new_text = element.getAttribute('data-disable_with')
  if new_text?
    Rails.set(element, 'ujs:enable-with', element.innerHTML) # store enabled state
    element.innerHTML = new_text
  element.addEventListener('click', Rails.stop_everything) # prevent further clicking
  Rails.set(element, 'ujs:disabled', true)

# Restore element to its original state which was disabled by 'disable_link' above
enable_link = (element) ->
  return unless Rails.get(element, 'ujs:disabled')
  old_text = Rails.get(element, 'ujs:enable-with')
  if old_text?
    element.innerHTML = old_text # set to old enabled state
    Rails.set(element, 'ujs:enable-with', null) # clean up cache
  element.removeEventListener('click', Rails.stop_everything) # enable element
  Rails.set(element, 'ujs:disabled', null)

# Disables form elements:
#  - Caches element value in 'ujs:enable-with' data store
#  - Replaces element text with value of 'data-disable_with' attribute
#  - Sets disabled property to true
disable_inputs = (form) ->
  Rails.form_elements(form, Rails.disableable_inputs).forEach(disable_input)

disable_input = (element) ->
  return if Rails.get(element, 'ujs:disabled') or element.hasAttribute('disabled')
  new_text = element.getAttribute('data-disable_with')
  if new_text?
    if element.matches('button')
      Rails.set(element, 'ujs:enable-with', element.innerHTML)
      element.innerHTML = new_text
    else
      Rails.set(element, 'ujs:enable-with', element.value)
      element.value = new_text
  element.disabled = true
  Rails.set(element, 'ujs:disabled', true)

# Re-enables disabled form elements:
#  - Replaces element text with cached value from 'ujs:enable-with' data store (created in `disable_inputs`)
#  - Sets disabled property to false
enable_inputs = (form) ->
  Rails.form_elements(form, Rails.enableable_inputs).forEach(enable_input)

enable_input = (element) ->
  return unless Rails.get(element, 'ujs:disabled')
  old_text = Rails.get(element, 'ujs:enable-with')
  if old_text?
    if element.matches('button')
      element.innerHTML = old_text
    else
      element.value = old_text
    Rails.set(element, 'ujs:enable-with', null) # clean up cache
  element.disabled = false
  Rails.set(element, 'ujs:disabled', null)
