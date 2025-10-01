### References
# https://github.com/madeintandem/jsonb_accessor
module ActiveRecord::Base::WithJsonAttribute
  extend ActiveSupport::Concern

  POSTGRESQL_JSON_ACCESSORS = %w(->> #>>)
  POSTGRESQL_JSON_TYPES = {
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
  }.to_hwka

  prepended do
    class_attribute :json_accessors, instance_reader: true, instance_accessor: false, instance_predicate: false

    delegate :json_attribute?, to: :class
  end

  class_methods do
    def json_attributes
      json_accessors[:json_data]
    end

    def json_attribute(fields)
      json_accessor(:json_data, fields)
    end

    def json_attribute?(name)
      return false unless json_accessors
      json_accessors[:json_data].has_key? Array.wrap(name).first
    end

    def json_translate(fields)
      fields = json_normalize_fields(fields)
      defaults = json_extract_defaults! fields
      fields.each do |name, type_options|
        localized_fields = I18n.available_locales.each_with_object({}) do |locale, memo|
          memo.merge! "#{name}_#{locale}": type_options
        end
        json_attribute(localized_fields)
        default = defaults[name]

        define_method name do |locale = nil, fallback = nil|
          locale ||= Current.locale || I18n.default_locale
          value = public_send("#{name}_#{locale}")
          return value unless value.nil?
          fallback ||= I18n.available_locales.except(locale.to_sym).first
          value = public_send("#{name}_#{fallback}")
          return value unless value.nil?
          return I18n.with_locale(locale){ default.call(self) } if default.is_a? Proc
          default
        end
      end
    end

    def json_key(name, as: nil, cast: nil)
      return name unless json_attribute? name
      name, *keys = Array.wrap(name)
      if keys.present?
        type = cast || :text
        key = "#{quote_column(:json_data)}#>>'{#{name},#{keys.join(',')}}'"
      else
        type = cast || json_accessors[:json_data][name].first
        key = "#{quote_column(:json_data)}->>'#{name}'"
      end
      key = "(#{key})::#{POSTGRESQL_JSON_TYPES[type]}"
      return "#{key} AS #{as == true ? [name, *keys].join('_') : as}".sql_safe if as.present?
      key.sql_safe
    end

    # NOTE column (ex.: :json_data) is updated only before validations, but fields are updated when column is updated
    def json_accessor(column, fields)
      self.json_accessors ||= {}.to_hwka
      json_accessors[column] ||= {}.to_hwka
      fields = json_normalize_fields(fields)
      defaults = json_extract_defaults! fields
      previous_keys = json_accessors[column].keys
      json_accessors[column].merge! fields
      fields.each do |name, (type, options)|
        attribute name, type, **options
      end

      accessors = Module.new do
        defaults.each do |name, default|
          define_method name do
            value = super()
            return value unless value.nil?
            return default.call(self) if default.is_a? Proc
            default
          end
        end

        next unless previous_keys.empty?

        define_method "#{column}=" do |new_values|
          new_values = (new_values || {}).to_hwka.slice(*json_accessors[column].keys)
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
          return unless (values = public_send(column)).present?
          values.each do |name, value|
            next unless has_attribute? name
            write_attribute(name, value)
            clear_attribute_change(name) if persisted?
          end
        end

        define_method "nullify_blanks_#{column}" do
          values = json_accessors[column].each_with_object({}) do |(name, (type, _options)), memo|
            value = read_attribute(name)
            next if value.nil?
            memo[name] = value
          end
          write_attribute(column, values)
        end
      end
      include accessors

      if previous_keys.empty?
        after_initialize  :"initialize_#{column}"
        before_validation :"nullify_blanks_#{column}"
      end
    end

    def quote_column(name)
      return name if name.is_a?(Arel::Nodes::SqlLiteral) || POSTGRESQL_JSON_ACCESSORS.any?{ |op| name.to_s.include? op }
      super
    end

    private

    def json_normalize_fields(fields)
      if fields.is_a? Hash
        fields.transform_values do |(type, options)|
          type, options = :string, type if type.is_a? Hash
          [type, options || {}]
        end
      else
        Array.wrap(fields).index_with{ [:string, {}] }
      end
    end

    def json_extract_defaults!(fields)
      fields.each_with_object({}.to_hwka) do |(name, (type, options)), defaults|
        next unless options.has_key?(:default)
        defaults[name] = options.delete(:default)
      end
    end
  end
end
