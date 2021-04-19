module Checks
  module Postgres
    class Setting < Base
      attribute :value

      def self.list
        { version: db.server_version }.merge!(
          db.settings,
          db.vacuum_settings,
          db.autovacuum_settings
        ).map do |(name, value)|
          { id: name.to_s, value: value }
        end
      end
    end
  end
end
