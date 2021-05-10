module Checks
  module Postgres
    class TransactionWraparound < Base
      alias_attribute :table, :id
      attribute       :left, :integer
      attribute       :autovacuum, :boolean

      scope :wraparound, -> { where(autovacuum: nil) }
      scope :autovacuum, -> { where(autovacuum: true) }

      def self.list
        ids = {}
        wraparounds = db.transaction_id_danger(threshold: 1_500_000_000).map do |row|
          ids[row[:table]] = true
          { id: row[:table], left: row[:transactions_left] }
        end
        db.autovacuum_danger.each_with_object(wraparounds) do |row, memo|
          next if ids[row[:table]]
          memo << { id: row[:table], left: row[:transactions_left], autovacuum: true }
        end
      end

      def wraparound?
        !autovacuum?
      end

      alias_method :wraparound_issue?, :wraparound?
      alias_method :autovacuum_warning?, :autovacuum?
    end
  end
end
