module Admin
  module Sections
    class Trash < Index
      def bulk_form_options
        { method: :post, remote: true }
      end

      def inline_items(presenter)
        []
      end
    end
  end
end
