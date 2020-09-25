### References
# https://gitlab.com/gitlab-org/gitlab-ee/blob/master/config/initializers/0_as_concern.rb
# TODO
# https://github.com/rails/rails/commit/ba2bea5e07de7206c7309b1e8da79d70b71dfa8a
module Prependable
  def prepend_features(base)
    if base.instance_variable_defined?(:@_dependencies)
      base.instance_variable_get(:@_dependencies) << self
      return false
    else
      return false if base < self
      super
      base.singleton_class.prepend const_get(:ClassMethods) if const_defined?(:ClassMethods)
      @_dependencies.each { |dep| base.prepend(dep) }
      base.class_eval(&@_included_block) if instance_variable_defined?(:@_included_block)
    end
  end
end

module ActiveSupport
  module Concern
    prepend Prependable

    alias_method :prepended, :included

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
  end
end
