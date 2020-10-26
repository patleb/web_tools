# TODO https://api.rubyonrails.org/classes/ActiveRecord/Store.html
module ActiveRecord::Base::WithJsonAttribute
  extend ActiveSupport::Concern

  # TODO array support
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
    class_attribute :json_accessors, instance_accessor: false, instance_predicate: false

    delegate :json_attribute?, :json_key, to: :class
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

    def json_key(name, operator = nil)
      key = "#{quote_column(:json_data)}->>'#{name}'"
      key = "(#{key})::#{POSTGRESQL_TYPES[Array.wrap(json_accessors[:json_data][name]).first]}"
      key = "#{key} #{operator} ?" if operator.present?
      key
    end

    def json_accessor(column, field_types)
      self.json_accessors ||= {}.with_indifferent_access
      self.json_accessors[column] ||= {}.with_indifferent_access
      defaults = field_types.each_with_object({}.with_indifferent_access) do |(name, type), defaults|
        next unless type.is_a?(Array) && (options = type.last).is_a?(Hash) && options.key?(:default)
        defaults[name] = options.delete(:default)
      end
      self.json_accessors[column].merge! field_types

      field_types.each do |name, type|
        attribute name, *type
      end

      accessors = Module.new do
        field_types.each_key do |name|
          define_method "#{name}=" do |value|
            super(value)
            values = public_send(column).merge(name => public_send(name))
            write_attribute(column, values)
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

        define_method "#{column}=" do |new_values|
          new_values = (new_values || {}).with_indifferent_access.slice(*self.class.json_accessors[column].keys)
          nil_values = public_send(column).except(*new_values.keys)
          super(new_values)
          nil_values.each_key do |name|
            write_attribute(name, nil)
          end
          new_values.each do |name, value|
            write_attribute(name, value)
          end
        end

        define_method "initialize_#{column}" do
          return unless has_attribute? column
          (public_send(column) || {}).each do |name, value|
            next unless has_attribute? name
            write_attribute(name, value)
            clear_attribute_change(name) if persisted?
          end
        end
      end
      include accessors

      after_initialize :"initialize_#{column}"
    end
  end
end
