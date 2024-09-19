module Admin
  class Model::Column
    attr_reader :column, :klass, :name

    delegate_missing_to :column

    def initialize(column, klass, name, virtual)
      @column = column
      @klass = klass
      @name = name.to_sym
      @virtual = virtual
    end

    def required?
      @column.false?(:null) && !(@column.default.nil? && @column.default_function.nil?)
    end

    def readonly?
      @klass.readonly_attributes.include? @name
    end

    def type
      if serialized?
        :serialized
      else
        @column.type || :string
      end
    end

    def virtual?
      @virtual
    end

    def array?
      @column.true? :array?
    end

    def association?
      false
    end

    private

    def serialized?
      @klass.type_for_attribute(@name).class == ActiveRecord::Type::Serialized
    end
  end
end
