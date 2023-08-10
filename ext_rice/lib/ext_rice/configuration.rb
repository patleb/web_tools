module ExtRice
  has_config do
    attr_writer :log_path
    attr_writer :log_level
    attr_writer :log_levels
    attr_writer :bin_path
    attr_writer :lib_path
    attr_writer :tmp_path
    attr_writer :checksum_path
    attr_writer :yml_path
    attr_writer :extconf_path
    attr_writer :dst_path
    attr_writer :root

    def log_path
      @log_path ||= root.join('tmp/rice.log')
    end

    def log_levels
      @log_levels ||= %w(trace debug info warning error).map.with_index.to_h
    end

    def log_level
      @log_level ||= 'error'
    end

    def log_level_i
      log_levels[log_level]
    end

    def bin_path
      @bin_path ||= lib_path.join("ext.#{RbConfig::CONFIG['DLEXT']}")
    end

    def lib_path
      @lib_path ||= root.join('app/libraries')
    end

    def tmp_path
      @tmp_path ||= root.join('tmp/rice')
    end

    def checksum_path
      @checksum_path ||= lib_path.join('ext.sha256')
    end

    def yml_path
      @yml_path ||= extconf_path.dirname.sub_ext('.yml')
    end

    def extconf_path
      @extconf_path ||= root.join('config/rice/extconf.rb')
    end

    def dst_path
      @dst_path ||= tmp_path.join('src')
    end

    def root
      @root ||= Bundler.root
    end
  end
end
