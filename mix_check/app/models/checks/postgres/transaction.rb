module Checks
  module Postgres
    class Transaction < Base
      attribute       :schema
      alias_attribute :table, :id
      attribute       :left, :integer

      def self.list
        database.transaction_id_danger(threshold: 1_500_000_000).each do |row|
          { id: row[:table], schema: row[:schema], left: row[:transactions_left] }
        end
      end

      def self.issues
        { transaction: any? }
      end

      def self.stats
        { transaction: all.map{ |item| [item.id, item.slice(:left)] }.to_h }
      end
    end
  end
end
