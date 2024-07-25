class Module
  def has_config(&configuration)
    cvar(:@@config, nil)

    define_singleton_method :configure do |&block|
      config = cvar(:@@config){ const_get(:Configuration).new }
      block.call(config) if block
      config
    end

    define_singleton_method :config do
      cvar(:@@config) || configure
    end

    define_singleton_method :reset do
      cvar(:@@config, nil)
      self
    end

    define_singleton_method :with do |&block|
      old_config = config.deep_dup
      block.call(config)
    ensure
      cvar(:@@config, old_config)
    end

    const_set :Configuration, Class.new(&configuration)
  end
end
