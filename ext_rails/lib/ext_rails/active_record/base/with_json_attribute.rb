# TODO https://api.rubyonrails.org/classes/ActiveRecord/Store.html
module ActiveRecord::Base::WithJsonAttribute
  extend ActiveSupport::Concern

  POSTGRESQL_TYPES = {
    big_integer: 'BIGINT',
    boolean: 'BOOLEAN',
    date: 'DATE',
    datetime: 'TIMESTAMP',
    decimal: 'NUMERIC',
    float: 'DOUBLE PRECISION',
    integer: 'INTEGER',
    json: 'jsonb',
    string: 'TEXT',
    text: 'TEXT',
    time: 'TIME',
  }.with_indifferent_access

  prepended do
    class_attribute :jsonb_accessors
    class_attribute :jsonb_accessors_defaults

    after_initialize :initialize_jsonb_accessors_defaults

    delegate :json_column, :json_key, to: :class
  end

  def initialize_jsonb_accessors_defaults
    if jsonb_accessors_defaults&.key? :json_data
      jsonb_accessors_defaults[:json_data].each do |field, default|
        next unless send(field).nil?
        value = default.is_a?(Proc) ? default.call : default
        send("#{field}=", value)
      end
    end
  end

  class_methods do
    def json_attribute(field_types)
      jsonb_accessor(:json_data, field_types)
    end

    def json_translate(field_types)
      field_types.each do |field, type|
        if type.is_a?(Array) && (options = type.last).is_a?(Hash) && options.key?(:default)
          default = options.delete(:default)
        end

        json_attribute(I18n.available_locales.each_with_object({}) { |locale, json|
          json.merge! "#{field}_#{locale}": type
        })

        define_method field do |locale = nil, fallback = nil|
          locale ||= Current.locale || I18n.default_locale
          send("#{field}_#{locale}") ||
            send("#{field}_#{fallback || I18n.available_locales.except(I18n.default_locale).first}") ||
            (default.is_a?(Proc) ? default.call(self) : default)
        end
      end
    end

    def json_column(name)
      "(#{json_key(name)})::#{POSTGRESQL_TYPES[Array.wrap(jsonb_accessors[:json_data][name]).first]}"
    end

    def json_key(name)
      "json_data->'#{name}'"
    end

    def jsonb_accessor(jsonb_attribute, field_types)
      self.jsonb_accessors ||= {}.with_indifferent_access
      self.jsonb_accessors[jsonb_attribute] ||= {}.with_indifferent_access
      field_types.each do |field, type|
        next unless type.is_a?(Array) && (options = type.last).is_a?(Hash) && options.key?(:default)
        self.jsonb_accessors_defaults ||= {}.with_indifferent_access
        self.jsonb_accessors_defaults[jsonb_attribute] ||= {}.with_indifferent_access
        self.jsonb_accessors_defaults[jsonb_attribute][field] = options.delete(:default)
      end
      self.jsonb_accessors[jsonb_attribute].merge! field_types
      super
    end
  end
end
