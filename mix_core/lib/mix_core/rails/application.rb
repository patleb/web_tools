Rails::Application.class_eval do
  alias_method :old_initialize!, :initialize!
  def initialize!(group = :default)
    if ENV['RAILS_PROFILE']
      require 'mr_backend/lineprof'

      thresholds = {
        Rack::Lineprof::CRITICAL => 100,
        Rack::Lineprof::WARNING => 50,
        Rack::Lineprof::NOMINAL => 25
      }

      $profile_dependencies = []
      $profile_initializers = []
      $profile_loaded_hooks = []
      Lineprof.profile(%r{#{ENV['RAILS_PROFILE']}}, thresholds: thresholds) do
        old_initialize! group
      end
      puts '[DEPENDENCIES]'
      puts $profile_dependencies.sort.join("\n")
      puts '[INITIALIZERS]'
      puts $profile_initializers.sort.join("\n")
      puts "Autoloaded Hooks Count: #{ActiveSupport.autoloaded_hooks_count} / #{ActiveSupport.autoload_hooks_count}"
      puts $profile_loaded_hooks.join("\n")
    else
      old_initialize! group
    end
  end
end
