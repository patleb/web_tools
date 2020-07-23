module ExtPjax
  has_config do
    attr_accessor :debug_trace

    def debug_trace?
      !!@debug_trace
    end
  end
end
