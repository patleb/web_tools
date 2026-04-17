module MatIO
  File.class_eval do
    def self.open(...)
      file = new(...)
      yield file
      file
    ensure
      file&.remove_ivar(:@vars)
      file&.close
    end

    module self::WithOverrides
      def initialize(path, mode = nil, version: nil)
        super(path.to_s, mode, version)
      end

      def vars
        @vars ||= super.to_h.nest_keys.to_hwia
      end
    end
    prepend self::WithOverrides

    def var(*path)
      vars.dig(*path)
    end

    def read(*path, **)
      var(*path).read(**)
    end

    def at(*path, indexes)
      var(*path).at(indexes)
    end

    def [](*path_and_ranges)
      path, vars = [], self.vars
      i = path_and_ranges.index do |part|
        break true if vars.is_a? MatIO::Var
        path << part
        vars = vars[part]
        false
      end
      var(*path)[*path_and_ranges[i..-1]]
    end
  end
end
