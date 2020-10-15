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

    delegate :json_attribute?, :json_column, :json_key, to: :class
  end

  class_methods do
    def json_attribute(field_types)
      jsonb_accessor(:json_data, field_types)
    end

    def json_attribute?(name)
      return false unless jsonb_accessors
      jsonb_accessors[:json_data].has_key? name
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
          send("#{field}_#{locale}").presence ||
            send("#{field}_#{fallback || I18n.available_locales.except(locale.to_sym).first}").presence ||
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
      defaults = field_types.each_with_object({}.with_indifferent_access) do |(field, type), defaults|
        next unless type.is_a?(Array) && (options = type.last).is_a?(Hash) && options.key?(:default)
        defaults[field] = options.delete(:default)
      end
      self.jsonb_accessors[jsonb_attribute].merge! field_types

      super

      field_types.each_key do |field|
        next unless defaults.has_key? field
        default = defaults[field]
        define_method field do
          if (value = read_attribute(field)).nil?
            (default.is_a?(Proc) ? default.call(self) : default)
          else
            value
          end
        end
      end
    end
  end
end
