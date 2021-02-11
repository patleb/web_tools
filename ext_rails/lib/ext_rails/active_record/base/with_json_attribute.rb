# TODO https://github.com/guyboertje/arel-pg-json
module ActiveRecord::Base::WithJsonAttribute
  extend ActiveSupport::Concern

  POSTGRESQL_JSON_ACCESSORS = %w(->> #>>)
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
    interval: 'INTERVAL',
  }.with_keyword_access

  prepended do
    class_attribute :json_accessors, instance_accessor: false, instance_predicate: false

    delegate :json_attribute?, to: :class
  end

  class_methods do
    def json_attribute(field_types)
      json_accessor(:json_data, field_types)
    end

    def json_attribute?(name)
      return false unless json_accessors
      json_accessors[:json_data].has_key? Array.wrap(name).first
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

    def json_key(name, as: nil, cast: nil)
      return name unless json_attribute? name
      name, *keys = Array.wrap(name)
      if keys.present?
        key = "#{quote_column(:json_data)}#>>'{#{name},#{keys.join(',')}}'"
        key = "(#{key})::#{POSTGRESQL_TYPES[cast || :text]}"
      else
        key = "#{quote_column(:json_data)}->>'#{name}'"
        key = "(#{key})::#{POSTGRESQL_TYPES[cast || Array.wrap(json_accessors[:json_data][name]).first]}"
      end
      return "#{key} AS #{as == true ? [name, *keys].join('_') : as}".sql_safe if as.present?
      key.sql_safe
    end
    alias_method :jk, :json_key

    def json_accessor(column, field_types)
      self.json_accessors ||= {}.with_keyword_access
      self.json_accessors[column] ||= {}.with_keyword_access
      field_types = Array.wrap(field_types).map{ |name| [name, :string] }.to_h unless field_types.is_a? Hash
      defaults = field_types.each_with_object({}.with_keyword_access) do |(name, type), defaults|
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
          new_values = (new_values || {}).with_keyword_access.slice(*self.class.json_accessors[column].keys)
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

    def quote_column(name)
      return name if name.is_a?(Arel::Nodes::SqlLiteral) || POSTGRESQL_JSON_ACCESSORS.any?{ |op| name.to_s.include? op }
      super
    end
  end
end
