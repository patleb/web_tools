### References
# https://github.com/rubiety/nilify_blanks
module ActiveRecord::Base::WithNullifyBlanks
  extend ActiveSupport::Concern

  DEFAULT_TYPES = [:string, :text, :citext]

  prepended do
    class_attribute :nullify_blanks_types, instance_writer: false, instance_predicate: false, default: DEFAULT_TYPES
    class_attribute :nullify_blanks_columns, instance_writer: false, instance_predicate: false, default: Set.new
  end

  class_methods do
    def types_hash
      @types_hash ||= begin
        hash = {}.with_indifferent_access
        if respond_to? :columns_hash
          hash.merge! columns_hash.transform_values{ |c| c.type || :string }
        end
        if respond_to? :virtual_columns_hash
          hash.merge! virtual_columns_hash.transform_values{ |c| c.ivar(:@type_caster).ivar(:@type) || :string }
        end
        if respond_to? :attribute_types
          hash.merge! attribute_types.transform_values{ |c| c.type || :string }
        end
        hash
      end
    end

    def define_attribute_methods
      define_nullify_blank_methods if super
    end

    private

    def define_nullify_blank_methods
      return false if nullify_blanks_types.blank?

      generated_attribute_methods.synchronize do
        return false if @nullify_blank_methods_generated

        self.nullify_blanks_columns = types_hash.select_map{ |name, type| name if nullify_blanks_types.include? type }.to_set

        @nullify_blank_methods_generated = true
      end
    end
  end

  def nullify_blanks
    return unless nullify_blanks_columns.present?
    nullify_blanks_columns.each do |column|
      value = read_attribute(column)
      next unless value.is_a? String
      write_attribute(column, nil) if value.blank?
    end
  end

  private

  def _run_initialize_callbacks
    nullify_blanks
    super
  end

  def _run_validation_callbacks
    nullify_blanks
    super
  end
end
