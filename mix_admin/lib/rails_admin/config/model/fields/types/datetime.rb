class RailsAdmin::Config::Model::Fields::Datetime < RailsAdmin::Config::Model::Fields::Base
  require_rel 'datetime'

  include self::Formatter

  def parser
    Parser.new(strftime_format)
  end

  def parse_value(value)
    parser.parse_string(value)
  end

  def parse_input(params)
    params[name] = parse_value(params[name]) if params[name]
  end

  def value
    value_in_time_zone(super)
  end

  register_instance_option :formatted_value do
    if (time = value)
      pretty_format_datetime(time)
    else
      ''.html_safe
    end
  end

  register_instance_option :export_value do
    if (time = value)
      export_format_datetime(time)
    else
      ''.html_safe
    end
  end

  register_instance_option :datepicker_options do
    {
      useCurrent: false,
      showClear: true,
      ignoreReadonly: true,
      showTodayButton: true,
      format: parser.to_momentjs,
      locale: Current.locale
    }
  end

  register_instance_option :html_attributes do
    {
      readonly: true,
      required: required?,
      size: 22,
    }
  end

  register_instance_option :sort_reverse? do
    true
  end

  register_instance_option :render do
    div_ '.form-inline' do
      div_('.input-group', [
        form.send(view_helper, method_name, html_attributes.reverse_merge(
          value: form_value,
          class: 'form-control js_field_input js_datetimepicker',
          data: { options: datepicker_options }
        )),
        form.label(method_name, class: 'input-group-addon') do
          i_ '.fa.fa-calendar.fa-fw'
        end
      ])
    end
  end
end
