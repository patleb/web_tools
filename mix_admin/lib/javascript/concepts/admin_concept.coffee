class Js.AdminConcept
  DATE = /[0-9]{4}-[0-9]{2}-[0-9]{2}/

  readers: ->
    scroll_menu: -> Rails.find('.js_scroll_menu')
    scroll_x: -> @model() and @bulk_form() and @store('scroll_x')?["#{@model()}_#{@action()}"]
    bulk_form: -> Rails.find('.js_bulk_form')
    bulk_toggles: -> Rails.$('.js_bulk_toggles')
    bulk_checkboxes: -> Rails.$('.js_bulk_checkboxes')
    bulk_buttons: -> Rails.$('.js_bulk_buttons')
    table_head: -> { bottom: Device.move.y + e.top + e.height } if (e = Rails.find('.js_table_head')?.getBoundingClientRect())
    table_body: -> Rails.find('.js_table_body')
    export_toggles: -> Rails.$('.js_export_toggles')
    query_bar: -> Rails.find('.js_query_bar')
    search: -> Rails.find('.js_search')
    action: -> Rails.find('.js_action').data('name')
    model: -> Rails.find('.js_model')?.data('name')

  document_on: -> [
    Device.RESIZE_Y, document, @toggle_scoll_menu
    Device.RESIZE_X, document, @toggle_scoll_menu
    Device.RESIZE_X, document, @reset_table_head.debounce()
    Device.SCROLL_Y, document, @toggle_table_head.debounce()

    'change', '.js_bulk_toggles', (event, target) ->
      @toggle_checkboxes(target, @bulk_checkboxes())
      @toggle_bulk_form()

    'change', '.js_bulk_checkboxes', @toggle_bulk_form

    'change', '.js_export_toggles', (event, target) ->
      @toggle_checkboxes(target, @export_checkboxes(target))
      @toggle_export_schema()

    'change', '.js_export_checkboxes', @toggle_export_schema

    'search', '.js_search', @on_blank_search

    'turbolinks:submit', '.js_query_bar', ->
      @query_submitted = true

    'change', '.js_query_datetime', (event, target) ->
      @with_search_token(target, (before, token) =>
        if @is_after_operator(before)
          token
        else if @is_after_separator(before)
          "=#{token}"
        else if target.type is 'time'
          if before.last() is 'T'
            token
          else if before.match DATE
            "T#{token}"
      , reset: true, before_size: 10)

    'change', '.js_query_keyword', (event, target) ->
      @with_search_token(target, (before, token) =>
        if @is_after_operator(before, equality_only: true)
          token
        else if @is_after_separator(before)
          "=#{token}"
      , reset: true)

    'change', '.js_query_operator', (event, target) ->
      @with_search_token(target, (before, token) =>
        token if @is_after_separator(before)
      , reset: true)

    'click', '.js_query_or', (event, target) ->
      @with_search_token(target, (before, token) =>
        token unless @is_after_operator(before) or @is_after_separator(before)
      , token: '|')

    'click', '.js_query_and', (event, target) ->
      @with_search_token(target, (before, token) =>
        return token if before.end_with(' ')
        " #{token}" unless @is_after_operator(before) or @is_after_separator(before)
      , token: '{_}')

    'click', '.js_query_field', (event, target) ->
      @with_search_token(target, (before, token) =>
        return if before is '_}' or @is_after_operator(before)
        switch before.last() ? ''
          when '', ' ' then "{#{token}}"
          when '{'     then token
          when '}'     then { reopen: true, result: "|#{token}}" }
          when '|' # do nothing
          else " {#{token}}"
      , token: target.data('field'))
  ]

  ready: ->
    @restore_scroll_x()
    @toggle_bulk_form()
    @toggle_export_schema()
    @query_submitted = false

  leave: ->
    @persist_scroll_x()

  restore_scroll_x: ->
    if (scroll_x = @scroll_x())
      @bulk_form().scrollLeft = scroll_x.left * (@bulk_form().clientWidth / scroll_x.width)

  persist_scroll_x: ->
    if @model() and @bulk_form()
      scroll_x = { left: @bulk_form().scrollLeft, width: @bulk_form().clientWidth }
      stored_scroll_x = @store('scroll_x') || {}
      @store('scroll_x', stored_scroll_x.merge("#{@model()}_#{@action()}": scroll_x))

  toggle_bulk_form: ->
    return unless (toggles = @bulk_toggles()).present()
    [all_checked, none_checked] = @toggle_toggles(toggles, @bulk_checkboxes())
    @bulk_buttons().each (button) -> button.toggleAttribute('disabled', none_checked)

  toggle_export_schema: ->
    return unless (toggles = @export_toggles()).present()
    toggles.each (toggle) =>
      @toggle_toggles(Array.wrap(toggle), @export_checkboxes(toggle))
    # TODO disable buttons if none selected

  export_checkboxes: (toggle) ->
    toggle.closest('label').next_siblings().map (label) -> label.find('.js_export_checkboxes')

  toggle_scoll_menu: ->
    return unless @scroll_menu()
    @scrollable_was = @scrollable
    @scrollable = Device.full_size.y > Device.size.y * 2
    return if @scrollable is @scrollable_was
    @scroll_menu().toggle_class('hidden', not @scrollable)

  reset_table_head: ->
    @nullify('table_head')
    @toggle_table_head()

  toggle_table_head: ->
    return unless @table_head()
    @visible_was = @visible
    @visible = @table_head().bottom > Device.move.y
    return if @visible is @visible_was
    @table_body().toggle_class('visible_head', @visible)

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

  on_blank_search: (event, target) ->
    return if @query_submitted
    return if target.get_value()?.present()
    return unless Routes.decode_params().q
    Rails.fire @query_bar(), 'submit'

  with_search_token: (target, callback, { reset = false, before_size = 2, token = target.get_value() } = {}) ->
    search = @search().get_value() ? ''
    cursor_end = @search().cursor_end()
    cursor_start = cursor_end - before_size
    cursor_start = 0 if cursor_start < 0
    before = search[cursor_start...cursor_end] or search[cursor_end - 1] ? ''
    token = callback(before, token)
    if token?.reopen
      search = search.insert(cursor_end - 1, token.result, replace: 1)
      move = cursor_end - 1 + token.result.size()
    else if token
      search = search.insert(cursor_end, token)
      move = cursor_end + token.size()
    else
      move = cursor_end
    target.set_value('') if reset # otherwise can't reuse the same value, the 'change' event won't fire
    @search().set_value(search)
    @search().focus()
    @search().cursor_end(move)

  is_after_operator: (before, { equality_only = false } = {}) ->
    if equality_only
      before.last(2)?.match /[=!]=?$/
    else
      before.last(2)?.match /[=!<>]=?$/

  is_after_separator: (before) ->
    before is '' or before.match /[ }|]$/
