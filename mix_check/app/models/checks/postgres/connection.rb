module Checks
  module Postgres
    class Connection < Base
      IDLE = '[idle in transaction]'

      attribute :total, :integer

      def self.list
        db.connections.group_by{ |c| c.slice(:state, :source, :user, :ip, :database) }.map do |k, v|
          id = {
            "[#{k[:state]}]"   => k[:state],
            "#{k[:source]}://" => k[:source],
            k[:user]           => k[:user],
            "@#{k[:ip]}"       => k[:ip],
            "/#{k[:database]}" => k[:database],
          }
          { id: id.reject{|_key, value| value.blank? }.keys.join, total: v.count }
        end
      end

      def self.issues
        { connection: total >= db.total_connections_threshold, connection_idle: idle >= 100 }
      end

      def self.stats
        { connection: { total: total, idle: idle } }
      end

      def self.total
        all.sum(&:total)
      end

      def self.idle
        all.find(&:idle?)&.total || 0
      end

      # NOTE might need to restart passenger and job:watch
      def self.kill_all
        db.kill_all
      end

      def idle?
        id.start_with? IDLE
      end
    end
  end
end
