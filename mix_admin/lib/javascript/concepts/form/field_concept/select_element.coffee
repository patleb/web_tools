# TODO mobile correction https://gist.github.com/brandonaaskov/1596867

class RailsAdmin.Form.FieldConcept::SelectElement
  constants: =>
    REMOTE: 'CLASS'
    SEARCH_BOX: 'CLASS'
    PLACEHOLDER: 'CLASS'
    CONTROL: => "#{@SEARCH_BOX},#{@PLACEHOLDER}"
    LIST_WRAPPER: 'ID'
    LIST: 'ID'
    ITEM: 'CLASS'
    SELECTED: => "#{@LIST} > .active"
    SPACER: 'CLASS'
    SHOW: 'CLASS'
    HIDE: 'CLASS'
    BLANK: '__BLANK__'

  document_on: => [
    'focus', @REMOTE, (event, target) =>
      @concept.fields[target.attr('id')].render()

    'focus', @PLACEHOLDER, (event, target) =>
      select = @concept.fields[target.data('id')]
      select.render() unless select.keep_focus

    'blur', @CONTROL, (event, target) =>
      if (select = @concept.fields?[target.data('id')]) # could blur on back/forward navigation
        select.close() unless select.keep_focus

    'keydown', @CONTROL, (event, target) =>
      @concept.fields[target.data('id')].update_on_keydown(event)

    'keyup', @CONTROL, (event, target) =>
      @concept.fields[target.data('id')].update_on_keyup(event)

    'mousedown', @ITEM, (event) =>
      @concept.fields[$(@LIST_WRAPPER).data('id')].keep_focus = (event.which == 1)

    'click', @ITEM, (event, target) =>
      select = @concept.fields[$(@LIST_WRAPPER).data('id')]
      select.update_input(target.data())
      select.close() if select.keep_focus
  ]

  ready: =>
    $("#{@LIST_WRAPPER} > .dropdown.open").removeClass('open')

  constructor: (@input) -> # @control Must Be Defined
  render:          -> throw 'NotImplementedError'
  update_input:    -> throw 'NotImplementedError'
  update_on_keyup: -> throw 'NotImplementedError'

  update_on_keydown: (event) =>
    # TODO must consider SHIFT+TAB as well
    item = $(@SELECTED)
    switch event.which
      when $.ui.keyCode.ESCAPE
        @control.blur()

      when $.ui.keyCode.ENTER
        @enter(item)
        @control.blur()

      when $.ui.keyCode.UP
        @up(item)
        event.preventDefault()

      when $.ui.keyCode.DOWN
        @down(item)
        event.preventDefault()

      when $.ui.keyCode.PAGE_UP
        @first(item)

      when $.ui.keyCode.PAGE_DOWN
        @last(item)
      else
        return
    @scroll()

  close: =>
    $(@LIST_WRAPPER).remove()
    @keep_focus = false

  # See: RailsAdmin.Form.ModalFormConcept#update
  # TODO rename label to text (to simplify option.text usage)
  update_select: (input, { value, text, multiple = false }) ->
    if (item = input.find_by(value: value)).length
      # EDIT
      item.text(text)
    else
      # NEW
      input.append(option$ value: value, text: text)
    if multiple
      values = input.val()
      values.push(value)
      input.set_value(values)
    else
      input.set_value(value)
    input.change()

  #### PROTECTED ####

  show_field:  -> throw 'NotImplementedError'

  render_list: =>
    $(@LIST_WRAPPER).remove()
    list_wrapper =
      div$ @LIST_WRAPPER, data: { id: @input.attr('id') },
        div_ '.dropdown.open.input-group.col-sm-12',
          ul_ @LIST, class: 'dropdown-menu', style: "max-height: #{Device.height}px"
    @control.after(list_wrapper)
    list_wrapper.find(@LIST)

  append_item: (list, query, { value, text }) =>
    query = query.safe_regex()
    value = value.to_s().safe_text()
    text = text.safe_text()
    item =
      if (blank = (value == @BLANK))
        if text == 'true'
          text = @BLANK
          span_ @BLANK, style: 'opacity: 0'
        else
          text
      else if query.blank() || (exact = ///^#{query}$///i.match(text))
        text
      else
        text.gsub(///(#{query})///i, "<strong>$1</strong>")

    selected = 'active' if (blank && query.blank()) || exact

    list.append(
      li_ @ITEM, class: selected, data: { value, text },
        a_ item.html_safe(true), href: '#'
    )

  #### PRIVATE ####

  enter: (item) =>
    if item.length
      @update_input(item.data())

  down: (item) =>
    if item.length
      if (next = item.next(@ITEM)).length
        item.removeClass('active')
        next.addClass('active')
    else
      $(@ITEM).first().addClass('active')

  up: (item) =>
    if item.length
      if (prev = item.prev(@ITEM)).length
        item.removeClass('active')
        prev.addClass('active')
    else
      $(@ITEM).first().addClass('active')

  first: (item) =>
    if item.length
      item.removeClass('active')
    $(@LIST).find(@ITEM).first().addClass('active')

  last: (item) =>
    if item.length
      item.removeClass('active')
    $(@LIST).find(@ITEM).last().addClass('active')

  scroll: =>
    $(@LIST).scroll_to(@SELECTED)
