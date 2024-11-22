module ActivePresenter
  class Base < ActionView::Delegator
    attr_reader   :record
    attr_accessor :list

    def initialize(record:, **)
      @record = record
      super(**)
    end

    def [](name)
      record.public_send(name)
    end

    def method_missing(name, ...)
      if record.respond_to? name
        record.public_send(name, ...)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      record.respond_to?(name, include_private) || super
    end
  end
end
