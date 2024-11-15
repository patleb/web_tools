class String
  include Numeric::Conversions

  def to_class_param
    split('::').map(&:underscore).join('-')
  end

  def to_class_name
    split('-').map(&:camelize).join('::')
  end

  class ClassCache
    def initialize
      @store = Concurrent::Map.new
    end

    def key?(key)
      @store.key?(key)
    end

    def get(key)
      @store[key] ||= ActiveSupport::Inflector.constantize(key)
    end

    def safe_get(key)
      if key? key
        @store[key]
      else
        @store[key] = ActiveSupport::Inflector.safe_constantize(key)
      end
    end

    def delete(key)
      @store.delete(key)
    end

    def clear!
      @store.clear
    end
  end

  Reference = ClassCache.new

  def to_const!
    Reference.get(self)
  end

  def to_const
    Reference.safe_get(self)
  end

  def clear_const
    Reference.delete(self)
  end
end
