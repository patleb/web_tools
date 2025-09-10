module Rake
  module DSL
    def namespace!(name = nil, &block)
      module_name  = "#{name.to_s.camelize}_Tasks"
      with_scope   = self.class.const_get(module_name) if self.class.const_defined? module_name
      with_scope ||= self.class.const_set(module_name, Module.new)
      with_scope.module_eval do
        extend Rake::DSL
        extend self
        namespace name do
          instance_eval(&block)
        end
      end
    end

    def flag_on?(args, name)
      return unless args.respond_to? :key?
      value = args[name]
      (value.to_s == name.to_s) || value.to_b
    end
  end
end
