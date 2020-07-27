class RailsAdmin.FilterBoxConcept
  constants: =>
    MENU: 'ID'
    INIT: 'ID'
    CONTAINER: 'ID'
    FILTERS: => "#{@CONTAINER} > p"
    OPTION: 'CLASS'
    SHARED: 'CLASS'
    FORM: 'CLASS'
    CLEAR: 'CLASS'
    INPUT: 'CLASS'
    FIELD: 'CLASS'

  document_on: => [
    'click', @MENU, (event, target) ->
      # TODO hide if mobile and no filters, open on click

    'click', @OPTION, (event, target) =>
      option = target.data('option')
      field_name = option.name
      unless @uniq_filters[field_name]
        @uniq_filters[field_name] = true
        @append
          label: option.label
          name:  field_name
          type:  option.type
          value: option.value
          operator: option.operator
          select_options: option.options
          index: $.unique_id()
          datetimepicker_format: option.datetimepicker_format
        RailsAdmin.TableConcept.refresh()

    'click', "#{@CONTAINER} .delete", (event, target) =>
      # TODO bug when switching scope/action, deleted filters come back
      filter = target.closest(@FIELD)
      field_name = filter.data('field_name')
      @uniq_filters[field_name] = false
      filter.remove()
      RailsAdmin.TableConcept.refresh()

    'click', "#{@CONTAINER} .switch-select", (event, target) ->
      selected_select = target.siblings('select:visible')
      not_selected_select = target.siblings('select:hidden')
      not_selected_select.attr(name: not_selected_select.data('name')).show('slow')
      selected_select.attr(name: null).hide('slow')
      target.find('i').toggleClass("fa-plus fa-minus")

    'change', "#{@CONTAINER} .switch-additional-fieldsets", (event, target) ->
      selected_option = target.find('option:selected')
      if (klass = $(selected_option).data('additional-fieldset'))
        target.siblings(".additional-fieldset:not(.#{klass})").hide('slow')
        target.siblings(".#{klass}").show('slow')
      else
        target.siblings('.additional-fieldset').hide('slow')

    'click', @CLEAR, (event, target) =>
      $(@INPUT).val("")
      if Main.index_action || Main.trash_action
        $(@CONTAINER).html("")
        target.parents("form").submit()

    'pjax:click', @SHARED, (event, pjax, options) =>
      @merge_params(options)
  ]

  ready: =>
    return unless (@container = $(@CONTAINER)).length

    $(@FILTERS).remove()
    if (filters = $(@INIT).data('init'))?
      filters.each (options) =>
        @append(options)

    @uniq_filters = {}
    $(@FILTERS).each$ (filter) =>
      field_name = filter.data('field_name')
      if @uniq_filters[field_name]
        filter.remove()
      else
        @uniq_filters[field_name] = true

  merge_params: (options, hash = null) =>
    url = $.parse_location(options.url, hash: hash)
    params = $.flat_params(url.search)
    params = $.merge_params(params, $(@FORM).serialize())
    delete params.query if params.query?.blank()
    url.search = $.param(params)
    options.url = url.href

  #### PRIVATE ####

  append: ({ label, name, type, value, operator, select_options, index, datetimepicker_format }) =>
    value_name = "f[#{name}][#{index}][v]"
    operator_name = "f[#{name}][#{index}][o]"
    switch type
      when 'boolean'
        control =
          select_ '.input-sm.form-control', name: value_name, [
            option_ '...', value: '_ignore'
            option_ I18n.t('true'), @option_attributes(value, 'true')
            option_ I18n.t('false'), @option_attributes(value, 'false')
            option_ '---------', disabled: true
            option_ I18n.t('is_present'), @option_attributes(value, '_present')
            option_ I18n.t('is_blank'), @option_attributes(value, '_blank')
          ]
      when 'date', 'datetime', 'timestamp'
        control =
          select_ '.switch-additional-fieldsets.input-sm.form-control', name: operator_name, [
            option_ I18n.t('date'), @option_attributes(operator, 'default', data: { 'additional-fieldset': 'default' })
            option_ I18n.t('between_and_'), @option_attributes(operator, 'between', data: { 'additional-fieldset': 'between' })
            option_ I18n.t('today'), @option_attributes(operator, 'today')
            option_ I18n.t('yesterday'), @option_attributes(operator, 'yesterday')
            option_ I18n.t('this_week'), @option_attributes(operator, 'this_week')
            option_ I18n.t('last_week'), @option_attributes(operator, 'last_week')
            option_ '---------', disabled: true
            option_ I18n.t('is_present'), @option_attributes(operator, '_not_null')
            option_ I18n.t('is_blank'), @option_attributes(operator, '_null')
          ]
        input_attributes = {
          type: 'text'
          name: "#{value_name}[]"
          autocomplete: 'nope'
        }
        if type == 'date'
          input_attributes.size = 20
          input_type = 'date'
        else
          input_attributes.size = 25
          input_type = 'datetime'
        if Device.phone
          input_attributes.readonly = true
        additional_control = h_(
          input_ ".#{input_type}.additional-fieldset.default.input-sm.form-control", input_attributes.merge(
            value: value[0]
            style: "display:#{if !operator || operator == 'default' then 'inline-block' else 'none'};"
          )
          input_ ".#{input_type}.additional-fieldset.between.input-sm.form-control", input_attributes.merge(
            placeholder: '-∞'
            value: value[1]
            style: "display:#{if operator == 'between' then 'inline-block' else 'none'};"
          )
          input_ ".#{input_type}.additional-fieldset.between.input-sm.form-control", input_attributes.merge(
            placeholder: '∞'
            value: value[2]
            style: "display:#{if operator == 'between' then 'inline-block' else 'none'};"
          )
        )
      when 'enum', 'sti'
        multiple = value.is_a(Array)
        control = h_(
          select_ '.select-one.input-sm.form-control',
            data: { name: value_name }
            name: (value_name unless multiple),
            style: "display:#{if multiple then 'none' else 'inline-block'}"
          , [
            option_ '...', value: '_ignore'
            option_ I18n.t('is_present'), @option_attributes(value, '_present')
            option_ I18n.t('is_blank'), @option_attributes(value, '_blank')
            option_ '---------', disabled: true
            select_options.html_safe(true)
          ]
          select_ '.select-multiple.input-sm.form-control',
            multiple: true
            data: { name: "#{value_name}[]" }
            name: ("#{value_name}[]" if multiple)
            style: "display:#{if multiple then 'inline-block' else 'none'}"
          ,
            select_options.html_safe(true)
          a_ '.switch-select', href: '#',
            i_ ".fa.fa-#{if multiple then 'minus' else 'plus'}"
        )
      when 'string', 'text', 'belongs_to_association'
        control =
          select_ '.switch-additional-fieldsets.input-sm.form-control', value: operator, name: operator_name, [
            option_ I18n.t('contains'), @option_attributes(operator, 'like', data: { 'additional-fieldset': 'additional-fieldset' })
            option_ I18n.t('is_exactly'), @option_attributes(operator, 'is', data: { 'additional-fieldset': 'additional-fieldset' })
            option_ I18n.t('starts_with'), @option_attributes(operator, 'starts_with', data: { 'additional-fieldset': 'additional-fieldset' })
            option_ I18n.t('ends_with'), @option_attributes(operator, 'ends_with', data: { 'additional-fieldset': 'additional-fieldset' })
            option_ '---------', disabled: true
            option_ I18n.t('is_present'), @option_attributes(operator, '_not_null')
            option_ I18n.t('is_blank'), @option_attributes(operator, '_null')
          ]
        additional_control =
          input_ '.additional-fieldset.input-sm.form-control',
            type: 'text'
            name: value_name
            value: value
            style: "display:#{if operator == '_blank' || operator == '_present' then 'none' else 'inline-block'};"
      when 'integer', 'decimal', 'float', 'foreign_key'
        control =
          select_ '.switch-additional-fieldsets.input-sm.form-control', name: operator_name, [
            option_ I18n.t('number'), @option_attributes(operator, 'default', data: { 'additional-fieldset': 'default' })
            option_ I18n.t('between_and_'), @option_attributes(operator, 'between', data: { 'additional-fieldset': 'between' })
            option_ '---------', disabled: true
            option_ I18n.t('is_present'), @option_attributes(operator, '_not_null', data: { 'additional-fieldset': '_not_null' })
            option_ I18n.t('is_blank'), @option_attributes(operator, '_null', data: { 'additional-fieldset': '_null' })
          ]
        input_attributes = {
          type: 'number'
          name: "#{value_name}[]"
        }
        additional_control = h_(
          input_ '.additional-fieldset.default.input-sm.form-control', input_attributes.merge(
            value: value[0]
            style: "display:#{if !operator || operator == 'default' then 'inline-block' else 'none'};"
          )
          input_ '.additional-fieldset.between.input-sm.form-control', input_attributes.merge(
            placeholder: '-∞'
            value: value[1]
            style: "display:#{if operator == 'between' then 'inline-block' else 'none'};"
          )
          input_ '.additional-fieldset.between.input-sm.form-control', input_attributes.merge(
            placeholder: '∞'
            value: value[2]
            style: "display:#{if operator == 'between' then 'inline-block' else 'none'};"
          )
        )
      else
        control = input_ '.input-sm.form-control', type: 'text', name: value_name, value: value

    content =
      p$ @FIELD, data: { field_name: name }, [
        a_ '.delete', href: '#', [
          i_ '.fa.fa-trash-o.fa-fw' unless Main.export_action
          span_ '.label.label-info', label.html_safe(true)
        ]
        control
        additional_control
      ]

    @container.append(content)
    content.find('.date, .datetime').datetimepicker(
      locale: I18n.locale
      useCurrent: false
      showClear: true
      ignoreReadonly: true
      showTodayButton: true
      format: datetimepicker_format
    )

  option_attributes: (current_value, option_value, attributes) ->
    if current_value == option_value
      { selected: true, value: option_value }.merge(attributes)
    else
      { value: option_value }.merge(attributes)
