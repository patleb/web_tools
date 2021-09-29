module Monit
  module Osquery
    class FileEvent < Base
      attribute :inode, :integer
      attribute :time, :datetime
      attribute :action
      attribute :path
      attribute :mode
      attribute :size, :integer
      attribute :sha256
      attribute :uid, :integer
      attribute :gid, :integer

      def self.list
        (osquery['file_events'] || []).flat_map do |rows|
          rows[:new].map do |row|
            inode, time, action = row.values_at('inode', 'time', 'action')
            {
              id: [inode, time, action].join(':'), inode: inode, time: Time.at(time).utc, action: action,
              path: row['target_path'], mode: row['mode'], size: row['size'], sha256: row['sha256'],
              uid: row['uid'], gid: row['gid'],
            }
          end
        end
      end
    end
  end
end
