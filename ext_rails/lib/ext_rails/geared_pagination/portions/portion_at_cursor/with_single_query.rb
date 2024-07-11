# frozen_string_literal: true

module GearedPagination
  module PortionAtCursor::WithSingleQuery
    extend ActiveSupport::Concern

    prepended do
      attr_reader :next, :last, :scope
    end

    def from(scope)
      raise "#from was used for a different scope" if @scope && @scope != scope
      @from ||= begin
        unless scope.order_values.none? && scope.limit_value.nil?
          raise ArgumentError, "Can't paginate relation with ORDER BY or LIMIT clauses (got #{scope.to_sql})"
        end
        records = selection_from(scope).order(orderings).limit(limit).to_a
        if records.size == limit
          *records, @next = records
        end
        @last = records.last
        @scope = scope
        records
      end
    end

    def next_param(*)
      @next_param ||= Cursor.encode(page_number: page_number + 1, values: last&.slice(*attributes) || {})
    end

    private

    def limit
      super + 1
    end
  end
end

GearedPagination::PortionAtCursor.prepend GearedPagination::PortionAtCursor::WithSingleQuery
