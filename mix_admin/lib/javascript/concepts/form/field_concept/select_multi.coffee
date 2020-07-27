class RailsAdmin.Form.FieldConcept::SelectMulti
  constants: =>
    TOKEN_LIST: 'CLASS'
    TOKEN_ITEM: 'CLASS'
    CHOSE_ALL: 'CLASS'
    CLEAR_ALL: 'CLASS'
    RESET: 'CLASS'
    REMOVE_SPACER: 'CLASS'
    REMOVE: => "#{@TOKEN_ITEM} > .delete"
    EDIT: 'CLASS'

  document_on: => [
    'click', @CHOSE_ALL, (event, target) =>
      @concept.fields[target.data('id')].chose_all_options()

    'click', @CLEAR_ALL, (event, target) =>
      @concept.fields[target.data('id')].remove_all_tokens()

    'click', @RESET, (event, target) =>
      @concept.fields[target.data('id')].reset_tokens()

    'click', @REMOVE, (event, target) =>
      # TODO add confirm if saved relation
      token = target.closest(@TOKEN_ITEM)
      @concept.fields[token.closest(@TOKEN_LIST).data('id')].remove_token(token.data())

    'dblclick', @EDIT, (event, target) =>
      token = target.closest(@TOKEN_ITEM)
      @concept.fields[token.closest(@TOKEN_LIST).data('id')].render_form(token.data())
  ]

  initialize: =>
    { @edit_params, @removable, @sortable, @include_blank, @selected = [], @values = [], @texts = [] } = @input.data('config') || {}
    @find_or_append_placeholder()
    @find_or_append_token_list()
    @set_control()

  update_input: ({ value, text }) =>
    return if value == @BLANK

    @update_select(@input, { value, text, multiple: true })
    if (item_data = @selected_options().find(value: value))
      # TODO won't work
      item_data.selected = true
      { index, initial } = item_data
      if (old_token = @find_token(value)).length
        # EDIT
        item_data.text = text
        new_token = @render_token({ value, text, index, initial })
        old_token.replaceWith(new_token)
      else
        @append_token({ value, text, index, initial })
    else
      # NEW
      [index, initial] = [@values.length, false]
      @values.push { value, text, index, initial, selected: true }
      @append_token({ value, text, index, initial })

  reset_tokens: =>
    @remove_all_tokens()
    @append_token_refresh()

  chose_all_options: =>
    @remaining_options().each (option) =>
      @update_input(option)

  remove_all_tokens: =>
    @selected_options().each (option) =>
      @remove_token(value: option.value, skip_refresh: true)
    @remove_token_refresh()

  remove_token: ({ value, skip_refresh = false }) =>
    value = value.to_s()
    values = @input.val().except(value)
    @input.set_value(values)
    @find_token(value).remove()
    @remove_token_refresh() unless skip_refresh

  render_form: ({ value }) =>
    if @edit_params
      params = { id: value }.merge(@edit_params)
      url = Routes.url_for('edit', params)
      # TODO @input.id
      RailsAdmin.Form.ModalFormConcept.render_modal(url, @input.attr('id'))

  #### PROTECTED ####

  set_control: ->

  #### PRIVATE ####

  selected_options: =>
    @input.children().filter(-> $(this).is_selected(@include_blank)).to_a()

  remaining_options: =>
    @input.children().filter(-> $(this).not_selected(@include_blank)).to_a()

  find_or_append_placeholder: =>
    input_id = @input.attr('id')
    unless (@placeholder = $("#{@PLACEHOLDER}[data-id=#{input_id}]")).length
      @placeholder = select$ @PLACEHOLDER, class: 'form-control', data: { id: input_id }
      @input.after(@placeholder)

  find_or_append_token_list: =>
    input_id = @input.attr('id')
    unless (@token_list = $("#{@TOKEN_LIST}[data-id=#{input_id}]")).length
      @token_list = div$ @TOKEN_LIST, data: { id: input_id }, style: "max-height: #{Device.height}px"
      @placeholder.after(@token_list)
      @initialize_tokens()
    @configure_sortable() if @sortable

  initialize_tokens: =>
    @values.zip(@texts).each ([value, text], index) =>
      if @selected.includes(value)
        @append_token(value: value, text: text, index: index, initial: true, skip_refresh: true)

  configure_sortable: =>
    @token_list.sortable(
      items: "> #{@TOKEN_ITEM}"
      cursorAt: { top: 52 }
      axis: 'y'
      update: (event, ui) =>
        @reorder_select()
    )

  find_token: (value) =>
    @token_list.find_by('data-value': value)

  append_token: ({ value, text, index, initial = false, skip_refresh = false }) =>
    token = @render_token({ value, text, index, initial })
    if @sortable
      @token_list.append(token)
    else if (previous_token = @token_list.find(@TOKEN_ITEM).filter(-> $(this).data('index') < index)).length
      previous_token.last().after(token)
    else
      @token_list.prepend(token)
    @append_token_refresh() unless skip_refresh

  append_token_refresh: =>
    if @sortable
      @reorder_select()
      @token_list.sortable('refresh')

  remove_token_refresh: =>
    if @sortable
      @token_list.sortable('refresh')

  render_token: ({ value, text, index, initial }) =>
    value = value.to_s().safe_text()
    text = text.safe_text()
    removable_link = '.delete' if @removable || !initial
    p_ @TOKEN_ITEM, data: { value: value, index: index, initial: initial }, style: "max-width: #{@input.outerWidth()}px", [
      a_ removable_link || @REMOVE_SPACER,
        i_ '.fa.fa-trash-o.fa-fw', class: ('icon-danger' if initial)
      span_ '.label.label-info', text, class: (@EDIT_CLASS if @edit_params)
    ]

  reorder_select: =>
    # TODO won't work
    values = @input.val()
    unneeded_values = @values.dup()
    selected_values = @token_list.find(@TOKEN_ITEM).map$ (token) ->
      { value, text } = unneeded_values.delete_if((item_data) -> item_data.value == token.data('value').to_s())[0]
    @input.find("option[value!='']").remove()
    [selected_values, unneeded_values].each (list_data) =>
      list_data.each (item_data) =>
        @input.append(option$ item_data)
    @input.val(values)
