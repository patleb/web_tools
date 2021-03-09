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

  def all_rake_tasks
    @_all_rake_tasks ||= begin
      Rake::TaskManager.record_task_metadata = true
      Rails.application.load_tasks
      tasks = Rake.application.instance_variable_get('@tasks')
      unless MixTask.config.keep_install_migrations
        tasks.each do |t|
          if (task_name = t.first).end_with? ':install:migrations'
            tasks.delete(task_name)
          end
        end
      end
      tasks
    end
  end
end

module Rails
  def self.app
    @_app ||= AppStringInquirer.new(ENV["RAILS_APP"].presence || ENV["RACK_APP"].presence || application.name)
  end

  def self.app=(application)
    @_app = AppStringInquirer.new(application)
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
