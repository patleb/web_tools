module Admin
  class Model::Column
    attr_reader :column, :klass, :name

    delegate_missing_to :column

    def initialize(column, klass, name = nil)
      @column = column
      @klass = klass
      @name = name ? name.to_sym : column.name.to_sym
    end

    def required?
      @column.false?(:null) && !(@column.default.nil? && @column.default_function.nil?)
    end

    def readonly?
      @klass.readonly_attributes.include? @column.name
    end

    def type
      if serialized? @column.name
        :serialized
      else
        @column.type
      end
    end

    def virtual?
      false
    end

    def array?
      @column.true? :array?
    end

    def association?
      false
    end

    private

    def serialized?(name)
      @klass.type_for_attribute(name).class == ActiveRecord::Type::Serialized
    end
  end
end
