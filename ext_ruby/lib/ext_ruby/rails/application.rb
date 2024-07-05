class AppStringInquirer < ActiveSupport::StringInquirer
  def base?
    return @base if defined? @base
    @base = Rails.app == Rails.application.name
  end
end

Rails::Application.class_eval do
  def name
    @_name ||= engine_name.delete_suffix('_application')
  end
end

module Rails
  def self.stage
    @_stage ||= "#{env}-#{app}"
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
