MonkeyPatch.add{['activerecord', 'lib/active_record/enum.rb', '13fa7931de66b72cb3fa05ba03563d968351f3bac921942a90a91ebc4e02fd1b']}

module ActiveRecord::Enum::EnumType::WithKeywordAccess
  def initialize(*, with_keyword_access: false, **)
    super(*, **)
    @with_keyword_access = with_keyword_access
  end

  def cast(value)
    if mapping.has_key?(value)
      @with_keyword_access ? HashWithKeywordAccess.convert_key(value) : value.to_s
    elsif mapping.has_value?(value)
      mapping.key(value)
    else
      value.presence
    end
  end
end

ActiveRecord::Enum::EnumType.prepend ActiveRecord::Enum::EnumType::WithKeywordAccess

module ActiveRecord::Enum
  module WithKeywordAccess
    extend ActiveSupport::Concern

    class_methods do
      def enum(name, values = nil, **options)
        values, options = options, {} unless values
        _enum(name, values, **options)
      end

      private

      def _enum(name, values, prefix: nil, suffix: nil, scopes: true, instance_methods: true, validate: false, with_keyword_access: true, **options)
        assert_valid_enum_definition_values(values)
        assert_valid_enum_options(options)

        # statuses = { }
        enum_values = with_keyword_access ? HashWithKeywordAccess.new : ActiveSupport::HashWithIndifferentAccess.new
        name = name.to_s

        # def self.statuses() statuses end
        detect_enum_conflict!(name, name.pluralize, true)
        singleton_class.define_method(name.pluralize) { enum_values }
        defined_enums[name] = enum_values

        detect_enum_conflict!(name, name)
        detect_enum_conflict!(name, "#{name}=")

        if respond_to? :virtual_columns_hash
          ar_attribute(name, options.delete(:type), **options)
        else
          attribute(name, options.delete(:type), **options)
        end

        decorate_attributes([name]) do |_name, subtype|
          if subtype == ActiveModel::Type.default_value
            raise "Undeclared attribute type for enum '#{name}' in #{self.name}. Enums must be" \
              " backed by a database column or declared with an explicit type" \
              " via `attribute`."
          end

          subtype = subtype.subtype if EnumType === subtype
          EnumType.new(name, enum_values, subtype, with_keyword_access: with_keyword_access, raise_on_invalid_values: !validate)
        end

        value_method_names = []
        _enum_methods_module.module_eval do
          prefix = if prefix
            prefix == true ? "#{name}_" : "#{prefix}_"
          end

          suffix = if suffix
            suffix == true ? "_#{name}" : "_#{suffix}"
          end

          pairs = values.respond_to?(:each_pair) ? values.each_pair : values.each_with_index
          pairs.each do |label, value|
            enum_values[label] = value
            label = label.to_s

            value_method_name = "#{prefix}#{label}#{suffix}"
            value_method_names << value_method_name
            define_enum_methods(name, value_method_name, value, scopes, instance_methods)

            method_friendly_label = label.gsub(/[\W&&[:ascii:]]+/, "_")
            value_method_alias = "#{prefix}#{method_friendly_label}#{suffix}"

            if value_method_alias != value_method_name && !value_method_names.include?(value_method_alias)
              value_method_names << value_method_alias
              define_enum_methods(name, value_method_alias, value, scopes, instance_methods)
            end
          end
        end
        detect_negative_enum_conditions!(value_method_names) if scopes

        if validate
          validate = {} unless Hash === validate
          validates_inclusion_of name, in: enum_values.keys, **validate
        end

        enum_values.freeze
      end

      def assert_valid_enum_options(options)
        invalid_keys = options.keys & %i[_prefix _suffix _scopes _default _instance_methods]
        unless invalid_keys.empty?
          raise ArgumentError, "invalid option(s): #{invalid_keys.map(&:inspect).join(", ")}. Valid options are:" \
            " :type, :prefix, :suffix, :scopes, :default, :instance_methods, :validate and :with_keyword_access."
        end
      end
    end
  end
end

ActiveRecord::Base.prepend ActiveRecord::Enum::WithKeywordAccess
