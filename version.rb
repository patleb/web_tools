unless defined? WebTools
  module WebTools
    def self.gem_version
      Gem::Version.new VERSION::STRING
    end

    module RAILS_VERSION
      MAJOR = 8
      MINOR = 0
      PATCH = 1

      STRING = [MAJOR, MINOR, PATCH].compact.join(".")
    end

    module VERSION
      MAJOR = 0
      MINOR = 3
      PATCH = 0

      STRING = [MAJOR, MINOR, PATCH].compact.join(".")
    end
  end
end
