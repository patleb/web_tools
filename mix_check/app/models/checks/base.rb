module Checks
  class Base < VirtualRecord::Base
    def self.issues
      {}
    end

    def self.warnings
      {}
    end

    def self.stats
      {}
    end
  end
end
