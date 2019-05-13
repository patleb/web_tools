module ActiveTask
  module Counts
    extend ActiveSupport::Concern

    class_methods do
      def track_count_of(*methods)
        methods.each do |name|
          method_count = "#{name}_count"
          method_count_ivar = "@#{method_count}"

          attr_reader method_count

          with_count = const_defined?(:WithCount) ? const_get(:WithCount) : const_set(:WithCount, Module.new)
          with_count.module_eval do
            define_method name do |*args, &block|
              count = instance_variable_get(method_count_ivar)
              instance_variable_set(method_count_ivar, count += 1)
              super(*args, &block)
            end
          end
        end
      end
    end

    def initialize(*args)
      super
      if self.class.const_defined? :WithCount
        with_count = self.class.const_get(:WithCount)
        self.class.prepend with_count
        with_count.instance_methods.each do |name|
          instance_variable_set("@#{name}_count", 0)
        end
      end
    end
  end
end
