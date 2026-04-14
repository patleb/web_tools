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
  end
end
