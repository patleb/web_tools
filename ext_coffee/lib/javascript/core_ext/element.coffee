Element.polyfill_methods
  closest: (selector) ->
    node = this
    while node
      return node if node.nodeType is Node.ELEMENT_NODE and node.matches(selector)
      node = node.parentNode

  remove: ->
    this.parentNode.removeChild(this)

m = Element::matches or
  Element::matchesSelector or
  Element::mozMatchesSelector or
  Element::msMatchesSelector or
  Element::oMatchesSelector or
  Element::webkitMatchesSelector

# Checks if the given native dom element matches the selector
# element::
#   native DOM element
# selector::
#   CSS selector string or
#   a JavaScript object with `selector` and `exclude` properties
#   Examples: "form", { selector: "form", exclude: "form[data-remote='true']"}
Element.override_methods
  matches: (selector) ->
    if typeof selector is 'object' and selector.exclude?
      m.call(this, selector.selector) and not m.call(this, selector.exclude)
    else
      m.call(this, selector)

HTMLElement.decorate_methods
  focus: (options) ->
    if @hasAttribute('tabindex')
      @super(options)
    else
      @setAttribute('tabindex', '-1')
      @super(options)
      @removeAttribute('tabindex')
    return

HTMLElement.define_methods
  is_a: (klass) ->
    @constructor is klass

  to_s: ->
    @outerHTML

  blank: ->
    false

  html_safe: ->
    true

  # NOTE: not meant to be used in attributes
  safe_text: not_implemented

  classes: ->
    Array.wrap(@classList)

  has_class: (token) ->
    @classList.contains(token)

  add_class: (tokens...) ->
    @classList.add(tokens...)
    this

  remove_class: (tokens...) ->
    @classList.remove(tokens...)
    this

  replace_class: (old_token, new_token) ->
    @classList.replace(old_token, new_token)

  toggle_class: (token, force = null) ->
    if force is null
      @classList.toggle(token)
    else
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

  data: (key) ->
    this.getAttribute("data-#{key}")

  next: ->
    this.nextElementSibling

  next_siblings: ->
    sibling = this
    siblings = []
    siblings.push(sibling) while sibling = sibling.nextElementSibling
    siblings

  prev: ->
    this.previousElementSibling

  prev_siblings: ->
    sibling = this
    siblings = []
    siblings.push(sibling) while sibling = sibling.previousElementSibling
    siblings

  get_value: ->
    return if @disabled or @hasAttribute('disabled')
    value = switch @type
      when 'select-one', 'select-multiple'
        value = []
        for option in Array.wrap(@options)
          if option.selected
            choice = cast_value(option, option.value)
            value.push(choice)
        value = value[0] unless @multiple
        value
      when 'radio', 'checkbox'
        @checked
      when 'range'
        value = @value
        value = cast_value(@list.options[value], value) if @list?.present()
        value
      else
        @value
    cast_value(this, value)

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
    if move isnt false
      move = 0 if move is true
      move = 0 if move < 0
      @setSelectionRange?(move, move)
    @selectionStart ? 0

  cursor_end: (move = false) ->
    if move isnt false
      move = @value.length * 2 if move is true
      move = 0 if move < 0
      @setSelectionRange?(move, move)
    @selectionEnd ? 0

  valid: ->
    return true if (form = @closest('form')) and Rails.get(form, 'ujs:formnovalidate-button')
    return true if @formNoValidate
    return @checkValidity() if @checkValidity?
    return @reportValidity() if @reportValidity?
    true

  invalid: ->
    not @valid()

  cast_value = (input, value) ->
    if value? and (cast = input.getAttribute('data-cast'))?
      if args = input.getAttribute 'data-args'
        args = JSON.parse(args)
      value = if cast.scope_constantizable()
        cast.constantize()(value, args)
      else if cast.constantizable() and value[cast]
        value[cast](args)
      else # option
        cast
    value
