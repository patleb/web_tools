module Checks
  module Postgres
    class Setting < Base
      attribute :value

      def self.list
        { version: database.server_version }.merge!(
          database.settings,
          database.vacuum_settings,
          database.autovacuum_settings
        ).map do |(name, value)|
          { id: name.to_s, value: value }
        end
      end
    end
  end
end
