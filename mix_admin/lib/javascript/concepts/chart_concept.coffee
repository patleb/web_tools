# https://github.com/chartjs/Chart.js/issues/5106 --> wait version 2.8
class RailsAdmin.ChartConcept
  constants: ->
    CONFIG: '.js_chartkick_config'
    CHART_ID: 'chart-1'
    INIT: 'ID'
    ADDED_LIST: 'CLASS'
    ADDED_ITEM: 'CLASS'
    ADD_LINK: 'CLASS'
    FORM: 'CLASS'
    INPUTS: 'CLASS'
    SUBMIT_BUTTON: 'CLASS'

  document_on: => [
    'click', @ADD_LINK, (event) =>
      options = @current_item()
      @append_item(options)

    'click', "#{@ADDED_ITEM} .delete", (event, target) =>
      item = target.closest(@ADDED_ITEM)
      @remove_item(item)

    'keydown', '#chart_action > form', (event) =>
      if event.which == $.ui.keyCode.ENTER
        event.preventDefault()
        $(@SUBMIT_BUTTON).click()

    'pjax:submit', @FORM, (event, pjax, options) =>
      RailsAdmin.FilterBoxConcept.merge_params(options, @CHART_ID)
  ]

  ready: =>
    return unless Main.chart_action

    @charts = $(@CONFIG).each_with_object {}, (chart, result) ->
      config = chart.data('config')
      result[config.id] = new Chartkick[config.type](config.id, config.source, config.options)

    if (charts = $("#{@INIT}:not(.#{$.ONCE})")).length
      if (list = charts.data('init'))
        @render_list(list)
      charts.add_once()
    @toggle_list()

  leave: =>
    (@charts || {}).each (id, chart) ->
      chart.stopRefresh()

  ### list = {
        uid_0: [
          { index: uid_0, input: {name: 'field', value: 'field_value'},   label: {name: 'Field', value: 'FieldValue'} },
          { index: uid_0, input: {name: 'calculation', value: 'average'}, label: {name: 'Calculation', value: 'average'} }
        ],
        uid_1: [...]
      }
  ###
  render_list: (list) =>
    return unless list.present()

    list = @json_to_list(list) if list.is_a String
    $(@ADDED_LIST).html list.html_map (uid, options) =>
      @render_item(options)
    @toggle_list()

  append_item: (options) =>
    unless $("#{@ADDED_ITEM}[data-key='#{@uniq_key(options)}']").length
      $(@ADDED_LIST).append @render_item(options)
      @toggle_list()
      RailsAdmin.ChooseConcept.clear()

  remove_item: (item) =>
    item.remove()
    @toggle_list()
    RailsAdmin.ChooseConcept.clear()

  render_item: (options) =>
    p_ @ADDED_ITEM, data: { key: @uniq_key(options) }, [
      a_ '.delete', i_('.fa.fa-trash-o.fa-fw'), href: '#'
      options.map (option) =>
        span_ [
          span_ '.label.label-info', option.label.name
          span_ -> option.label.value
        ]
      options.map (option) =>
        input_ type: 'hidden', name: "c[#{option.index}][#{option.input.name}]", value: option.input.value
    ]

  current_item: =>
    index = $.unique_id()
    $(@INPUTS).each_with_object [], (input, memo) =>
      category = { value: @category_name(input), text: @category_label(input) }
      option = input.find(':selected')[0]
      memo.push {
        index: index,
        input: { name: category.value, value: option.value },
        label: { name: category.text, value: option.text }
      }

  ### return = [
    {field: 'field_0', calculation: 'average'},
    {field: 'field_1', calculation: 'minimum'},
    {...}
  ]
  ###
  current_fields: =>
    $(@ADDED_ITEM).each_with_object [], (wrapper, fields) =>
      inputs = wrapper.find('input')
      fields.push @categories().each_with_object {}, (category, memo) ->
        memo[category] = inputs.filter("[name$='[#{category}]']").first().val()

  #### PRIVATE ####

  json_to_list: (json) =>
    json.to_h().each_with_object {}, (options, list) =>
      index = $.unique_id()
      list[index] = options.each_with_object [], (category, value, memo) =>
        return unless (fields = @available_fields()[category])?[value]
        memo.push {
          index: index,
          input: { name: category, value: value },
          label: { name: fields._label, value: fields[value] }
        }

  available_fields: =>
    @_available_fields ||= $(@INPUTS).each_with_object {}, (select, categories) =>
      fields = select.find('option').each_with_object {}, (option, memo) ->
        memo[option.val()] = option.text()
      fields._label = @category_label(select)
      categories[@category_name(select)] = fields

  categories: =>
    @available_fields().keys()

  category_name: (select) ->
    select.attr('name').match(/\[(\w+)\]$/)[1]

  category_label: (select) ->
    $("label[for='#{select.attr('id')}']").html()

  uniq_key: (options) ->
    options.map((option) => option.input.value).join('-')

  toggle_list: =>
    if $(@ADDED_ITEM).length
      $(@ADDED_LIST).show()
    else
      $(@ADDED_LIST).hide()
