spinners = {}

window.Js =
  SPINNER_DEBOUNCE: 500

  load_spinner: (id = 0) ->
    spinners[id] = setTimeout(->
      Rails.find('.spinner_container').remove_class('hidden')
    , Js.SPINNER_DEBOUNCE)

  clear_spinner: (id = 0) ->
    clearTimeout spinners.delete(id)
    if spinners.empty()
      Rails.find('.spinner_container').add_class('hidden')

  # https://stackoverflow.com/questions/5623838/rgb-to-hex-and-hex-to-rgb
  add_opacity: (hex, opacity) ->
    result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
    if result
      "rgba(#{result[1].to_i(16)}, #{result[2].to_i(16)}, #{result[3].to_i(16)}, #{opacity})"
    else
      hex

  mix_colors: (background, foreground, opacity) ->
    [bg, fg] = [Js.parse_color(background), Js.parse_color(foreground)]
    alpha = 1 - opacity
    r = Math.round(fg[0] * opacity + bg[0] * alpha)
    g = Math.round(fg[1] * opacity + bg[1] * alpha)
    b = Math.round(fg[2] * opacity + bg[2] * alpha)
    "#" + [r,g,b].map((v) -> v.toString(16).padStart(2, '0')).join('')

  parse_color: (color) ->
    if typeof color is 'string'
      if color[0] is '#'
        switch color.length
          when 7
            [parseInt(color[1..2], 16), parseInt(color[3..4], 16), parseInt(color[5..6], 16)]
          when 4
            [parseInt(color[1] + color[1], 16), parseInt(color[2] + color[2], 16), parseInt(color[3] + color[3], 16)]
      else if color.startsWith('rgb')
        rgb = color.match(/\d+/g)?.map(Number)
        rgb.slice(0, 3) if rgb?.length >= 3
    else if Array.isArray(color) and color.length >= 3
      color.slice(0, 3).map(Number)

  selected_text: ->
    Js.selection()?.toString() ? ''

  selection: ->
    window.getSelection?() ? document.getSelection?()

  is_submit_key: (event) ->
    event.which is 13 and not (event.target.matches('textarea') or event.target.isContentEditable)

  is_form_valid: (inputs) ->
    Array.wrap(inputs).all (input) -> input.valid()

  extract_global: (name, { keep = false, constant = false, warn = false } = {}) ->
    if (data = document.getElementById("js_#{name}"))
      global = if constant or data.getAttribute('data-constant') is 'true'
        name.upcase()
      else
        "$#{name}"
      warn_defined_singleton_key(window, global) if warn
      window[global] = JSON.parse(data.getAttribute('data-value'))
      data.remove() unless keep
