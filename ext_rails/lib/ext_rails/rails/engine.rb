Rails::Engine.class_eval do
  def append_migrations(app, engine = self, scope: nil)
    unless app.root.to_s == engine.root.to_s
      engine.config.paths['db/migrate'].expanded.each do |expanded_path|
        app.config.paths['db/migrate'] << (scope ? expanded_path.to_s.sub('db/migrate', "db/#{scope}/migrate") : expanded_path)
      end
    end
  end
end
