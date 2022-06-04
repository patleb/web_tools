window.Rails =
  # Link elements bound by rails-ujs
  clickable_links: 'a[data-confirm], a[data-remote]:not([disabled]), a[data-disable-with], a[data-disable]'

  # Button elements bound by rails-ujs
  clickable_buttons:
    selector: 'button[data-remote]:not([form]), button[data-confirm]:not([form])'
    exclude: 'form button'

  # Select elements bound by rails-ujs
  changeable_inputs: 'select[data-remote], input[data-remote], textarea[data-remote]'

  # Form elements bound by rails-ujs
  submitable_forms: 'form:not([data-turbo=true])',

  # Form input elements bound by rails-ujs
  clickable_inputs: 'form:not([data-turbo=true]) input[type=submit], form:not([data-turbo=true]) input[type=image], form:not([data-turbo=true]) button[type=submit], form:not([data-turbo=true]) button:not([type]), input[type=submit][form], input[type=image][form], button[type=submit][form], button[form]:not([type])',

  # Form input elements disabled during form submission
  disableable_inputs: 'input[data-disable-with]:enabled, button[data-disable-with]:enabled, textarea[data-disable-with]:enabled, input[data-disable]:enabled, button[data-disable]:enabled, textarea[data-disable]:enabled'

  # Form input elements re-enabled after form submission
  enableable_inputs: 'input[data-disable-with]:disabled, button[data-disable-with]:disabled, textarea[data-disable-with]:disabled, input[data-disable]:disabled, button[data-disable]:disabled, textarea[data-disable]:disabled'

  # Link onClick disable selector with possible re-enable after remote submission
  disableable_links: 'a[data-disable-with], a[data-disable]'

  # Button onClick disable selector with possible re-enable after remote submission
  disableable_buttons: 'button[data-remote][data-disable-with], button[data-remote][data-disable]'
