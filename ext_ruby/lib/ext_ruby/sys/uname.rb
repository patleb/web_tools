module Sys
  class Uname
    class UnsupportedOS < ::StandardError; end

    UBUNTU_VERSION = /~(\d+\.\d+)\.\d+-ubuntu/i
    CENTOS_VERSION = /\.el(\d+)\./

    def self.os
      @os ||= case
        when version.match?(UBUNTU_VERSION) then 'ubuntu'
        when release.match?(CENTOS_VERSION) then 'centos'
        else raise UnsupportedOS
        end
    end

    def self.os_version
      @os_version ||= case true
        when ubuntu? then version.match(UBUNTU_VERSION)[1]
        when centos? then release.match(CENTOS_VERSION)[1]
        else raise UnsupportedOS
        end
    end

    def self.ubuntu?
      os == 'ubuntu'
    end

    def self.centos?
      os == 'centos'
    end
  end
end
