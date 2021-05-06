module Checks
  module Postgres
    class ReplicationSlot < Base
      attribute :inactive, :boolean

      scope :inactive, -> { where(inactive: true) }
      scope :active,   -> { where(inactive: false) }

      def self.list
        db.replication_slots.map do |row|
          { id: row[:slot_name], inactive: !row[:active] }
        end
      end

      def error?
        inactive?
      end

      def active?
        !inactive?
      end
    end
  end
end
