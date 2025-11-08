class Js.AdminConcept
  readers: ->
    action: -> Rails.find('.js_action').data('value')
    model: -> Rails.find('.js_model')?.data('value')
    scroll_menu: -> Rails.find('.js_scroll_menu')
    scroll_x: -> @model and @bulk_form and @store('scroll_x')?["#{@model}_#{@action}"]
    bulk_form_scroll_x: -> Rails.$('.js_bulk_form th')
    bulk_form: -> Rails.find('.js_bulk_form')
    bulk_toggles: -> Rails.$('.js_bulk_toggles')
    bulk_checkboxes: -> Rails.$('.js_bulk_checkboxes')
    bulk_buttons: -> Rails.$('.js_bulk_buttons')
    table_head_position: -> { bottom: Device.move.y + e.top + e.height } if (e = @table_head?.getBoundingClientRect())
    table_head: -> Rails.find('.js_table_head')
    table_body: -> Rails.find('.js_table_body')
    export_toggles: -> Rails.$('.js_export_toggles')

  events: -> [
    Device.RESIZE_Y, document, @toggle_scoll_menu
    Device.RESIZE_X, document, @toggle_scoll_menu
    Device.RESIZE_X, document, @reset_table_head.debounce()
    Device.SCROLL_Y, document, @toggle_table_head.debounce()

    'change', '.js_bulk_toggles', (event, target) ->
      @toggle_checkboxes(target, @bulk_checkboxes)
      @toggle_bulk_form()

    'change', '.js_bulk_checkboxes', @toggle_bulk_form

    'change', '.js_export_toggles', (event, target) ->
      @toggle_checkboxes(target, @export_checkboxes(target))
      @toggle_export_schema()

    'change', '.js_export_checkboxes', @toggle_export_schema
  ]

  ready: ->
    @restore_bulk_form_scroll()
    @toggle_bulk_form()
    @toggle_export_schema()
    @mouse_scroll_x = @bulk_form_scroll_x.map (scroll) =>
      Hamster(scroll).wheel (event, delta, dx, dy) =>
        event.preventDefault()
        @bulk_form.scrollLeft -= 40 * dy

  leave: ->
    @persist_bulk_form_scroll()
    @mouse_scroll_x.each (scroll) -> scroll.unwheel()

  restore_bulk_form_scroll: ->
    if @scroll_x
      @bulk_form.scrollLeft = @scroll_x.left * (@bulk_form.clientWidth / @scroll_x.width)

  persist_bulk_form_scroll: ->
    if @model and @bulk_form
      scroll_x = { left: @bulk_form.scrollLeft, width: @bulk_form.clientWidth }
      stored_scroll_x = @store('scroll_x') ? {}
      @store('scroll_x', stored_scroll_x.merge("#{@model}_#{@action}": scroll_x))

  toggle_bulk_form: ->
    return unless @bulk_toggles.present()
    [all_checked, none_checked] = @toggle_toggles(@bulk_toggles, @bulk_checkboxes)
    @bulk_buttons.each (button) -> button.toggleAttribute('disabled', none_checked)

  toggle_export_schema: ->
    return unless @export_toggles.present()
    @export_toggles.each (toggle) =>
      @toggle_toggles(Array.wrap(toggle), @export_checkboxes(toggle))
    # TODO disable buttons if none selected

  export_checkboxes: (toggle) ->
    toggle.closest('label').next_siblings().map (label) -> label.find('.js_export_checkboxes')

  toggle_scoll_menu: ->
    return unless @scroll_menu
    @scrollable_was = @scrollable
    @scrollable = Device.full_size.y > Device.size.y * 2
    return if @scrollable is @scrollable_was
    @scroll_menu.toggle_class('hidden', not @scrollable)

  reset_table_head: ->
    @nullify('table_head_position')
    @toggle_table_head()

  toggle_table_head: ->
    return unless @table_head_position
    @visible_was = @visible
    @visible = @table_head_position.bottom > Device.move.y
    return if @visible is @visible_was
    @table_body.toggle_class('visible_head', @visible)

  # Private

  toggle_checkboxes: (toggle, checkboxes) ->
    checked = toggle.get_value()
    checkboxes.each (checkbox) -> checkbox.set_value(checked)

  toggle_toggles: (toggles, checkboxes) ->
    all_checked = true
    none_checked = true
    toggle_checked = toggles.map (toggle) -> toggle.get_value()
    checkboxes.each (checkbox) ->
      checked = checkbox.get_value()
      all_checked &&= checked
      none_checked &&= not checked
    toggles.each((toggle, i) -> toggle.set_value(false) if none_checked and toggle_checked[i])
    toggles.each((toggle, i) -> toggle.set_value(true) if all_checked and not toggle_checked[i])
    [all_checked, none_checked]
