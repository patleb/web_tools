class Module
  def has_config(&configuration)
    class_variable_set(:@@config, nil)

    define_singleton_method :configure do |&block|
      unless (config = class_variable_get(:@@config))
        config = class_variable_set(:@@config, const_get(:Configuration).new)
      end

      block.call(config) if block

      config
    end

    define_singleton_method :config do
      class_variable_get(:@@config) || configure
    end

    define_singleton_method :reset do
      class_variable_set(:@@config, nil)
      self
    end

    define_singleton_method :with do |&block|
      old_config = config.deep_dup
      block.call(config)
    ensure
      class_variable_set(:@@config, old_config)
    end

    const_set :Configuration, Class.new(&configuration)
  end
end
