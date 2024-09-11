module Admin
  module Fields
    class Date < DateTime
      register_option :view_helper, memoize: true do
        :date_field
      end

      register_option :html_attributes do
        super!(:html_attributes).merge! size: 18
      end

      register_option :i18n_scope do
        [:date, :formats, :pretty]
      end
    end
  end
end
