### References
# https://github.com/rubiety/nilify_blanks
module ActiveRecord::Base::WithNullifyBlanks
  extend ActiveSupport::Concern

  DEFAULT_TYPES = [nil, :string, :text, :citext]

  prepended do
    class_attribute :nullify_blanks_types, instance_writer: false, instance_predicate: false, default: DEFAULT_TYPES
    class_attribute :nullify_blanks_columns, instance_writer: false, instance_predicate: false
  end

  class_methods do
    def define_attribute_methods
      define_nullify_blank_methods if super
    end

    private

    def define_nullify_blank_methods
      return false if nullify_blanks_types.blank?

      generated_attribute_methods.class::LOCK.synchronize do
        return false if @nullify_blank_methods_generated

        self.nullify_blanks_columns = types_hash.select_map do |name, attribute|
          next unless nullify_blanks_types.include? attribute.type
          name unless attribute.false? :null
        end.to_set

        @nullify_blank_methods_generated = true
      end
    end
  end

  def nullify_blanks
    return unless nullify_blanks_columns.present?
    nullify_blanks_columns.each do |column|
      value = read_attribute(column)
      next unless value.is_a? String
      next unless value.blank?
      write_attribute(column, nil)
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
