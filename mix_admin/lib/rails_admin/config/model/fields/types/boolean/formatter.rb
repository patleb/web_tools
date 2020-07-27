module RailsAdmin::Config::Model::Fields::Boolean::Formatter
  extend ActiveSupport::Concern

  included do
    register_instance_option :export_format, memoize: true do
      :boolean_and_null
    end
  end

  def pretty_format_boolean(value = self.value)
    case value
    when TrueClass
      %{<span class='label label-success label_boolean'>&#x2713;</span>}
    when FalseClass
      %{<span class='label label-danger label_boolean'>&#x2718;</span>}
    else
      %{<span class='label label-default label_boolean'>&#x2012;</span>}
    end.html_safe
  end

  def export_format_boolean(value = self.value)
    case export_format
    when :boolean_and_null
      value.nil? ? 'null' : value.to_s
    when :integer_and_null
      value.nil? ? 'null' : value.to_i.to_s
    when :integer
      value.nil? ? '' : value.to_i.to_s
    else
      value.to_s
    end
  end
end
