# TODO bug with input on mobile: https://github.com/marcandre/inputevent
# TODO request to fetch all if (count < max) backend side

class RailsAdmin.Form.FieldConcept::SelectRemoteElement extends RailsAdmin.Form.FieldConcept::SelectElement
  constructor: (@input) ->
    { index_params, @required, @include_blank, selected = [], values = [], texts = [] } = @input.data('config')
    @selected_id = selected.first()
    @selected_name = texts[values.index(@selected_id)] if @selected_id
    @url = Routes.url_for('index', index_params)
    @cached_keys = {}
    @cached_values = {}
    @debounced_fetch = _.debounce(@remote_fetch, 300)
    @find_or_append_control()

  render: =>
    value = @input.find(':selected')[0]?.text || ''
    @render_list()
    @update_list(value)
    @show_field(value)

  update_input: ({ value, text }) =>
    options = @input.children()
    if @include_blank
      options.first().attr(selected: false)
      options.last().remove() if options.length > 1
    else
      options.remove()
    if value == @BLANK
      options.first().attr(selected: true)
    else
      @input.append(option_ selected: true, value: value, text: text)
      @cached_values[value] = text.to_s()
    @input.change()

  update_on_keyup: (event) =>
    query = @control.val()
    switch event.which
      when $.ui.keyCode.DELETE
        @update_list(query)

      when $.ui.keyCode.BACKSPACE
        if @control.cursor_end() == query.length && /\s$/.match(query)
          return
        else
          @update_list(query)
      else
        char = String.fromCharCode(event.which)
        if /[\w ]/.match(char)
          @update_list(query)
        else
          return
    @scroll()

  close: =>
    @input.removeClass(@HIDE_CLASS)
    @control.removeClass(@SHOW_CLASS)
    super()

  #### PRIVATE ####

  find_or_append_control: =>
    input_id = @input.attr('id')
    unless (@control = $("#{@SEARCH_BOX}[data-id=#{input_id}]")).length
      @control =
        input$ @SEARCH_BOX,
          type: 'search'
          placeholder: I18n.t("placeholder")
          class: 'form-control'
          data: { id: input_id }
          autocomplete: 'nope'
      @input.after(@control)

  update_list: (query) =>
    option = @selected_option()
    selected_id = option?.value?.presence()
    selected_name = option.text if selected_id && selected_id != @include_blank
    data =
      switch query
        when selected_name
          [{ value: selected_id, text: selected_name }]
        when @include_blank
          if @selected_name?.present()
            [{ value: @selected_id, text: @selected_name }]
          else
            []
    query = query.downcase().strip()
    if (data ?= @cache_fetch(query))
      @build_list(query, data)
    else
      @debounced_fetch(query)

  selected_option: =>
    @input.children().filter(-> $(this).is_selected(@include_blank))[0]

  show_field: (value) =>
    @control.addClass(@SHOW_CLASS).attr(required: @required).val(value)
    @input.addClass(@HIDE_CLASS)
    spacer = div$ @SPACER
    @input.after(spacer).hide()
    setTimeout =>
      spacer.remove()
      @input.show()
    @control.click().focus().cursor_end(true)
    @control.valid()

  remote_fetch: (query) =>
    @xhr.abort() if @xhr?
    @xhr = $.ajax(
      url: @url
      data: { query }
      fail: "##{@input.attr('id')}, ##{@input.attr('id')} + #{@SEARCH_BOX}, ##{@input.attr('id')} ~ #{@PLACEHOLDER}"
      success: (data, status, xhr) =>
        if xhr.request_id == $.request_id
          @build_list(query, data)
    )

  build_list: (query, data) =>
    list = $(@LIST)
    list.html('')
    @append_item(list, query, value: @BLANK, text: @include_blank) if @include_blank
    @cache_write(query, data).each (item_data) =>
      @append_item(list, query, item_data)

  cache_fetch: (query) =>
    if query.blank()
      return [] if @cached_keys.empty()
    else
      return unless @cached_keys[query]
    @filtered_values(query)

  cache_write: (query, data) =>
    @cached_keys[query] = true
    data.each (item_data) =>
      @cached_values[item_data.value] = item_data.text.to_s()
    @filtered_values(query)

  filtered_values: (query) ->
    values = @cached_values.each_with_object [], (value, text, memo) ->
      unless value.blank() || text.downcase().excludes(query)
        memo.push { value, text }
    values.sort_by('text')
