MonkeyPatch.add{['railties', 'lib/rails/application.rb', '1b26eb866fda996aa17fc777f386036f12ba3660dd4aefb3a60e25b3a822fb0e']}

class AppStringInquirer < ActiveSupport::StringInquirer
  def default?
    return @default if defined? @default
    @default = Rails.app == Rails.application.name
  end
end

module Rails
  def self.stage
    @_stage ||= "#{env}_#{app}"
  end

  def self.app
    @_app ||= AppStringInquirer.new(ENV["RAILS_APP"].presence || ENV["RACK_APP"].presence || application.name)
  end

  def self.app=(application)
    @_app = AppStringInquirer.new(application)
  end

  def self.viable_names(type, excluded_names = Set.new, excluded_suffixes = [])
    ([application] + Engine.subclasses).each_with_object(SortedSet.new) do |app, names|
      app.config.paths["app/#{type}"].each do |load_path|
        Dir.glob(app.root.join(load_path, '**', '*.rb')).each do |file|
          next if file.include?('/concerns/') || file.end_with?(*excluded_suffixes)
          model = file.delete_prefix("#{app.root.join(load_path)}/").delete_suffix('.rb').camelize
          names << model unless excluded_names.include? model
        end
      end
    end.to_a
  end
end

Rails::Application.class_eval do
  def title
    @_title ||= name.titleize
  end

  # NOTE override, it was less useful for keys
  # --> self.class.name.underscore.dasherize.delete_suffix("/application")
  def name
    @_name ||= engine_name.delete_suffix('_application')
  end

  def credentials
    Setting
  end

  alias_method :old_initialize!, :initialize!
  def initialize!(group = :default)
    if ENV['RAILS_PROFILE']
      require 'ext_rails/lineprof'

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
