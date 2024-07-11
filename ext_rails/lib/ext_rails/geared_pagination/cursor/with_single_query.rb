module GearedPagination
  module Cursor::WithSingleQuery
    extend ActiveSupport::Concern

    class_methods do
      def encode(page_number: 1, values: {})
        Base64.urlsafe_encode64 ActiveSupport::JSON.encode(p: page_number, v: values)
      end
    end

    def initialize(p: 1, v: {})
      @page_number, @values = p, v
    end
  end
end

GearedPagination::Cursor.prepend GearedPagination::Cursor::WithSingleQuery
