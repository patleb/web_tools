module GearedPagination
  module PortionAtOffset::WithSingleQuery
    extend ActiveSupport::Concern

    prepended do
      attr_reader :scope
    end

    def from(scope)
      raise "#from was used for a different scope" if @scope && @scope != scope
      @from ||= begin
        @scope = scope
        super
      end
    end
  end
end

GearedPagination::PortionAtOffset.prepend GearedPagination::PortionAtOffset::WithSingleQuery
