module RailsAdmin::Config::Model::Fields::Enum::Formatter
  extend ActiveSupport::Concern

  included do
    register_instance_option :enum_labels, memoize: :locale do
      nil
    end

    register_instance_option :enum_method, memoize: true do
      plural_name = name.to_s.pluralize
      method_name = "enum_#{plural_name}"
      if klass.respond_to?(method_name) || object.respond_to?(method_name)
        method_name
      else
        plural_name
      end
    end

    register_instance_option :enum do
      enum_values
    end
  end

  def enum_values
    if klass.respond_to? enum_method
      klass.send(enum_method)
    else
      object.send(enum_method)
    end
  end

  def pretty_format_enum(value)
    if (labels = enum_labels)
      if labels.has_key? value
        type, text = labels[value]
        return span_ ".label.label-#{type}", text
      end
    end
    value = value.to_s
    if (list = enum).is_a? Hash
      list.reject{ |_k, v| v.to_s != value }.keys.first.to_s.presence || value
    elsif list.is_a?(::Array) && list.first.is_a?(::Array)
      list.find{ |e| e[1].to_s == value }.try(:first).to_s.presence || value
    else
      value
    end
  end
end
