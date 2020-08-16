### WARNING
# hooks are run after const declaration, not definition, so included/prepended blocks must be defined accordingly
module ActiveSupport::LazyLoadHooks::Autorun
  extend ActiveSupport::Concern

  SKIPPED_HOOKS = IceNine.deep_freeze(
    active_storage_blob: true
  )

  class_methods do
    def inherited(subclass)
      super
      if subclass.name
        hook_name = subclass.name.full_underscore.to_sym
        if ENV['RAILS_PROFILE']
          $profile_loaded_hooks << hook_name
        end
        ActiveSupport.run_load_hooks(hook_name, subclass) unless SKIPPED_HOOKS[hook_name]
      end
    end
  end
end
