module ExtRice
  has_config do
    attr_writer :log_path
    attr_writer :log_level
    attr_writer :log_levels

    def log_path
      @log_path ||= Rice.root.join('tmp/rice.log')
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
  end
end
