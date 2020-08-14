Rails::Application.class_eval do
  def name
    @_name ||= engine_name.delete_suffix('_application')
  end
end

module Rails
  def self.app
    @_app ||= ActiveSupport::StringInquirer.new(ENV["RAILS_APP"].presence || ENV["RACK_APP"].presence || application.name)
  end

  def self.app=(application)
    @_app = ActiveSupport::StringInquirer.new(application)
  end

  def self.viable_names(type, excluded_names = Set.new, excluded_suffixes = [])
    included_names = ([application] + Engine.subclasses).map do |app|
      paths = app.config.paths["app/#{type}"].to_a + app.config.eager_load_paths.select(&:end_with?.with("/#{type}"))
      paths.uniq.map do |load_path|
        Dir.glob(app.root.join(load_path)).map do |load_dir|
          Dir.glob(load_dir + '/**/*.rb').map do |filename|
            unless filename.include?('/concerns/') || filename.end_with?(*excluded_suffixes)
              filename.delete_prefix("#{app.root.join(load_dir)}/").delete_suffix('.rb').camelize
            end
          end.compact
        end
      end
    end.flatten
    included_names.reject do |model|
      excluded_names.include? model
    end.sort
  end
end
