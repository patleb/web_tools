### References
# https://github.com/rubiety/nilify_blanks/blob/master/lib/nilify_blanks.rb
# TODO https://github.com/rmm5t/strip_attributes

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
      if subclass.name \
      && instance_variable_get(:@_nullify_blanks_options) \
      && !subclass.instance_variable_get(:@_nullify_blanks_options)
        subclass.nullify_blanks **@_nullify_blanks_options
      end
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

        options[:only] = Array.wrap(options[:only]).map(&:to_s) if options[:only]
        options[:except] = Array.wrap(options[:except]).map(&:to_s) if options[:except]
        options[:types] = options[:types] ? Array.wrap(options[:types]).map(&:to_sym) : DEFAULT_TYPES

        cattr_accessor :nullify_blanks_columns

        self.nullify_blanks_columns =
          if options[:only]
            options[:only].clone
          elsif options[:nullables_only] == false
            columns.select_map{ |c| c.name.to_s if options[:types].include?(c.type) && c.default.nil? }
          else
            columns.select_map{ |c| c.name.to_s if c.null && options[:types].include?(c.type) }
          end

        self.nullify_blanks_columns -= options[:except] if options[:except]
        self.nullify_blanks_columns = nullify_blanks_columns.map(&:to_s)

        options[:before] ||= :validation
        send("before_#{options[:before]}", :nullify_blanks)
        @nullify_blank_methods_generated = true
      end
    end
  end

  def nullify_blanks
    (nullify_blanks_columns || []).each do |column|
      value = read_attribute(column)
      next unless value.is_a?(String)
      next unless value.respond_to?(:blank?)

      write_attribute(column, nil) if value.blank?
    end
  end
end
