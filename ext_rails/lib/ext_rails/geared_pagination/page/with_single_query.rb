module GearedPagination
  module Page::WithSingleQuery
    extend ActiveSupport::Concern

    def scope
      @portion.scope
    end

    def last?
      return super unless @portion.is_a? PortionAtCursor
      @portion.next.nil?
    end
  end
end

GearedPagination::Page.prepend GearedPagination::Page::WithSingleQuery
