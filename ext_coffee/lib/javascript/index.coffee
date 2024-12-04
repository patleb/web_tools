spinner_timeout = null

window.Js =
  SPINNER_DEBOUNCE: 500

  load_spinner: ->
    unless spinner_timeout?
      spinner_timeout = setTimeout(->
        Rails.find('.spinner_container').remove_class('hidden')
      , Js.SPINNER_DEBOUNCE)

  clear_spinner: ->
    Rails.find('.spinner_container').add_class('hidden')
    clearTimeout(spinner_timeout)
    spinner_timeout = null

  # https://stackoverflow.com/questions/5623838/rgb-to-hex-and-hex-to-rgb
  add_opacity: (hex, opacity) ->
    result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
    if result
      "rgba(#{result[1].to_i(16)}, #{result[2].to_i(16)}, #{result[3].to_i(16)}, #{opacity})"
    else
      hex

  selected_text: ->
    text =
      if window.getSelection
        window.getSelection()
      else if document.getSelection
        document.getSelection()
      else if document.selection
        document.selection.createRange().text
      else
    text ?= ''
    text.toString()

  is_submit_key: (event) ->
    event.which is 13 and not (event.target.matches('textarea') or event.target.isContentEditable)

  is_form_valid: (inputs) ->
    Array.wrap(inputs).all (input) -> input.valid()

window.Sm = {}
