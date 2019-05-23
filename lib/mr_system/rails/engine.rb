Rails::Engine.class_eval do
  def append_migrations(app, engine = self)
    unless app.root.to_s == engine.root.to_s
      engine.config.paths['db/migrate'].expanded.each do |expanded_path|
        app.config.paths['db/migrate'] << expanded_path
      end
    end
  end
end
