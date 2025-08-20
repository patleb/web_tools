module ExtRice
  has_config do
    attr_writer :log_path
    attr_writer :log_level
    attr_writer :log_levels
    attr_writer :target
    attr_writer :target_path
    attr_writer :bin_path
    attr_writer :tmp_path
    attr_writer :checksum_path
    attr_writer :yml_path
    attr_writer :extconf_path
    attr_writer :mkmf_path
    attr_writer :dst_path
    attr_writer :root_vendor
    attr_writer :root_test
    attr_writer :root_app
    attr_writer :root
    attr_writer :scope
    attr_writer :template
    attr_accessor :executable
    alias_method :executable?, :executable

    def log_path
      @log_path || Bundler.root.join("log/rice#{log_suffix}.log")
    end

    def log_levels
      @log_levels || %w(trace debug info warning error).map.with_index.to_h
    end

    def log_level
      @log_level || ENV['DEBUG'] ? 'debug' : (test ? 'info' : 'warning')
    end

    def log_level_i
      log_levels[log_level]
    end

    def log_suffix
      scope.presence ? "-#{scope.full_underscore}" : ''
    end

    def target
      Setting[:rice_target]
    end

    def target_path
      @target_path || root.join('app/rice', scope)
    end

    def bin_path
      @bin_path || target_path.join(executable ? target : "#{target}.#{RbConfig::CONFIG['DLEXT']}")
    end

    def tmp_path
      @tmp_path || Bundler.root.join('tmp/rice', scope)
    end

    def checksum_path
      @checksum_path || target_path.join("#{target}.sha256")
    end

    def yml_path
      @yml_path || root.join('config/rice.yml')
    end

    def extconf_path
      @extconf_path || root.join('config/rice/extconf.rb')
    end

    def mkmf_path
      @mkmf_path || tmp_path.join('make')
    end

    def dst_path
      @dst_path || tmp_path.join('src')
    end

    def root_vendor
      @root_vendor || root.join('vendor/rice')
    end

    def root_test
      @root_test || root.join('test/rice')
    end

    def root_app
      @root_app || root.join('app/rice')
    end

    def root
      @root || Bundler.root
    end

    def scope
      @scope || (test ? "test/#{root.basename.to_s}" : '')
    end

    def template
      @template ||= {}.to_hwia
    end

    def test
      ENV['RAILS_ENV'] == 'test'
    end
    alias_method :test?, :test
  end
end
