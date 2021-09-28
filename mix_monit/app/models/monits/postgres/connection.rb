module Monits
  module Postgres
    class Connection < Base
      IDLE = 'idle in transaction'

      attribute :total, :integer
      attribute :idle, :boolean

      scope :idle, -> { where(idle: true) }

      def self.list
        db.connections.group_by{ |c| c.slice(:state, :source, :user, :ip, :database) }.map do |k, v|
          state = k[:state]
          total = v.size
          id = {
            "[#{state}]"       => state,
            "#{k[:source]}://" => k[:source],
            k[:user]           => k[:user],
            "@#{k[:ip]}"       => k[:ip],
            "/#{k[:database]}" => k[:database],
          }
          { id: id.reject{ |_key, value| value.blank? }.keys.join, idle: state == IDLE, total: total }
        end
      end

      def self.total
        sum(&:total)
      end
    end
  end
end
