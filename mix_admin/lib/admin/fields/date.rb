module Admin
  module Fields
    class Date < DateTime
      register_option :i18n_scope do
        [:date, :formats, :pretty]
      end

      def input_type
        :date
      end

      def default_input_attributes
        super.merge! size: 18
      end
    end
  end
end
