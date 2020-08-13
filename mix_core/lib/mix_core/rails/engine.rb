Rails::Engine.class_eval do
  def autoload_models_if_admin(models, engine = self)
    unless defined? MixAdmin
      Array.wrap(models).each do |model|
        Rails.autoloaders.main.ignore("#{engine.root}/app/models/#{model.to_s.underscore}_admin.rb")
      end
    end
  end

  def append_migrations(app, engine = self, scope: nil)
    unless app.root.to_s == engine.root.to_s
      engine.config.paths['db/migrate'].expanded.each do |expanded_path|
        app.config.paths['db/migrate'] << (scope ? expanded_path.to_s.sub('db/migrate', "db/#{scope}/migrate") : expanded_path)
      end
    end
  end
end
