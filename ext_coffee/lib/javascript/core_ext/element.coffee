HTMLElement.define_methods
  is_a: (klass) ->
    @constructor is klass

  to_s: ->
    @outerHTML

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

  $0: (selector) ->
    @querySelector(selector)

  get_value: ->
    return if not @name or @disabled or @hasAttribute('disabled')
    return if @matches('fieldset[disabled] *')
    if @matches('select')
      value = []
      for option in Array.wrap(@options)
        value.push(option.value) if option.selected
      value = value[0] unless @multiple
      value
    else if @checked or @type not in ['radio', 'checkbox', 'submit']
      @value
