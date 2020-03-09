Rails::Engine.class_eval do
  def append_pgrest_migrations(app, engine = self)
    append_migrations(app, engine, type: 'pgrest')
  end

  def append_postgis_migrations(app, engine = self)
    append_migrations(app, engine, type: 'postgis')
  end

  def append_timescaledb_migrations(app, engine = self)
    append_migrations(app, engine, type: 'timescaledb')
  end

  def append_migrations(app, engine = self, type: nil)
    unless app.root.to_s == engine.root.to_s
      engine.config.paths['db/migrate'].expanded.each do |expanded_path|
        app.config.paths['db/migrate'] << (type ? expanded_path.to_s.sub('db/migrate', "db/#{type}/migrate") : expanded_path)
      end
    end
  end
end
