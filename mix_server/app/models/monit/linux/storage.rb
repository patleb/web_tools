module Monit
  module Linux
    class Storage < Disk
      def self.disk_path
        Setting[:data_directory]
      end
    end
  end
end
