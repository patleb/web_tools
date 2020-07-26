module ActiveSupport::LazyLoadHooks::Autoload
  extend ActiveSupport::Concern

  SPECIAL_HOOKS = IceNine.deep_freeze(
    action_view_base:   :action_view,
    action_mailer_base: :action_mailer,
    active_job_base:    :active_job,
    active_record_base: :active_record,
  )
  SPECIAL_BASES = IceNine.deep_freeze(
    'ActionController::Base' => true,
    'ActionController::API' => true,
  )

  class_methods do
    def autoload_hooks_count
      @autoload_hooks_count ||= 0
    end

    def autoload_hooks_count=(count)
      @autoload_hooks_count = count
    end

    def autoloaded_hooks_count
      @autoloaded_hooks_count ||= 0
    end

    def autoloaded_hooks_count=(count)
      @autoloaded_hooks_count = count
    end

    def autoload_hooks
      Rails::Engine.subclasses.map(&:root).each{ |root| _autoload_hooks(root.join('lib')) }
      _autoload_hooks(Rails.root.join('app/libraries'))
    end

    def _get_module_const(base, module_name)
      base.const_get(module_name)
    rescue NameError => e
      if !SPECIAL_BASES[base.name] && e.message.match?(/^uninitialized constant #{module_name}$/)
        raise
      end
      base.module_parent.const_get(module_name)
    end

    private

    def _autoload_hooks(base_dir)
      Pathname.glob(base_dir / '**/*.{include,prepend}.rb').each do |file|
        module_path = file.relative_path_from(base_dir)
        module_path = module_path.sub(/^\w+\//, '')
        parent_name, module_name = module_path.split
        hook_name = parent_name.to_s.full_underscore.to_sym
        hook_name = SPECIAL_HOOKS[hook_name] if SPECIAL_HOOKS[hook_name]
        file = file.to_s
        module_name, type = module_name.to_s.split('.').first(2)
        module_name = module_name.camelize

        ActiveSupport.autoload_hooks_count += 1
        on_load(hook_name) do |base|
          require_dependency file
          base.send type, ActiveSupport._get_module_const(base, module_name)
        rescue NameError
          raise unless Rails.env.dev_or_vagrant?
          load file
          base.send type, ActiveSupport._get_module_const(base, module_name)
        rescue ActiveSupport::Concern::MultipleIncludedBlocks
          raise unless Rails.env.dev_or_vagrant?
          base.send type, ActiveSupport._get_module_const(base, module_name)
        ensure
          ActiveSupport.autoloaded_hooks_count += 1
        end
      end
    end
  end
end

ActiveSupport.include ActiveSupport::LazyLoadHooks::Autoload
