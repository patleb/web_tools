class RailsAdmin::Config::Model::Fields::Date < RailsAdmin::Config::Model::Fields::Datetime
  require_rel 'date'

  include self::Formatter

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
      size: 18,
    }
  end
end
