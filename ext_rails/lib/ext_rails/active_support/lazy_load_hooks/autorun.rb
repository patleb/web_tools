### WARNING
# hooks are run after const declaration, not definition, so included/prepended blocks must be defined accordingly
module ActiveSupport::LazyLoadHooks::Autorun
  extend ActiveSupport::Concern

  included do
    ActiveSupport.run_load_hooks(name, self)
  end

  class_methods do
    def inherited(subclass)
      super
      return unless (hook_name = subclass.name)
      ActiveSupport.run_load_hooks(hook_name, subclass)
    end
  end
end
