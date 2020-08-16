unless defined? WebTools
  module WebTools
    def self.gem_version
      Gem::Version.new VERSION::STRING
    end

    module RAILS_VERSION
      MAJOR = 6
      MINOR = 0
      PATCH = 0

      STRING = [MAJOR, MINOR, PATCH].compact.join(".")
    end

    module VERSION
      MAJOR = 0
      MINOR = 2
      PATCH = 0

      STRING = [MAJOR, MINOR, PATCH].compact.join(".")
    end
  end
end
