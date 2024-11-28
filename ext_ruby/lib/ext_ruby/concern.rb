module ActiveSupport
  module Concern
    def method_added(method_name, &block)
      return super unless block_given?
      mod = const_defined?(:ClassMethods, false) ? const_get(:ClassMethods) : const_set(:ClassMethods, Module.new)
      mod.module_eval do
        define_method :method_added do |name|
          if name == method_name
            self.class_eval(&block)
          end
        end
      end
    end

    def prepended_or_included(...)
      prepended(...)
      included(...)
    end
  end
end
