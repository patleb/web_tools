module Admin
  module Sections
    class Trash < Index
      def bulk_form_options
        { method: :post, remote: true }
      end
    end
  end
end
