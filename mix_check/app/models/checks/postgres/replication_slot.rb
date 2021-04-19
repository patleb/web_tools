module Checks
  module Postgres
    class ReplicationSlot < Base
      attribute :active, :boolean

      def self.list
        db.replication_slots.map do |row|
          { id: row[:slot_name], active: row[:active] }
        end
      end

      def self.issues
        { replication_slot: any?(&:inactive?) }
      end

      def self.inactive
        where(active: false)
      end

      def inactive?
        !active?
      end
    end
  end
end
