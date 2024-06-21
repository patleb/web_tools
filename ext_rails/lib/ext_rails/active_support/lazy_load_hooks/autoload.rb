module ActiveSupport::LazyLoadHooks::Autoload
  extend ActiveSupport::Concern

  class_methods do
    def run_load_hooks(name, base = Object, parent: false)
      $profile_loaded_hooks << name if ENV['RAILS_PROFILE']
      _parent_hooks << base.name if parent
      super(name, base)
    end

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
    rescue NameError
      raise unless _parent_hooks.include? base.name
      base.module_parent.const_get(module_name)
    end

    def _unload_module_const(base, module_name)
      module_const = _get_module_const(base, module_name)
      module_const.module_parent.__send__(:remove_const, module_name)
    rescue NameError
      # do nothing
    end

    def _parent_hooks
      @_parent_hooks ||= Set.new
    end

    private

    def _autoload_hooks(base_dir)
      Pathname.glob(base_dir / '**/*.{include,prepend}.rb').each do |file|
        module_path = file.relative_path_from(base_dir)
        module_path = module_path.sub(/^\w+\//, '')
        parent_name, module_name = module_path.split
        hook_name = parent_name.to_s.camelize
        file = file.to_s
        module_name, type = module_name.to_s.split('.').first(2)
        module_name = module_name.camelize

        ActiveSupport.autoload_hooks_count += 1
        on_load(hook_name) do |base|
          ActiveSupport._unload_module_const(base, module_name) if Rails.env.local?
          load file
          base.send type, ActiveSupport._get_module_const(base, module_name)
          ActiveSupport.autoloaded_hooks_count += 1
        end
      end
    end
  end
end

ActiveSupport.prepend ActiveSupport::LazyLoadHooks::Autoload
