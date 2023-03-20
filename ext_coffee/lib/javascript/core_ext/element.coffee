HTMLElement.define_methods
  is_a: (klass) ->
    @constructor is klass

  to_s: ->
    @outerHTML

  html_safe: ->
    true

  classes: ->
    Array.wrap(@classList)

  add_class: (tokens...) ->
    @classList.add(tokens...)
    this

  remove_class: (tokens...) ->
    @classList.remove(tokens...)
    this

  replace_class: (old_token, new_token) ->
    @classList.replace(old_token, new_token)

  toggle_class: (token, force = null) ->
    @classList.toggle(token, force)

  $: (selector) ->
    Array.wrap(@querySelectorAll(selector))

  once: (selector, callback) ->
    elements = @$("#{selector}:not([data-once])")
    elements.each (element) ->
      callback(element)
      element.setAttribute('data-once', true)
    elements

  find: (selector) ->
    @querySelector(selector)

  get_value: ->
    return if @disabled or @hasAttribute('disabled')
    switch @type
      when 'select-one', 'select-multiple'
        value = []
        for option in Array.wrap(@options)
          value.push(option.value) if option.selected
        value = value[0] unless @multiple
        value
      when 'radio', 'checkbox'
        @checked
      else
        @value

  set_value: (value, { event = false } = {}) ->
    return value if @disabled or @hasAttribute('disabled')
    switch @type
      when 'select-one', 'select-multiple'
        selected_was = []
        selected = []
        changed = false
        for option in Array.wrap(@options)
          if option.selected
            selected_was.push(option)
            changed ||= option.value isnt value
          if option.value is value
            selected.push(option)
            changed ||= not option.selected
        return value unless changed
        selected_was.each (option) -> option.selected = false
        selected.each (option) -> option.selected = true
      when 'radio', 'checkbox'
        return value unless @checked isnt value
        this.checked = value
      else
        return value unless @value isnt value
        this.value = value
    switch event
      when 'change', true then Rails.fire(this, 'change')
      when 'input'        then Rails.fire(this, 'input')
    value

  cursor_start: (move = false) ->
    if move
      @setSelectionRange?(0, 0)
    @selectionStart || 0

  cursor_end: (move = false) ->
    if move
      caret_position = @value.length * 2
      @setSelectionRange?(caret_position, caret_position)
    @selectionEnd || 0
