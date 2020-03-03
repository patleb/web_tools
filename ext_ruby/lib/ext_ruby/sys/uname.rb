module Sys
  class Uname
    class UnsupportedOS < ::StandardError; end

    UBUNTU_VERSION = /~(\d+\.\d+)\.\d+-ubuntu/i
    CENTOS_VERSION = /\.el(\d+)\./

    def self.os
      @os ||= case
        when version.match?(UBUNTU_VERSION) then ActiveSupport::StringInquirer.new('ubuntu')
        when release.match?(CENTOS_VERSION) then ActiveSupport::StringInquirer.new('centos')
        else raise UnsupportedOS
        end
    end

    def self.os_version
      @os_version ||= case true
        when os.ubuntu? then version.match(UBUNTU_VERSION)[1]
        when os.centos? then release.match(CENTOS_VERSION)[1]
        else raise UnsupportedOS
        end
    end
  end
end
