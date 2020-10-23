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
    class_attribute :json_accessors

    delegate :json_attribute?, :json_column, :json_key, to: :class
  end

  class_methods do
    def json_attribute(field_types)
      json_accessor(:json_data, field_types)
    end

    def json_attribute?(name)
      return false unless json_accessors
      json_accessors[:json_data].has_key? name
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
            (default.is_a?(Proc) ? I18n.with_locale(locale){ default.call(self) } : default)
        end
      end
    end

    def json_column(name)
      "(#{json_key(name)})::#{POSTGRESQL_TYPES[Array.wrap(json_accessors[:json_data][name]).first]}"
    end

    def json_key(name)
      "json_data->'#{name}'"
    end

    def json_accessor(jsonb_attribute, field_types)
      self.json_accessors ||= {}.with_indifferent_access
      self.json_accessors[jsonb_attribute] ||= {}.with_indifferent_access
      defaults = field_types.each_with_object({}.with_indifferent_access) do |(name, type), defaults|
        next unless type.is_a?(Array) && (options = type.last).is_a?(Hash) && options.key?(:default)
        defaults[name] = options.delete(:default)
      end
      self.json_accessors[jsonb_attribute].merge! field_types

      field_types.each do |name, type|
        attribute name, *type
      end

      accessors = Module.new do
        field_types.each_key do |name|
          define_method "#{name}=" do |value|
            super(value)
            values = (public_send(jsonb_attribute) || {}).with_indifferent_access.merge(name => public_send(name))
            write_attribute(jsonb_attribute, values)
          end

          next unless defaults.has_key? name
          default = defaults[name]

          define_method name do
            if (value = super()).nil?
              (default.is_a?(Proc) ? default.call(self) : default)
            else
              value
            end
          end
        end

        define_method "#{jsonb_attribute}=" do |new_values|
          old_values = public_send(jsonb_attribute)
          new_values = (new_values || {}).with_indifferent_access
          values = old_values.merge! new_values
          write_attribute(jsonb_attribute, values)
          new_values.each do |name, value|
            write_attibute(name, value)
          end
          values
        end

        define_method jsonb_attribute do
          (super() || {}).with_indifferent_access
        end

        define_method "initialize_#{jsonb_attribute}" do
          return unless has_attribute? jsonb_attribute
          (public_send(jsonb_attribute) || {}).each do |name, value|
            next unless has_attribute? name
            write_attribute(name, value)
            clear_attribute_change(name) if persisted?
          end
        end
      end
      include accessors

      after_initialize :"initialize_#{jsonb_attribute}"
    end
  end
end
