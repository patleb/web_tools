### References
# https://github.com/rubiety/nilify_blanks/blob/master/lib/nilify_blanks.rb
# TODO https://github.com/rmm5t/strip_attributes
# TODO https://github.com/rails/rails/pull/42095 --> Rails 7.0

module ActiveRecord::Base::WithNullifyBlanks
  extend ActiveSupport::Concern

  class_methods do
    DEFAULT_TYPES = [:string, :text, :citext]

    # This overrides the underlying rails method that defines attribute methods.
    # This must be thread safe, just like the underlying method.
    #
    def define_attribute_methods
      if super
        define_nullify_blank_methods
      end
    end

    def inherited(subclass)
      super
      return unless subclass.name
      return unless ivar(:@_nullify_blanks_options)
      return if subclass.ivar(:@_nullify_blanks_options)
      subclass.nullify_blanks **@_nullify_blanks_options
    end

    def nullify_blanks(**options)
      return if @_nullify_blanks_options

      @_nullify_blanks_options = options

      # Normally we wait for rails to define attribute methods, but we could be calling this after this has already been done.
      # If so, let's just immediately generate nullify blanks methods.
      #
      if @attribute_methods_generated
        define_nullify_blank_methods
      end

      descendants.each do |subclass|
        subclass.nullify_blanks **@_nullify_blanks_options
      end
    end

    private

    def define_nullify_blank_methods
      return false unless @_nullify_blanks_options
      return false if @nullify_blank_methods_generated

      generated_attribute_methods.synchronize do
        return false if @nullify_blank_methods_generated
        options = @_nullify_blanks_options

        types = options[:types] = options[:types] ? Array.wrap(options[:types]).map(&:to_sym) : DEFAULT_TYPES

        cattr_accessor :nullify_blanks_columns

        names = Set.new
        if respond_to? :columns_hash
          columns_hash.each do |name, column|
            names << name if types.include?(column.type || :string)
          end
        end
        if respond_to? :virtual_columns_hash
          virtual_columns_hash.each do |name, column|
            names << name if types.include?(column.ivar(:@type_caster).ivar(:@type) || :string)
          end
        end
        if respond_to? :attribute_types
          attribute_types.each do |name, column|
            names << name if types.include?(column.type || :string)
          end
        end

        self.nullify_blanks_columns = names.to_a

        after_initialize  :nullify_blanks
        before_validation :nullify_blanks
        @nullify_blank_methods_generated = true
      end
    end
  end

  def nullify_blanks
    (nullify_blanks_columns || []).each do |column|
      value = read_attribute(column)
      next unless value.is_a? String
      write_attribute(column, nil) if value.blank?
    end
  end
end
